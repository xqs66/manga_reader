import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/pages/edit/edit_page.dart';
import 'package:manga_reader/pages/settings/settings_page.dart';

import 'books/books_page.dart';
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
      body: _buildBody(context),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return GetBuilder<HomePageController>(
      id: 'home_page',
      builder: (_) {
        return Stack(
          children: [
            Offstage(offstage: _state.pageIndex != 0, child: EditPage()),
            Offstage(offstage: _state.pageIndex != 1, child: BooksPage()),
            Offstage(offstage: _state.pageIndex != 2, child: SettingsPage()),
          ],
        );
      },
    );
  }

  // Widget _buildBottomNavigationBar(BuildContext context) {
  //   return GetBuilder<HomePageController>(
  //     id: 'bottom_bar',
  //     builder: (_) {
  //       return NavigationBar(
  //         destinations: [
  //           NavigationDestination(icon: Icon(Icons.edit), label: 'edit'),
  //           NavigationDestination(icon: Icon(Icons.book), label: 'books'),
  //           NavigationDestination(
  //             icon: Icon(Icons.settings),
  //             label: 'settings',
  //           ),
  //         ],
  //         onDestinationSelected: _controller.handleBottomBarTabIndexChanged,
  //         selectedIndex: _state.pageIndex,
  //       );
  //     },
  //   );
  // }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return GetBuilder<HomePageController>(
      id: 'bottom_bar',
      builder: (_) {
        return BottomNavigationBar(
          currentIndex: _state.pageIndex,
          onTap: _controller.handleBottomBarTabIndexChanged,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          // selectedItemColor: UiConfig.primaryColor,
          type: .fixed,
          items: [
            BottomNavigationBarItem(
              label: 'edit',
              icon: Icon(Icons.edit),
            ),
            BottomNavigationBarItem(
              label: 'books',
              icon: Icon(Icons.book_sharp),
            ),
            BottomNavigationBarItem(
              label: 'settings',
              icon: Icon(Icons.settings),
            ),
          ],
        );
      },
    );
  }
}
