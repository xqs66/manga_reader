import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:manga_reader/shared/extensions/file_system_entity_ext.dart';
import 'package:manga_reader/shared/utils/log_util.dart';

import '../constants/constants.dart';

class FileUtil {
  static Future<Directory?> selectDir() async {
    try {
      final path = await FilePicker.platform.getDirectoryPath();
      return Directory(path ?? '');
    } on Exception catch (e, stackTrace) {
      LogUtil.e(Constants.selectDirFailed, error: e, stackTrace: stackTrace);
      return null;
    }
  }

  static Future<void> fileRename(File file, String newName) async {
    try {
      file.rename(
        p.join(p.dirname(file.path), newName),
      );
    } on Exception catch (e, stackTrace) {
      LogUtil.e(Constants.renameFailed, error: e, stackTrace: stackTrace);
    }
  }

  static int naturalCompareFileOrDir(FileSystemEntity a, FileSystemEntity b) {
    if (a is File && b is Directory) return 1;
    if (a is Directory && b is File) return -1;
    return naturalCompare(a.fileOrDirName, b.fileOrDirName);
  }

  static int naturalCompare(String a, String b) {
    List<String> aParts = RegExp(
      r'(\d+|\D+)',
    ).allMatches(a).map((m) => m.group(0) ?? '').toList();
    List<String> bParts = RegExp(
      r'(\d+|\D+)',
    ).allMatches(b).map((m) => m.group(0) ?? '').toList();
    final minLen = min(aParts.length, bParts.length);

    for (int i = 0; i < minLen; i++) {
      String aPart = aParts[i];
      String bPart = bParts[i];
      int? aNum = int.tryParse(aPart);
      int? bNum = int.tryParse(bPart);

      if (aNum != null && bNum != null && aNum != bNum) {
        return aNum - bNum;
      }
      if (aPart.compareTo(bPart) != 0) {
        return aPart.compareTo(bPart);
      }
    }

    return aParts.length - bParts.length;
  }

  static String formatFileSize(int bytes) {
    if (bytes < 0) return '0 B';

    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
