import 'package:get/get.dart';
import 'package:manga_reader/pages/edit/archive_mangas/archive_mangas_page.dart';
import 'package:manga_reader/pages/edit/merge_mangas_page/merge_mangas_page.dart';
import 'package:manga_reader/pages/home_page.dart';
import 'package:manga_reader/pages/reader/reader_page.dart';
import 'package:manga_reader/pages/settings/local/path_setting_page.dart';
import 'package:manga_reader/pages/settings/read/read_settings_page.dart';

class Routes {
  static const String root = '/';
  static const String reader = '/reader';
  static const String localSetting = '/settings/localSetting';
  static const String readSetting = '/edit/readSetting';
  static const String mergeMangas = '/edit/editMangas';
  static const String archiveMangas = '/edit/archiveMangas';

  static Transition defaultTransition = Transition.cupertino;

  static final pages = [
    GetPage(name: root, page: () => HomePage(), transition: defaultTransition),
    GetPage(name: reader, page: () => ReaderPage(), transition: defaultTransition),
    GetPage(name: localSetting, page: () => PathSettingPage(), transition: defaultTransition),
    GetPage(name: readSetting, page: () => ReadSettingsPage(), transition: defaultTransition),
    GetPage(name: mergeMangas, page: () => MergeMangasPage(), transition: defaultTransition),
    GetPage(name: archiveMangas, page: () => const ArchiveMangasPage(), transition: defaultTransition),
  ];
}
