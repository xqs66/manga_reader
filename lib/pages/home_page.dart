import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/pages/edit/edit_page.dart';
import 'package:manga_reader/pages/more/more_page.dart';

import 'mangas/mangas_page.dart';
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
        return MangasPage(key: ValueKey('mangas'));
      case 2:
        return const MorePage(key: ValueKey('more'));
      default:
        return MangasPage(key: ValueKey('mangas'));
    }
  }

  Widget _buildBottomNavigationBar() {
    return GetBuilder<HomePageController>(
      id: _controller.bottomBarId,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return _state.showBottomBar
            ? NavigationBar(
                animationDuration: const Duration(milliseconds: 400),
                selectedIndex: _state.pageIndex,
                onDestinationSelected:
                    _controller.handleBottomBarTabIndexChanged,
                labelBehavior: .alwaysShow,
                backgroundColor: isDark
                    ? const Color(0xE61E1E1E)
                    : const Color(0xE6FFFFFF),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.auto_fix_high_rounded),
                    selectedIcon: Icon(Icons.auto_fix_high_rounded, size: 28),
                    label: '编辑',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.collections_bookmark_rounded),
                    selectedIcon: Icon(Icons.collections_bookmark_rounded, size: 28),
                    label: '书架',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.more_horiz_rounded),
                    selectedIcon: Icon(Icons.more_horiz_rounded, size: 28),
                    label: '更多',
                  ),
                ],
              )
            : const SizedBox.shrink();
      },
    );
  }
}
