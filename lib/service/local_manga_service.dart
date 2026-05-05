import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart' as a;
import 'package:drift/drift.dart' show Value;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:manga_reader/database/dao/manga_dao.dart';
import 'package:manga_reader/database/database.dart';
import 'package:manga_reader/models/local_image.dart';
import 'package:manga_reader/service/base/service_lifecircle_bean.dart';
import 'package:manga_reader/service/path_service.dart';
import 'package:manga_reader/settings/path_setting.dart';
import 'package:manga_reader/shared/constants/constants.dart';
import 'package:manga_reader/shared/extensions/file_system_entity_ext.dart';
import 'package:manga_reader/shared/utils/file_util.dart';
import 'package:path/path.dart';

import '../models/manga.dart';
import '../models/manga_id.dart';
import '../shared/utils/log_util.dart';

LocalMangaService localMangaService = LocalMangaService();

class LocalMangaService with ServiceBeanMixin implements ServiceLifeCircleBean {
  @override
  List<ServiceLifeCircleBean> get initDependencies => [
        pathService,
        pathSetting,
      ];

  final Map<String, List<Manga>> settingPath2Mangas = {};

  @override
  Future<void> doInit() async {
    await loadMangasInLocalSettingPaths();
  }

  @override
  Future<void> doAfterReady() async {}

  Future<void> loadMangasInLocalSettingPaths() {
    settingPath2Mangas.clear();
    final futures =
        pathSetting.paths.map((p) => loadMangasInDir(Directory(p)));
    return Future.wait(futures);
  }

  Future<List<Manga>> loadMangasInDir(Directory dir) async {
    final completer = Completer<List<Manga>>();
    final mangas = <Manga>[];
    final futures = <Future>[];

    dir.list().listen(
      (entity) {
        if (entity is Directory || (entity is File && isZipFile(entity.path))) {
          futures.add(
            loadManga(Directory(entity.path)).then((manga) {
              if (manga != null) mangas.add(manga);
            }),
          );
        }
      },
      onDone: () {
        Future.wait(futures).then((_) {
          mangas.sort((a, b) => FileUtil.naturalCompare(a.title, b.title));
          if (pathSetting.paths.contains(dir.path)) {
            (settingPath2Mangas[dir.path] ??= []).assignAll(mangas);
          }
          completer.complete(mangas);
        });
      },
      onError: completer.completeError,
    );
    return completer.future;
  }

  Future<List<Manga>> getMangasInDir(Directory dir) async {
    if (settingPath2Mangas.containsKey(dir.path)) {
      return settingPath2Mangas[dir.path]!;
    }
    return loadMangasInDir(dir);
  }

  Future<void> refreshMangasInDir(Directory dir) async {
    await loadMangasInDir(dir);
  }

  Future<Manga?> loadManga(Directory dirOfManga) async {
    if (isZipFile(dirOfManga.path)) {
      return _loadZipManga(File(dirOfManga.path));
    }
    return _loadFolderManga(dirOfManga);
  }

  bool isZipFile(String path) =>
      path.endsWith('.zip') || path.endsWith('.cbz');

  Future<Manga?> _loadFolderManga(Directory dirOfManga) async {
    try {
      final mangaId = MangaId.fromPath(dirOfManga.path);
      final mangaRecord = await MangaDao.getManga(mangaId.value);

      final imageFiles = <File>[];
      await for (final entity in dirOfManga.list()) {
        if (entity is File && entity.isImageExtension) {
          imageFiles.add(entity);
        }
      }

      if (imageFiles.isEmpty) return null;

      imageFiles.sort(FileUtil.naturalCompareFileOrDir);

      final countChanged =
          mangaRecord != null && mangaRecord.pageCount != imageFiles.length;
      final totalSize = mangaRecord != null && !countChanged
          ? mangaRecord.size
          : await _calculateTotalSize(imageFiles);

      final result = Manga(
        id: mangaId,
        path: dirOfManga.path,
        cover: LocalImage(path: imageFiles.first.path),
        title: basename(dirOfManga.path),
        lastReadPage: mangaRecord?.lastReadPage ?? 0,
        groupName: mangaRecord?.groupName ?? Constants.defaultGroupName,
        pageCount: imageFiles.length,
        size: totalSize,
      );

      if (mangaRecord == null) {
        MangaDao.insertManga(MangaCompanion.insert(
          id: result.id.value,
          title: result.title,
          coverPath: result.cover.path,
          parentPath: dirOfManga.parent.path,
          pageCount: result.pageCount,
          size: result.size,
          sortOrder: 0,
          type: 1,
        ));
      } else if (countChanged) {
        MangaDao.updateManga(MangaCompanion(
          id: Value(result.id.value),
          size: Value(result.size),
          pageCount: Value(result.pageCount),
        ));
      }
      return result;
    } catch (e) {
      LogUtil.e('Failed to load manga from ${dirOfManga.path}');
      return null;
    }
  }

  Future<Manga?> _loadZipManga(File zipFile) async {
    try {
      final mangaId = MangaId.fromPath(zipFile.path);
      final mangaRecord = await MangaDao.getManga(mangaId.value);

      final bytes = await zipFile.readAsBytes();
      final archive = a.ZipDecoder().decodeBytes(bytes);
      final imageEntries = archive.files
          .where((f) => !f.isFile == false && _isImageName(f.name))
          .toList()
        ..sort((a, b) => FileUtil.naturalCompare(a.name, b.name));

      if (imageEntries.isEmpty) return null;

      // Extract to cache dir
      final cacheDir = Directory(
        join(Directory.systemTemp.path, 'manga_reader', mangaId.value),
      );
      if (!cacheDir.existsSync()) {
        cacheDir.createSync(recursive: true);
      }
      for (final entry in imageEntries) {
        final outFile = File(join(cacheDir.path, entry.name));
        if (!outFile.existsSync()) {
          outFile.writeAsBytesSync(entry.content as List<int>);
        }
      }

      final images = imageEntries
          .map((e) => LocalImage(path: join(cacheDir.path, e.name)))
          .toList();

      final totalSize = zipFile.lengthSync();
      final result = Manga(
        id: mangaId,
        path: zipFile.path,
        cover: images.first,
        title: basenameWithoutExtension(zipFile.path),
        lastReadPage: mangaRecord?.lastReadPage ?? 0,
        groupName: mangaRecord?.groupName ?? Constants.defaultGroupName,
        pageCount: images.length,
        size: totalSize,
      );

      if (mangaRecord == null) {
        MangaDao.insertManga(MangaCompanion.insert(
          id: result.id.value,
          title: result.title,
          coverPath: result.cover.path,
          parentPath: dirname(zipFile.path),
          pageCount: result.pageCount,
          size: result.size,
          sortOrder: 0,
          type: 2,
        ));
      }
      return result;
    } catch (e) {
      LogUtil.e('Failed to load ZIP manga from ${zipFile.path}', error: e);
      return null;
    }
  }

  bool _isImageName(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.gif');
  }

  Future<int> _calculateTotalSize(List<File> images) async {
    final futures = <Future<int>>[];
    for (final f in images) {
      futures.add(f.length());
    }
    final sizes = await Future.wait(futures);
    return sizes.fold<int>(0, (sum, s) => sum + s);
  }

  /// Archive mangas to ZIP files. Returns number of successfully archived.
  Future<int> archiveMangas(
    List<Manga> mangas,
    Directory outputDir, {
    bool deleteSource = false,
    void Function(int current, int total)? onProgress,
  }) async {
    var successCount = 0;
    for (var i = 0; i < mangas.length; i++) {
      final manga = mangas[i];
      try {
        final archive = a.Archive();
        final images = getMangaImages(manga);
        for (final image in images) {
          final file = File(image.path);
          final bytes = await file.readAsBytes();
          archive.addFile(a.ArchiveFile(basename(image.path), bytes.length, bytes));
        }
        final zipData = a.ZipEncoder().encode(archive);
        final outPath = join(outputDir.path, '${manga.title}.zip');
        await File(outPath).writeAsBytes(zipData);

        if (deleteSource) {
          // Verify ZIP wrote correctly before deleting
          final zipFile = File(outPath);
          if (await zipFile.exists() && await zipFile.length() > 0) {
            await FileUtil.deleteDir(Directory(manga.path));
            await MangaDao.deleteManga(manga.id.value);
          }
        }
        successCount++;
        onProgress?.call(i + 1, mangas.length);
      } catch (e) {
        LogUtil.e('归档失败: ${manga.title}', error: e);
      }
    }
    return successCount;
  }

  List<LocalImage> getMangaImages(Manga manga) {
    if (isZipFile(manga.path)) {
      return _getZipMangaImagesSync(File(manga.path));
    }
    final imageFiles = Directory(manga.path)
        .listSync()
        .whereType<File>()
        .where((f) => f.isImageExtension)
        .toList()
      ..sort(FileUtil.naturalCompareFileOrDir);
    return imageFiles.map((f) => LocalImage(path: f.path)).toList();
  }

  List<LocalImage> _getZipMangaImagesSync(File zipFile) {
    final bytes = zipFile.readAsBytesSync();
    final archive = a.ZipDecoder().decodeBytes(bytes);
    final entries = archive.files
        .where((f) => _isImageName(f.name))
        .toList()
      ..sort((a, b) => FileUtil.naturalCompare(a.name, b.name));

    final cacheDir = Directory(
      join(Directory.systemTemp.path, 'manga_reader', MangaId.fromPath(zipFile.path).value),
    );
    if (!cacheDir.existsSync()) cacheDir.createSync(recursive: true);
    return entries.map((e) {
      final outFile = File(join(cacheDir.path, e.name));
      if (!outFile.existsSync()) outFile.writeAsBytesSync(e.content as List<int>);
      return LocalImage(path: outFile.path);
    }).toList();
  }

  Future<List<LocalImage>> getMangaImagesAsync(Manga manga) async {
    if (isZipFile(manga.path)) {
      return _getZipMangaImagesAsync(File(manga.path));
    }
    final imageFiles = <File>[];
    await for (final entity in Directory(manga.path).list()) {
      if (entity is File && entity.isImageExtension) {
        imageFiles.add(entity);
      }
    }
    imageFiles.sort(FileUtil.naturalCompareFileOrDir);
    return imageFiles.map((f) => LocalImage(path: f.path)).toList();
  }

  Future<List<LocalImage>> _getZipMangaImagesAsync(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final archive = a.ZipDecoder().decodeBytes(bytes);
    final entries = archive.files
        .where((f) => _isImageName(f.name))
        .toList()
      ..sort((a, b) => FileUtil.naturalCompare(a.name, b.name));

    final cacheDir = Directory(
      join(Directory.systemTemp.path, 'manga_reader', MangaId.fromPath(zipFile.path).value),
    );
    if (!cacheDir.existsSync()) cacheDir.createSync(recursive: true);
    return entries.map((e) {
      final outFile = File(join(cacheDir.path, e.name));
      if (!outFile.existsSync()) outFile.writeAsBytesSync(e.content as List<int>);
      return LocalImage(path: outFile.path);
    }).toList();
  }

  Future<Manga?> mergeMangas(
    List<Manga> mangas,
    Directory output, {
    int imageNameStartFrom = 0,
    void Function(int current, int total)? onProgress,
  }) async {
    output = await output.create(recursive: true);

    final totalCount = mangas.fold(0, (sum, m) => sum + m.pageCount);
    final digits = totalCount.toString().length;

    onProgress?.call(0, totalCount);

    for (final manga in mangas) {
      final imageFiles = await getMangaImagesAsync(manga);
      for (final image in imageFiles) {
        final newName =
            '${imageNameStartFrom.toString().padLeft(digits, '0')}${extension(image.path)}';
        final target = File(join(output.path, newName));
        await File(image.path).copy(target.path);
        imageNameStartFrom++;
        onProgress?.call(imageNameStartFrom, totalCount);
      }
    }
    return loadManga(output);
  }

  Future<void> deleteManga(Manga manga, {bool showToast = true}) async {
    try {
      final deleted = await MangaDao.deleteManga(manga.id.value);
      if (deleted != 1) return;

      await FileUtil.deleteDir(Directory(manga.path));
      if (showToast) {
        Fluttertoast.showToast(msg: '已删除漫画：${manga.title}');
      }
    } catch (e) {
      LogUtil.e('删除漫画：${manga.title}失败', error: e);
      if (showToast) Fluttertoast.showToast(msg: '删除漫画：${manga.title}失败');
    }
  }

  Future<void> deleteMangas(List<Manga> mangas, {bool showToast = true}) async {
    await Future.wait(
      mangas.map((m) => deleteManga(m, showToast: false)),
    );
    if (showToast) Fluttertoast.showToast(msg: '删除成功');
  }

  Future<void> deleteImage(LocalImage image) async {
    try {
      await FileUtil.deleteFile(File(image.path));
      Fluttertoast.showToast(msg: '删除成功');
    } catch (e) {
      LogUtil.e('删除图片失败', error: e);
      Fluttertoast.showToast(msg: '删除图片失败');
    }
  }
}
