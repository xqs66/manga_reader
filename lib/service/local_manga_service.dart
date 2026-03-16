import 'dart:async';
import 'dart:io';

import 'package:manga_reader/models/local_image.dart';
import 'package:manga_reader/service/base/service_lifecircle_bean.dart';
import 'package:manga_reader/service/path_service.dart';
import 'package:manga_reader/settings/path_setting.dart';
import 'package:manga_reader/shared/extensions/file_system_entity_ext.dart';
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

  final Map<String, List<Manga>> mangasInLocalSettingPaths = {};

  @override
  Future<void> doInit() async {
    await loadMangasInLocalSettingPaths();
  }

  @override
  Future<void> doAfterReady() async {}

  Future<void> loadMangasInLocalSettingPaths() {
    mangasInLocalSettingPaths.clear();
    List<Future<void>> futures = pathSetting.paths
        .map(
          (path) => _loadMangasInDir(
            Directory(path),
            mangasInLocalSettingPaths[path] ??= [],
          ),
        )
        .toList();
    return Future.wait(futures).whenComplete(() {
      for (final dirs in mangasInLocalSettingPaths.values) {
        dirs.sort((a, b) => FileUtil.naturalCompare(a.title, b.title));
      }
    });
  }

  Future<void> _loadMangasInDir(Directory parentDir, List<Manga> mangas) {
    final List<Future<void>> futures = parentDir
        .listSync()
        .whereType<Directory>()
        .map((dir) => _loadMangaInfo(dir, mangas))
        .toList();
    return Future.wait(futures);
  }

  Future<List<Manga>> getMangasInDir(Directory dir) async {
    if (mangasInLocalSettingPaths.containsKey(dir.path)) {
      return mangasInLocalSettingPaths[dir.path]!;
    }

    final List<Manga> mangas = [];
    await _loadMangasInDir(dir, mangas);
    return mangas;
  }

  // Future<void> _loadMangaInfo(Directory dir, List<Manga> mangas) {
  //   final completer = Completer<void>();
  //   List<File> images = [];
  //   int size = 0;
  //   dir.list().listen(
  //     (entity) {
  //       if (entity is File && entity.isImageExtension) {
  //         images.add(entity);
  //         size += entity.statSync().size;
  //       }
  //       if (entity is Directory) {
  //         // TODO 递归获取子目录的图片
  //       }
  //     },
  //     onDone: () {
  //       if (images.isNotEmpty) {
  //         images.sort(FileUtil.naturalCompareFileOrDir);
  //         mangas.add(
  //           Manga(
  //             path: dir.path,
  //             cover: LocalImage(path: images.first.path),
  //             title: basename(dir.path),
  //             pageCount: images.length,
  //             size: size,
  //           ),
  //         );
  //       }
  //       completer.complete();
  //     },
  //     onError: completer.completeError,
  //   );
  //   return completer.future;
  // }

  Future<void> _loadMangaInfo(Directory dir, List<Manga> mangas) async {
    List<File> images = [];
    int size = 0;

    try {
      await for (final entity in dir.list()) {
        if (entity is File && entity.isImageExtension) {
          images.add(entity);
          final stat = await entity.stat();
          size += stat.size;
        }
        if (entity is Directory) {
          // TODO 递归获取子目录的图片
        }
      }
      if (images.isNotEmpty) {
        images.sort(FileUtil.naturalCompareFileOrDir);
        mangas.add(
          Manga(
            path: dir.path,
            cover: LocalImage(path: images.first.path),
            title: basename(dir.path),
            pageCount: images.length,
            size: size,
          ),
        );
      }
    } catch (e) {
      LogUtil.e('Failed to load manga from ${dir.path}');
    }
  }

  List<LocalImage> getMangaImages(Manga manga) {
    final imageFiles =
        Directory(manga.path)
            .listSync()
            .whereType<File>()
            .where((file) => FileUtil.isImageExtension(file.path))
            .toList()
          ..sort(FileUtil.naturalCompareFileOrDir);
    return imageFiles.map((file) => LocalImage(path: file.path)).toList();
  }
}
