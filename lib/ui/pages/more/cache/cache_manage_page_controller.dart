import 'dart:io';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:manga_reader/service/log_service.dart';
import 'package:share_plus/share_plus.dart';

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

  Future<void> exportLogs() async {
    final dirPath = logService.logDirectoryPath;
    if (dirPath == null) {
      Fluttertoast.showToast(msg: '日志目录不可用');
      return;
    }
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      Fluttertoast.showToast(msg: '没有日志文件可导出');
      return;
    }
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.log'))
        .toList();
    if (files.isEmpty) {
      Fluttertoast.showToast(msg: '没有日志文件可导出');
      return;
    }
    final xFiles = files.map((f) => XFile(f.path)).toList();
    await SharePlus.instance.share(ShareParams(files: xFiles));
  }
}
