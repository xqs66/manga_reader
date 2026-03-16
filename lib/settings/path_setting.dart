import 'package:get/get.dart';
import 'package:manga_reader/service/base/service_lifecircle_bean.dart';
import 'package:manga_reader/service/storage_service.dart';
import 'package:manga_reader/shared/utils/permission_util.dart';

PathSetting pathSetting = PathSetting();

class PathSetting with ServiceBeanMixin implements ServiceLifeCircleBean {
  late final RxList<String> paths;

  @override
  List<ServiceLifeCircleBean> get initDependencies => [storageService];

  @override
  Future<void> doAfterReady() async {}

  @override
  Future<void> doInit() async {
    final List<String> savedPaths = (storageService.read('manga_paths') ?? [])
        .cast<String>();
    paths = savedPaths.obs;
  }

  void addPath(String path) async {
    final isPermissionGranted = await PermissionUtil.checkAndRequestStoragePermission();
    if (!isPermissionGranted) return;

    if (paths.contains(path)) return;
    paths.add(path);
    savePathConfig();
  }

  void removePath(String path) {
    if (!paths.contains(path)) return;
    paths.remove(path);
    savePathConfig();
  }

  Future<void> savePathConfig() async {
    await storageService.write('manga_paths', paths);
  }

  void loadPathConfig() {
    final List<String> savedPaths = (storageService.read('manga_paths') ?? [])
        .cast<String>();
    paths.assignAll(savedPaths);
  }
}
