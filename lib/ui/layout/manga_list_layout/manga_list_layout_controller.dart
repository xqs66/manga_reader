import 'dart:async';

import 'package:get/get.dart';
import 'package:manga_reader/settings/read_setting.dart';
import 'manga_list_layout_state.dart';

abstract class MangaListLayoutController<S extends MangaListLayoutState>
    extends GetxController {
  S get state;

  String get appBarId => 'appBarId';
  String get bodyId => 'bodyId';

  Timer? _searchDebounceTimer;

  void toggleSearchMode() {
    state.isSearchMode = !state.isSearchMode;
    if (!state.isSearchMode) {
      state.searchTextController.clear();
      state.searchedMangas.clear();
    } else {
      state.searchedMangas.assignAll(state.mangas);
    }
    update([appBarId, bodyId]);
  }

  void handleSearch(String keyword) {
    update([appBarId]);
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (keyword.isEmpty) {
        state.searchedMangas.assignAll(state.mangas);
      } else {
        final kw = keyword.toLowerCase();
        state.searchedMangas.assignAll(
          state.mangas.where((m) => m.title.toLowerCase().contains(kw)).toList(),
        );
      }
      update([bodyId]);
    });
  }

  void toggleLayoutMode() {
    final next = readSetting.bookshelfLayout.value == BookshelfLayout.list
        ? BookshelfLayout.grid
        : BookshelfLayout.list;
    readSetting.saveBookshelfLayout(next);
    update([bodyId, appBarId]);
  }

  @override
  void onClose() {
    _searchDebounceTimer?.cancel();
    super.onClose();
  }
}
