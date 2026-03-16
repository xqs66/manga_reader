import 'dart:io';

import 'package:manga_reader/shared/utils/file_util.dart';

extension FileSystemEntityExt on FileSystemEntity {
  String get fileOrDirName => path.split(Platform.pathSeparator).last;

  bool get isImageExtension => FileUtil.isImageExtension(path);
}