import 'dart:io';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/service/log_service.dart';
import 'package:manga_reader/ui/pages/mangas/mangas_page_controller.dart';

import 'cache_manage_page_state.dart';

class CacheManagePageController extends GetxController {
  final state = CacheManagePageState();
  static const String bodyId = 'cacheManageBodyId';

  static final _tempDir =
      Directory('${Directory.systemTemp.path}${Platform.pathSeparator}manga_reader');

  @override
  void onReady() {
    super.onReady();
    loadCacheInfo();
  }

  Future<void> loadCacheInfo() async {
    state.isLoading = true;
    update([bodyId]);
    state.imageCacheSizeBytes = await _dirSize(_tempDir);
    state.logCacheSizeBytes = await _logDirSize();
    state.isLoading = false;
    update([bodyId]);
  }

  Future<int> _dirSize(Directory dir) async {
    if (!dir.existsSync()) return 0;
    var total = 0;
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
    } catch (_) {}
    return total;
  }

  Future<int> _logDirSize() async {
    final dirPath = logService.logDirectoryPath;
    if (dirPath == null) return 0;
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return 0;
    var total = 0;
    try {
      await for (final entity in dir.list().where((e) => e is File && e.path.endsWith('.log'))) {
        if (entity is File) total += await entity.length();
      }
    } catch (_) {}
    return total;
  }

  Future<void> clearImageCache() async {
    if (_tempDir.existsSync()) {
      try {
        await _tempDir.delete(recursive: true);
        Fluttertoast.showToast(msg: '图片缓存已清除');
      } catch (_) {
        Fluttertoast.showToast(msg: '清除失败');
      }
    }
    await loadCacheInfo();
    await _refreshBookshelfCovers();
  }

  /// ZIP/CBZ covers live in the temp cache we just wiped, so re-scan the
  /// current bookshelf directory to regenerate valid cover paths.
  Future<void> _refreshBookshelfCovers() async {
    if (!Get.isRegistered<MangasPageController>()) return;
    final ctrl = Get.find<MangasPageController>();
    final path = ctrl.state.currentPath;
    if (ctrl.state.isRemotePath || path == null) return;
    await localMangaService.refreshMangasInDir(Directory(path));
    ctrl.handlePopNext();
  }

  Future<void> clearLogCache() async {
    final dirPath = logService.logDirectoryPath;
    if (dirPath == null) return;
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return;
    try {
      await for (final entry in dir.list().where((e) => e is File && e.path.endsWith('.log'))) {
        await entry.delete();
      }
      Fluttertoast.showToast(msg: '日志已清除');
    } catch (_) {
      Fluttertoast.showToast(msg: '清除失败');
    }
    await loadCacheInfo();
  }
}
