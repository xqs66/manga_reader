import 'dart:io';
import 'package:path/path.dart' as p;

extension FileSystemEntityExt on FileSystemEntity {
  String get fileOrDirName => path.split(Platform.pathSeparator).last;

  bool get isImageExtension {
    String s = path.toLowerCase();
    return s.endsWith('.jpg') ||
        s.endsWith('.png') ||
        s.endsWith('.gif') ||
        s.endsWith('.jpeg') ||
        s.endsWith('.webp');
  }

  String get extension => p.extension(path);
}
