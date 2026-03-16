import 'package:get/get.dart';
import 'package:manga_reader/pages/books/books_page.dart';
import 'package:manga_reader/pages/edit/merge_mangas_page/merge_mangas_page.dart';
import 'package:manga_reader/pages/home_page.dart';
import 'package:manga_reader/pages/reader/reader_page.dart';
import 'package:manga_reader/pages/settings/path_setting_page.dart';

class Routes {
  static const String root = '/';
  static const String reader = '/reader';
  static const String settingsPath = '/settings/pathSetting';
  static const String mergeMangas = '/edit/editMangas';

  static final pages = [
    GetPage(
      name: root,
      page: () => HomePage(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: reader,
      page: () => ReaderPage(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: settingsPath,
      page: () => PathSettingPage(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: mergeMangas,
      page: () => MergeMangasPage(),
      transition: Transition.cupertino,
    ),
  ];
}
