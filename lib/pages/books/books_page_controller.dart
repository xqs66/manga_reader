import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/mixin/scroll_handler.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/models/read_info.dart';
import 'package:manga_reader/pages/books/books_page_state.dart';
import 'package:manga_reader/routes/routes.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/shared/utils/file_util.dart';

class BooksPageController extends GetxController with ScrollHandler {
  final state = BooksPageState();

  @override
  ScrollState get scrollState => state;

  final bodyId = 'bodyId';
  final popUpMenuId = 'popUpMenuId';
  final mangaIdPrefix = 'Manga';

  void enterMangaDir(String path) {
    state.isAtRoot = false;
    state.currentPath = path;
    state.books = localMangaService.mangasInLocalSettingPaths[path] ?? [];
    update([bodyId, popUpMenuId]);
  }

  void back2Root() {
    state.isAtRoot = true;
    update([bodyId, popUpMenuId]);
  }

  void toggleOpen(int index) {
    if (state.displayGroups.contains(index)) {
      state.displayGroups.remove(index);
    } else {
      state.displayGroups.add(index);
    }
    update(['Group::$index']);
  }

  void handleMangaCardTap(Manga manga) {
    Get.toNamed(
      Routes.reader,
      arguments: ReadInfo(
        mangaInfo: manga,
        images: localMangaService.getMangaImages(manga),
        pageCount: manga.pageCount,
      ),
    );
  }

  Future<void> refreshMangas() async {
    await localMangaService.loadMangasInLocalSettingPaths();
    state.books =
        localMangaService.mangasInLocalSettingPaths[state.currentPath] ?? [];
    update([bodyId]);
  }

  Future<void> handleDeleteManga(Manga manga) {
    return Get.dialog(
      barrierDismissible: true,
      AlertDialog(
        title: Text('删除漫画'),
        content: Text('确定要删除漫画吗？'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('取消')),
          TextButton(
            onPressed: () async {
              localMangaService.deleteManga(manga);
              state.books.remove(manga);
              update([bodyId]);
              Get.back();
            },
            child: Text('确定'),
          ),
        ],
      ),
    );
  }
}
