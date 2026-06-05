import 'package:flutter/material.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/ui/layout/list/list_layout.dart';

class MangaListView extends ListLayout {
  final List<Manga> mangas;
  final Widget Function(BuildContext context, int index, Manga manga) tileBuilder;

  const MangaListView({
    super.key,
    required this.mangas,
    required this.tileBuilder,
    super.scrollController,
  }) : super(itemExtent: UiConfig.mangaListItemExtent);

  @override
  int get itemCount => mangas.length;

  @override
  Widget buildItem(BuildContext context, int index) {
    return tileBuilder(context, index, mangas[index]);
  }
}
