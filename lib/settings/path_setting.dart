import 'dart:io';

import 'package:get/get.dart';
import 'package:manga_reader/service/base/config_bean.dart';
import 'package:manga_reader/service/base/service_lifecircle_bean.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/service/storage_service.dart';
import 'package:manga_reader/core/utils/permission_util.dart';

PathSetting pathSetting = PathSetting();

class PathSetting extends ConfigBean with ServiceBeanMixin{
  late final RxList<String> paths;

  @override
  List<ServiceLifeCircleBean> get initDependencies => [storageService];

  @override
  Future<void> doAfterReady() async {}

  @override
  Future<void> doInit() async {
    final List<String> savedPaths = (storageService.read('manga_paths') ?? [])
        .cast<String>();
    savedPaths.removeWhere((path) => !Directory(path).existsSync());
    paths = savedPaths.obs;
  }

  Future<void> addPath(String path) async {
    final isPermissionGranted = await PermissionUtil.checkAndRequestStoragePermission();
    if (!isPermissionGranted) return;

    if (paths.contains(path) || path.isEmpty) return;
    paths.add(path);
    saveConfig('manga_paths', paths);

    // Load mangas for the new path immediately so the bookshelf
    // shows content without the user needing to manually refresh.
    localMangaService.loadMangasInDir(Directory(path));
  }

  void removePath(String path) {
    if (!paths.contains(path)) return;
    paths.remove(path);
    localMangaService.settingPath2Mangas.remove(path);
    saveConfig('manga_paths', paths);
  }

  void loadPathConfig() {
    final List<String> savedPaths = storageService.read<List<String>>('manga_paths') ?? [];
    paths.assignAll(savedPaths);
  }
}
