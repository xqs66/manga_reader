import 'package:flutter/material.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/pages/mangas/layout/grid_layout.dart';

class MangaGridView extends GridLayout {
  final List<Manga> mangas;
  final Widget Function(
    BuildContext context,
    int index,
    Manga manga,
    double cardWidth,
  ) cardBuilder;

  const MangaGridView({
    super.key,
    required this.mangas,
    required this.cardBuilder,
  });

  @override
  int get itemCount => mangas.length;

  @override
  Widget buildItem(BuildContext context, int index, double cardWidth) {
    return cardBuilder(context, index, mangas[index], cardWidth);
  }
}
