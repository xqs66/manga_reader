import 'package:manga_reader/service/path_service.dart';

extension StringExtension on String {
  String displayPath() =>
      replaceFirst(pathService.appExternalStorageRootDir?.path ?? '', '...');
}
