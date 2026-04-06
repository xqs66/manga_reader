import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
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
import 'package:manga_reader/shared/extensions/string_ext.dart';
import 'package:manga_reader/shared/utils/file_util.dart';
import 'package:path/path.dart';

import '../models/manga.dart';
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
    List<Future<void>> futures = pathSetting.paths
        .map((path) => loadMangasInDir(Directory(path)))
        .toList();
    return Future.wait(futures);
  }

  Future<List<Manga>> loadMangasInDir(Directory dir) async {
    final Completer<List<Manga>> completer = Completer();
    final List<Manga> mangas = [];
    final List<Future> futures = [];
    dir.list().listen(
      (entity) {
        if (entity is Directory) {
          futures.add(
            loadManga(entity).then((manga) {
              if (manga != null) {
                mangas.add(manga);
              }
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
    return await loadMangasInDir(dir);
  }

  Future<void> refreshMangasInDir(Directory dir) async {
    await loadMangasInDir(dir);
  }

  Future<Manga?> loadManga(Directory dirOfManga) async {
    List<File> images = [];
    int size = 0;
    final List<Future<int>> sizeCalcFutures = [];

    try {
      final mangaFromQurey = await MangaDao.getManga(dirOfManga.path.hash());

      await for (final entity in dirOfManga.list()) {
        if (entity is File && entity.isImageExtension) {
          images.add(entity);
          sizeCalcFutures.add(entity.length());
        }
        if (entity is Directory) {
          // TODO 递归获取子目录的图片
        }
      }

      if (images.isNotEmpty) {
        images.sort(FileUtil.naturalCompareFileOrDir);

        if (sizeCalcFutures.isNotEmpty) {
          final sizes = await Future.wait(sizeCalcFutures);
          size = sizes.fold(0, (sum, fileSize) => sum + fileSize);
        }

        final result = Manga(
          id: dirOfManga.path.hash(),
          path: dirOfManga.path,
          cover: LocalImage(path: images.first.path),
          title: basename(dirOfManga.path),
          lastReadPage: mangaFromQurey?.lastReadPage ?? 0,
          groupName: mangaFromQurey?.groupName ?? Constants.defaultGroupName,
          pageCount: images.length,
          size: size,
        );

        if (mangaFromQurey == null) {
          MangaDao.insertManga(
            MangaCompanion.insert(
              id: result.id,
              title: result.title,
              coverPath: result.cover.path,
              parentPath: dirOfManga.parent.path,
              pageCount: result.pageCount,
              size: result.size,
              sortOrder: 0,
              type: 1,
            ),
          );
        }
        return result;
      } else {
        return null;
      }
    } catch (e) {
      LogUtil.e('Failed to load manga from ${dirOfManga.path}');
      return null;
    }
  }

  List<LocalImage> getMangaImages(Manga manga) {
    final imageFiles =
        Directory(manga.path)
            .listSync()
            .whereType<File>()
            .where((file) => file.isImageExtension)
            .toList()
          ..sort(FileUtil.naturalCompareFileOrDir);
    return imageFiles.map((file) => LocalImage(path: file.path)).toList();
  }

  Future<List<LocalImage>> getMangaImagesAsync(Manga manga) async {
    final imageFiles = <File>[];

    await for (final entity in Directory(manga.path).list()) {
      if (entity is File && entity.isImageExtension) {
        imageFiles.add(entity);
      }
    }
    imageFiles.sort(FileUtil.naturalCompareFileOrDir);

    return imageFiles.map((file) => LocalImage(path: file.path)).toList();
  }

  // TODO
  // 1.添加进度回调
  // 2.优化性能
  Future<Manga?> mergeMangas(
    List<Manga> mangas,
    Directory output, {
    int imageNameStartFrom = 0,
  }) async {
    output = await output.create(recursive: true);

    final totalImageCount = mangas.fold(
      0,
      (sum, manga) => sum + manga.pageCount,
    );
    final digits = totalImageCount.toString().length;

    final List<List<LocalImage>> sourceImageFiles = [];

    for (final manga in mangas) {
      final imageFiles = await getMangaImagesAsync(manga);
      sourceImageFiles.add(imageFiles);

      for (final image in imageFiles) {
        final imageFile = File(image.path);
        final newName =
            '${imageNameStartFrom.toString().padLeft(digits, '0')}${extension(image.path)}';
        final target = File(join(output.path, newName));
        await imageFile.copy(target.path);
        imageNameStartFrom++;
      }
    }
    return loadManga(output);
  }

  Future<void> deleteManga(Manga manga, {bool showToast = true}) {
    return MangaDao.deleteManga(manga.path.hash()).then((value) {
      if (value == 1) {
        FileUtil.deleteDir(Directory(manga.path))
            .then((_) {
              if (showToast) {
                Fluttertoast.showToast(msg: '已删除漫画：${manga.title}');
              }
            })
            .catchError((e) {
              LogUtil.e('删除漫画：${manga.title}失败', error: e);
              Fluttertoast.showToast(msg: '删除漫画：${manga.title}失败');
            });
      }
    });
  }

  Future<void> deleteMangas(List<Manga> mangas, {bool showToast = true}) {
    return Future.wait(
      mangas.map((manga) => deleteManga(manga, showToast: false)),
    ).then((_) {
      if (showToast) {
        Fluttertoast.showToast(msg: '删除成功');
      }
    });
  }

  Future<void> deleteImage(LocalImage image) {
    return FileUtil.deleteFile(File(image.path))
        .then((_) {
          Fluttertoast.showToast(msg: '删除成功');
        })
        .catchError((e) {
          LogUtil.e('删除图片失败', error: e);
          Fluttertoast.showToast(msg: '删除图片失败');
        });
  }
}
