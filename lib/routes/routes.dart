import 'package:get/get.dart';
import 'package:manga_reader/ui/pages/edit/archive_mangas/archive_mangas_page.dart';
import 'package:manga_reader/ui/pages/edit/merge_mangas/merge_mangas_page.dart';
import 'package:manga_reader/ui/pages/home/home_page.dart';
import 'package:manga_reader/ui/pages/lan/lan_discovery/lan_discovery_page.dart';
import 'package:manga_reader/ui/pages/lan/lan_server/lan_server_page.dart';
import 'package:manga_reader/ui/pages/lan/server_paths/server_paths_page.dart';
import 'package:manga_reader/ui/pages/more/manage/group_manage_page.dart';
import 'package:manga_reader/ui/pages/reader/reader_page.dart';
import 'package:manga_reader/ui/pages/more/manage/path_manage_page.dart';
import 'package:manga_reader/ui/pages/more/settings/read/read_settings_page.dart';
import 'package:manga_reader/ui/pages/more/settings/settings_page.dart';

class Routes {
  static const String root = '/';
  static const String reader = '/reader';
  static const String editMerge = '/edit/merge';
  static const String editArchive = '/edit/archive';
  static const String moreSettings = '/more/settings';
  static const String morePaths = '/more/paths';
  static const String moreReadSetting = '/more/readSetting';
  static const String moreGroupManage = '/more/groupManage';
  static const String lanServer = '/lan/server';
  static const String lanDiscovery = '/lan/discovery';
  static const String lanServerPaths = '/lan/serverPaths';

  static final pages = [
    GetPage(name: root, page: () => HomePage()),
    GetPage(name: reader, page: () => ReaderPage()),
    GetPage(name: moreSettings, page: () => const SettingsPage()),
    GetPage(name: morePaths, page: () => const PathManagePage()),
    GetPage(name: moreReadSetting, page: () => const ReadSettingsPage()),
    GetPage(name: moreGroupManage, page: () => const GroupManagePage()),
    GetPage(name: editMerge, page: () => MergeMangasPage()),
    GetPage(name: editArchive, page: () => const ArchiveMangasPage()),
    GetPage(name: lanServer, page: () => const LanServerPage()),
    GetPage(name: lanDiscovery, page: () => const LanDiscoveryPage()),
    GetPage(name: lanServerPaths, page: () => const ServerPathsPage()),
  ];
}
