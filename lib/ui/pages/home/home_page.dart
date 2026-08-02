import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/ui/pages/edit/edit_page.dart';
import 'package:manga_reader/ui/pages/more/more_page.dart';

import 'package:manga_reader/ui/pages/mangas/mangas_page.dart';
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
        // IndexedStack keeps every tab's State alive, so switching away and
        // back preserves scroll position and selection instead of rebuilding.
        return IndexedStack(
          index: _state.pageIndex,
          children: [
            const EditPage(key: ValueKey('edit')),
            MangasPage(key: ValueKey('mangas')),
            const MorePage(key: ValueKey('more')),
          ],
        );
      },
    );
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
