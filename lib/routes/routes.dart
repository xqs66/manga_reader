import 'package:get/get.dart';
import 'package:manga_reader/pages/edit/archive_mangas/archive_mangas_page.dart';
import 'package:manga_reader/pages/edit/merge_mangas_page/merge_mangas_page.dart';
import 'package:manga_reader/pages/home_page.dart';
import 'package:manga_reader/pages/more/manage/group_manage_page.dart';
import 'package:manga_reader/pages/reader/reader_page.dart';
import 'package:manga_reader/pages/more/manage/path_manage_page.dart';
import 'package:manga_reader/pages/more/settings/read/read_settings_page.dart';
import 'package:manga_reader/pages/more/settings/settings_page.dart';

class Routes {
  static const String root = '/';
  static const String reader = '/reader';
  static const String editMerge = '/edit/merge';
  static const String editArchive = '/edit/archive';
  static const String moreSettings = '/more/settings';
  static const String morePaths = '/more/paths';
  static const String moreReadSetting = '/more/readSetting';
  static const String moreGroupManage = '/more/groupManage';
  static const String tapDemo = '/tapdemo';

  static final pages = [
    GetPage(name: root, page: () => HomePage()),
    GetPage(name: reader, page: () => ReaderPage()),
    GetPage(name: moreSettings, page: () => const SettingsPage()),
    GetPage(name: morePaths, page: () => const PathManagePage()),
    GetPage(name: moreReadSetting, page: () => const ReadSettingsPage()),
    GetPage(name: moreGroupManage, page: () => const GroupManagePage()),
    GetPage(name: editMerge, page: () => MergeMangasPage()),
    GetPage(name: editArchive, page: () => const ArchiveMangasPage()),
  ];
}
