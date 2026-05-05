import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/pages/edit/edit_page.dart';
import 'package:manga_reader/pages/settings/settings_page.dart';

import 'books/mangas_page.dart';
import 'home_page_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = Get.put(HomePageController(), permanent: true);
  final _state = Get.find<HomePageController>().state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    return GetBuilder<HomePageController>(
      id: _controller.homePageId,
      builder: (_) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _buildCurrentPage(),
        );
      },
    );
  }

  Widget _buildCurrentPage() {
    switch (_state.pageIndex) {
      case 0:
        return const EditPage(key: ValueKey('edit'));
      case 1:
        return const MangasPage(key: ValueKey('mangas'));
      case 2:
        return const SettingsPage(key: ValueKey('settings'));
      default:
        return const MangasPage(key: ValueKey('mangas'));
    }
  }

  Widget _buildBottomNavigationBar() {
    return GetBuilder<HomePageController>(
      id: _controller.bottomBarId,
      builder: (_) {
        return _state.showBottomBar
            ? NavigationBar(
                animationDuration: const Duration(milliseconds: 400),
                selectedIndex: _state.pageIndex,
                onDestinationSelected:
                    _controller.handleBottomBarTabIndexChanged,
                labelBehavior: .alwaysHide,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.build_rounded),
                    selectedIcon: Icon(Icons.build_rounded, size: 28),
                    label: '工具',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.library_books_rounded),
                    selectedIcon: Icon(Icons.library_books_rounded, size: 28),
                    label: '书架',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_rounded),
                    selectedIcon: Icon(Icons.settings_rounded, size: 28),
                    label: '设置',
                  ),
                ],
              )
            : const SizedBox.shrink();
      },
    );
  }
}
