import 'dart:convert';

import 'package:manga_reader/service/path_service.dart';
import 'package:crypto/crypto.dart';

extension StringExtension on String {
  String displayPath() =>
      replaceFirst(pathService.appExternalStorageRootDir?.path ?? '', '...');

  String hash() => md5.convert(utf8.encode(this)).toString();
}
