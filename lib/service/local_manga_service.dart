import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart' as a;
import 'package:drift/drift.dart' show Value;
import 'package:xml/xml.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:manga_reader/database/dao/manga_dao.dart';
import 'package:manga_reader/database/database.dart';
import 'package:manga_reader/models/local_image.dart';
import 'package:manga_reader/service/base/service_lifecircle_bean.dart';
import 'package:manga_reader/service/path_service.dart';
import 'package:manga_reader/settings/path_setting.dart';
import 'package:manga_reader/core/constants/constants.dart';
import 'package:manga_reader/core/extensions/file_system_entity_ext.dart';
import 'package:manga_reader/core/utils/file_util.dart';
import 'package:manga_reader/core/utils/zip_reader.dart';
import 'package:path/path.dart';

import '../models/manga.dart';
import '../models/manga_id.dart';
import '../core/utils/log_util.dart';

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

  /// [concurrency] controls how many mangas are loaded in parallel per batch.
  /// 0 (default) = all at once (for startup where no UI is rendered).
  /// >0 = batched with event-loop yields between batches (for refresh with UI visible).
  Future<List<Manga>> loadMangasInDir(Directory dir, {int concurrency = 0}) async {
    final entities = (await dir.list().toList())
        .where((e) => e is Directory || (e is File && isZipFile(e.path)))
        .toList();
    if (entities.isEmpty) {
      if (pathSetting.paths.contains(dir.path)) {
        settingPath2Mangas[dir.path] = [];
      }
      return [];
    }

    final ids = entities.map((e) => MangaId.fromPath(e.path).value).toList();
    final dbRecords = await MangaDao.getMangasByIds(ids);
    final recordMap = {for (final r in dbRecords) r.id: r};

    final poolSize = concurrency > 0 ? concurrency : entities.length;
    final mangas = <Manga>[];
    for (var i = 0; i < entities.length; i += poolSize) {
      final batch = entities.skip(i).take(poolSize).toList();
      final results = await Future.wait(batch.map((e) =>
        loadManga(Directory(e.path), dbRecord: recordMap[MangaId.fromPath(e.path).value]),
      ));
      for (final m in results) {
        if (m != null) mangas.add(m);
      }
      if (concurrency > 0 && i + poolSize < entities.length) {
        await Future(() {});
      }
    }

    mangas.sort((a, b) => FileUtil.naturalCompare(a.title, b.title));
    if (pathSetting.paths.contains(dir.path)) {
      (settingPath2Mangas[dir.path] ??= []).assignAll(mangas);
    }
    return mangas;
  }

  Future<List<Manga>> getMangasInDir(Directory dir) async {
    if (settingPath2Mangas.containsKey(dir.path)) {
      return settingPath2Mangas[dir.path]!;
    }
    return loadMangasInDir(dir);
  }

  Future<void> refreshMangasInDir(Directory dir) async {
    await loadMangasInDir(dir, concurrency: 3);
  }

  Future<Manga?> loadManga(Directory dirOfManga, {MangaData? dbRecord}) async {
    if (dirOfManga.path.endsWith('.epub')) {
      return _loadEpubManga(File(dirOfManga.path), dbRecord: dbRecord);
    }
    if (isZipFile(dirOfManga.path)) {
      return _loadZipManga(File(dirOfManga.path), dbRecord: dbRecord);
    }
    return _loadFolderManga(dirOfManga, dbRecord: dbRecord);
  }

  bool isZipFile(String path) =>
      path.endsWith('.zip') || path.endsWith('.cbz') || path.endsWith('.epub');

  Future<Manga?> _loadFolderManga(Directory dirOfManga, {MangaData? dbRecord}) async {
    try {
      final mangaId = MangaId.fromPath(dirOfManga.path);
      final mangaRecord = dbRecord ?? await MangaDao.getManga(mangaId.value);

      final imageFiles = (await dirOfManga.list().toList())
          .whereType<File>()
          .where((f) => f.isImageExtension)
          .toList();
      if (imageFiles.isEmpty) return null;
      imageFiles.sort(FileUtil.naturalCompareFileOrDir);

      final countChanged =
          mangaRecord != null && mangaRecord.pageCount != imageFiles.length;
      final totalSize = mangaRecord != null && !countChanged
          ? mangaRecord.size
          : await _calculateTotalSize(imageFiles);

      return _createAndPersistManga(
        mangaId: mangaId,
        path: dirOfManga.path,
        coverPath: imageFiles.first.path,
        title: basename(dirOfManga.path),
        pageCount: imageFiles.length,
        size: totalSize,
        type: 1,
        parentPath: dirOfManga.parent.path,
        mangaRecord: mangaRecord,
        shouldUpdate: countChanged,
      );
    } catch (e) {
      LogUtil.e('Failed to load manga from ${dirOfManga.path}', error: e);
      return null;
    }
  }

  Future<Manga?> _loadZipManga(File zipFile, {MangaData? dbRecord}) async {
    try {
      final mangaId = MangaId.fromPath(zipFile.path);
      final mangaRecord = dbRecord ?? await MangaDao.getManga(mangaId.value);

      final reader = await ZipReader.open(zipFile);
      String coverPath;
      int pageCount;
      try {
        final imageEntries = reader
            .readEntries()
            .where((e) => _isImageName(e.name))
            .toList()
          ..sort((a, b) => FileUtil.naturalCompare(a.name, b.name));
        if (imageEntries.isEmpty) return null;
        pageCount = imageEntries.length;

        final cacheDir = Directory(
          join(Directory.systemTemp.path, 'manga_reader', mangaId.value),
        );
        if (!await cacheDir.exists()) {
          await cacheDir.create(recursive: true);
        }

        final coverFile = File(join(cacheDir.path, imageEntries.first.name));
        coverPath = coverFile.path;
        if (!await coverFile.exists()) {
          await coverFile.writeAsBytes(reader.readEntryContent(imageEntries.first));
        }
      } finally {
        reader.close();
      }

      return _createAndPersistManga(
        mangaId: mangaId,
        path: zipFile.path,
        coverPath: coverPath,
        title: basenameWithoutExtension(zipFile.path),
        pageCount: pageCount,
        size: zipFile.lengthSync(),
        type: 2,
        parentPath: dirname(zipFile.path),
        mangaRecord: mangaRecord,
      );
    } catch (e) {
      LogUtil.e('Failed to load ZIP manga from ${zipFile.path}', error: e);
      return null;
    }
  }

  Future<Manga?> _loadEpubManga(File epubFile, {MangaData? dbRecord}) async {
    try {
      final mangaId = MangaId.fromPath(epubFile.path);
      final mangaRecord = dbRecord ?? await MangaDao.getManga(mangaId.value);

      final reader = await ZipReader.open(epubFile);
      String coverPath;
      int pageCount;
      try {
        final entries = reader.readEntries();
        final imageEntries = _resolveEpubImageEntries(reader, entries);
        if (imageEntries.isEmpty) return null;
        pageCount = imageEntries.length;

        final cacheDir = Directory(
          join(Directory.systemTemp.path, 'manga_reader', mangaId.value),
        );
        if (!await cacheDir.exists()) {
          await cacheDir.create(recursive: true);
        }

        final coverName = imageEntries.first.name.replaceAll('/', '_');
        final coverFile = File(join(cacheDir.path, coverName));
        coverPath = coverFile.path;
        if (!await coverFile.exists()) {
          await coverFile.writeAsBytes(reader.readEntryContent(imageEntries.first));
        }
      } finally {
        reader.close();
      }

      return _createAndPersistManga(
        mangaId: mangaId,
        path: epubFile.path,
        coverPath: coverPath,
        title: basenameWithoutExtension(epubFile.path),
        pageCount: pageCount,
        size: epubFile.lengthSync(),
        type: 3,
        parentPath: dirname(epubFile.path),
        mangaRecord: mangaRecord,
      );
    } catch (e) {
      LogUtil.e('Failed to load EPUB manga from ${epubFile.path}', error: e);
      return null;
    }
  }

  /// Resolves the image entries from an EPUB's OPF spine order.
  /// Falls back to natural sort of all image files if OPF parsing fails.
  List<ZipEntryMeta> _resolveEpubImageEntries(ZipReader reader, List<ZipEntryMeta> entries) {
    try {
      final containerEntry = entries.where((e) => e.name == 'META-INF/container.xml').firstOrNull;
      if (containerEntry == null) return _fallbackEpubImages(entries);

      final containerXml = XmlDocument.parse(utf8.decode(reader.readEntryContent(containerEntry)));
      final rootfile = containerXml.descendants
          .whereType<XmlElement>()
          .firstWhere((e) => e.name.local == 'rootfile');
      final opfPath = rootfile.getAttribute('full-path')!;

      final opfEntry = entries.where((e) => e.name == opfPath).firstOrNull;
      if (opfEntry == null) return _fallbackEpubImages(entries);

      final opfXml = XmlDocument.parse(utf8.decode(reader.readEntryContent(opfEntry)));
      final manifest = <String, String>{};
      for (final e in opfXml.descendants.whereType<XmlElement>()) {
        if (e.name.local == 'item') {
          manifest[e.getAttribute('id')!] = e.getAttribute('href')!;
        }
      }

      final opfDir = dirname(opfPath);
      final spineImages = <ZipEntryMeta>[];
      for (final e in opfXml.descendants.whereType<XmlElement>()) {
        if (e.name.local != 'itemref') continue;
        final href = manifest[e.getAttribute('idref')];
        if (href == null) continue;
        final fullPath = normalize(join(opfDir, href));
        final entry = reader.findEntry(fullPath);
        if (entry != null && _isImageName(entry.name)) {
          spineImages.add(entry);
        }
      }
      if (spineImages.isNotEmpty) return spineImages;
    } catch (e) {
      LogUtil.d('EPUB OPF spine parse failed, falling back to natural sort', error: e);
    }

    return _fallbackEpubImages(entries);
  }

  List<ZipEntryMeta> _fallbackEpubImages(List<ZipEntryMeta> entries) {
    return entries
        .where((e) => _isImageName(e.name))
        .toList()
      ..sort((a, b) => FileUtil.naturalCompare(a.name, b.name));
  }

  Future<Manga> _createAndPersistManga({
    required MangaId mangaId,
    required String path,
    required String coverPath,
    required String title,
    required int pageCount,
    required int size,
    required int type,
    required String parentPath,
    required MangaData? mangaRecord,
    bool shouldUpdate = false,
  }) async {
    final result = Manga(
      id: mangaId,
      path: path,
      cover: LocalImage(path: coverPath),
      title: title,
      lastReadPage: mangaRecord?.lastReadPage ?? 0,
      lastReadTime: mangaRecord?.lastReadTime,
      groupName: mangaRecord?.groupName ?? Constants.defaultGroupName,
      pageCount: pageCount,
      size: size,
    );

    if (mangaRecord == null) {
      await MangaDao.insertManga(MangaCompanion.insert(
        id: result.id.value,
        title: result.title,
        coverPath: Value(result.cover.path),
        parentPath: parentPath,
        pageCount: result.pageCount,
        size: result.size,
        sortOrder: 0,
        type: type,
      ));
    } else if (shouldUpdate) {
      await MangaDao.updateManga(MangaCompanion(
        id: Value(result.id.value),
        size: Value(result.size),
        pageCount: Value(result.pageCount),
      ));
    }
    return result;
  }

  List<a.ArchiveFile> _parseEpubImages(a.Archive archive) {
    try {
      final containerEntry = archive.files.firstWhere(
        (f) => f.name == 'META-INF/container.xml',
      );

      final containerXml =
          XmlDocument.parse(utf8.decode(containerEntry.content as List<int>));
      final rootfile = containerXml
          .descendants
          .whereType<XmlElement>()
          .firstWhere((e) => e.name.local == 'rootfile');
      final opfPath = rootfile.getAttribute('full-path')!;

      final opfEntry = archive.files.firstWhere((f) => f.name == opfPath);
      final opfXml =
          XmlDocument.parse(utf8.decode(opfEntry.content as List<int>));

      final manifest = <String, String>{};
      for (final e in opfXml.descendants.whereType<XmlElement>()) {
        if (e.name.local == 'item') {
          manifest[e.getAttribute('id')!] = e.getAttribute('href')!;
        }
      }

      final opfDir = dirname(opfPath);
      final spineImages = <a.ArchiveFile>[];
      for (final e in opfXml.descendants.whereType<XmlElement>()) {
        if (e.name.local != 'itemref') continue;
        final href = manifest[e.getAttribute('idref')];
        if (href == null) continue;
        final fullPath = normalize(join(opfDir, href));
        final entry =
            archive.files.where((f) => f.name == fullPath).firstOrNull;
        if (entry != null && _isImageName(entry.name)) {
          spineImages.add(entry);
        }
      }

      if (spineImages.isNotEmpty) return spineImages;
    } catch (e) {
      LogUtil.d('EPUB spine image parse failed, falling back to natural sort', error: e);
    }

    // Fallback: natural sort of all image files in the archive
    return archive.files
        .where((f) => f.isFile && _isImageName(f.name))
        .toList()
      ..sort((a, b) => FileUtil.naturalCompare(a.name, b.name));
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
    var total = 0;
    for (final f in images) {
      total += await f.length();
    }
    return total;
  }

  /// Archive mangas to ZIP files. Returns number of successfully archived.
  /// Archive mangas in-place: each manga's folder is zipped to
  /// `<mangaPath>.zip`, then the source folder is deleted after verification.
  Future<int> archiveMangasInPlace(
    List<Manga> mangas, {
    void Function(int current, int total)? onProgress,
  }) async {
    var successCount = 0;
    for (var i = 0; i < mangas.length; i++) {
      final manga = mangas[i];
      try {
        final archive = a.Archive();
        final images = await getMangaImagesAsync(manga);
        for (final image in images) {
          final file = File(image.path);
          final bytes = await file.readAsBytes();
          archive.addFile(a.ArchiveFile(basename(image.path), bytes.length, bytes));
        }
        final zipData = a.ZipEncoder().encode(archive);
        final zipPath = '${manga.path}.zip';
        await File(zipPath).writeAsBytes(zipData);

        // Verify ZIP before deleting source
        final zipFile = File(zipPath);
        if (await zipFile.exists() && await zipFile.length() > 0) {
          await FileUtil.deleteDir(Directory(manga.path));
          await MangaDao.deleteManga(manga.id.value);

          // Update in-memory cache: remove old manga, add new ZIP manga
          for (final entry in settingPath2Mangas.entries) {
            entry.value.removeWhere((m) => m.id == manga.id);
          }
          final zipManga = await _loadZipManga(zipFile);
          if (zipManga != null) {
            final parentDir = dirname(zipFile.path);
            if (settingPath2Mangas.containsKey(parentDir)) {
              settingPath2Mangas[parentDir]!.add(zipManga);
            }
          }
          successCount++;
        }
        onProgress?.call(i + 1, mangas.length);
      } catch (e) {
        LogUtil.e('归档失败: ${manga.title}', error: e);
      }
    }
    return successCount;
  }

  List<LocalImage> getMangaImages(Manga manga) {
    if (manga.path.endsWith('.epub')) {
      return _getEpubImages(File(manga.path));
    }
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

  List<LocalImage> _getEpubImages(File epubFile) {
    final mangaId = MangaId.fromPath(epubFile.path);
    final cacheDir = Directory(
      join(Directory.systemTemp.path, 'manga_reader', mangaId.value),
    );
    cacheDir.createSync(recursive: true);
    final bytes = epubFile.readAsBytesSync();
    final archive = a.ZipDecoder().decodeBytes(bytes);
    final entries = _parseEpubImages(archive);
    return entries.map((e) {
      final name = e.name.replaceAll('/', '_');
      final outFile = File(join(cacheDir.path, name));
      if (!outFile.existsSync()) outFile.writeAsBytesSync(e.content as List<int>);
      return LocalImage(path: outFile.path);
    }).toList();
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
    if (manga.path.endsWith('.epub')) {
      return _getEpubImagesAsync(File(manga.path));
    }
    if (isZipFile(manga.path)) {
      return _getZipMangaImagesAsync(File(manga.path));
    }
    final imageFiles = (await Directory(manga.path).list().toList())
        .whereType<File>()
        .where((f) => f.isImageExtension)
        .toList();
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
    if (!await cacheDir.exists()) await cacheDir.create(recursive: true);
    final result = <LocalImage>[];
    for (final e in entries) {
      final outFile = File(join(cacheDir.path, e.name));
      if (!await outFile.exists()) await outFile.writeAsBytes(e.content as List<int>);
      result.add(LocalImage(path: outFile.path));
    }
    return result;
  }

  Future<List<LocalImage>> _getEpubImagesAsync(File epubFile) async {
    final mangaId = MangaId.fromPath(epubFile.path);
    final cacheDir = Directory(
      join(Directory.systemTemp.path, 'manga_reader', mangaId.value),
    );
    if (!await cacheDir.exists()) await cacheDir.create(recursive: true);
    final bytes = await epubFile.readAsBytes();
    final archive = a.ZipDecoder().decodeBytes(bytes);
    final entries = _parseEpubImages(archive);
    final result = <LocalImage>[];
    for (final e in entries) {
      final name = e.name.replaceAll('/', '_');
      final outFile = File(join(cacheDir.path, name));
      if (!await outFile.exists()) await outFile.writeAsBytes(e.content as List<int>);
      result.add(LocalImage(path: outFile.path));
    }
    return result;
  }

  Future<Manga?> mergeMangas(
    List<Manga> mangas,
    Directory output, {
    int imageNameStartFrom = 0,
    bool outputAsZip = false,
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

    if (outputAsZip) {
      final archive = a.Archive();
      final files = output.listSync().whereType<File>().where((f) => f.isImageExtension).toList()
        ..sort(FileUtil.naturalCompareFileOrDir);
      for (final f in files) {
        final bytes = await f.readAsBytes();
        archive.addFile(a.ArchiveFile(basename(f.path), bytes.length, bytes));
      }
      final zipData = a.ZipEncoder().encode(archive);
      final zipPath = '${output.path}.zip';
      await File(zipPath).writeAsBytes(zipData);
      await output.delete(recursive: true);
      final manga = await _loadZipManga(File(zipPath));
      if (manga != null) return manga;
      return loadManga(Directory(zipPath));
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

  /// Deletes a single image entry from a ZIP/CBZ file and clears the temp cache.
  ///
  /// Reads the entire ZIP into memory, removes the entry, and re-encodes it.
  Future<void> deleteImageFromZip(File zipFile, String entryName) async {
    try {
      final bytes = await zipFile.readAsBytes();
      final archive = a.ZipDecoder().decodeBytes(bytes);

      // archive.files may be unmodifiable — filter into a new list
      final toKeep = archive.files.where((f) => f.name != entryName).toList();

      if (toKeep.length == archive.files.length) {
        Fluttertoast.showToast(msg: '未找到该图片');
        return;
      }

      archive.clear();
      for (final f in toKeep) {
        archive.addFile(f);
      }

      final newBytes = a.ZipEncoder().encode(archive);
      await zipFile.writeAsBytes(newBytes);

      // Clear temp cache so it regenerates with updated entries
      final cacheDir = Directory(
        join(
          Directory.systemTemp.path,
          'manga_reader',
          MangaId.fromPath(zipFile.path).value,
        ),
      );
      if (cacheDir.existsSync()) cacheDir.deleteSync(recursive: true);

      Fluttertoast.showToast(msg: '删除成功');
    } catch (e) {
      LogUtil.e('删除ZIP图片失败', error: e);
      Fluttertoast.showToast(msg: '删除失败');
      rethrow;
    }
  }
}
