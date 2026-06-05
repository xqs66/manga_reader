import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/settings/read_setting.dart';
import 'package:manga_reader/ui/widgets/empty_state.dart';
import 'package:manga_reader/ui/layout/grid/components/manga_grid_view.dart';
import 'package:manga_reader/ui/layout/list/components/manga_list_view.dart';
import 'manga_list_layout_controller.dart';
import 'manga_list_layout_state.dart';

mixin MangaListLayout<C extends MangaListLayoutController,
    S extends MangaListLayoutState> on Widget {
  C get controller;
  S get state;

  Widget buildSearchBox() {
    return TextField(
      autofocus: true,
      controller: state.searchTextController,
      onChanged: controller.handleSearch,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: '搜索漫画...',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
        contentPadding: .symmetric(vertical: 8),
        suffixIcon: state.searchTextController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  state.searchTextController.clear();
                  controller.handleSearch('');
                },
                icon: const Icon(Icons.clear_rounded, size: 20),
              )
            : null,
        border: .none,
        isDense: true,
      ),
    );
  }

  PreferredSizeWidget buildSearchAppBar() {
    return AppBar(
      leading: IconButton(
        onPressed: controller.toggleSearchMode,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: buildSearchBox(),
    );
  }

  List<Manga> get displayMangas =>
      state.isSearchMode ? state.searchedMangas : state.mangas;

  Widget buildSearchResults() {
    if (state.searchedMangas.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: '无搜索结果',
      );
    }
    if (readSetting.bookshelfLayout.value == BookshelfLayout.grid) {
      return buildMangaGridView();
    }
    return buildMangaListView();
  }

  Widget buildMangaGridView() {
    return MangaGridView(
      mangas: displayMangas,
      cardBuilder: buildGridCard,
    );
  }

  Widget buildMangaListView() {
    return MangaListView(
      mangas: displayMangas,
      tileBuilder: buildListTile,
    );
  }

  Widget buildBody(BuildContext context) {
    return GetBuilder<C>(
      id: controller.bodyId,
      builder: (_) {
        if (state.isSearchMode) return buildSearchResults();
        return buildNormalContent(context);
      },
    );
  }

  Widget buildLayout(BuildContext context) {
    return GetBuilder<C>(
      id: controller.appBarId,
      builder: (_) {
        return Scaffold(
          appBar: state.isSearchMode
              ? buildSearchAppBar()
              : buildNormalAppBar(context),
          body: buildBody(context),
        );
      },
    );
  }

  PreferredSizeWidget buildNormalAppBar(BuildContext context);
  Widget buildNormalContent(BuildContext context);

  Widget buildGridCard(
    BuildContext context,
    int index,
    Manga manga,
    double cardWidth,
  );

  Widget buildListTile(BuildContext context, int index, Manga manga,
      {bool buildCover = true});
}
