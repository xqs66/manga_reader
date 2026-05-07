import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/pages/books/mangas_page_controller.dart';
import 'package:manga_reader/widgets/grid/grid_layout.dart';
import 'package:manga_reader/widgets/grid/manga_grid_card.dart';

class MangaGridView extends GridLayout {
  final List<Manga> mangas;
  final MangasPageController controller;

  const MangaGridView({
    super.key,
    required this.mangas,
    required this.controller,
  });

  @override
  int get itemCount => mangas.length;

  @override
  Widget buildItem(BuildContext context, int index, double cardWidth) {
    final manga = mangas[index];
    final isSelectMode = controller.state.isSelectMode;

    return GetBuilder<MangasPageController>(
      id: '${controller.mangaIdPrefix}::${manga.id}',
      builder: (_) {
        final selected = isSelectMode &&
            controller.state.selectedMangaIds.contains(manga.id);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: selected
              ? BoxDecoration(
                  borderRadius: .circular(12),
                  border: Border.all(
                    color: Colors.indigo.withValues(alpha: 0.5), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withValues(alpha: 0.25),
                      blurRadius: 8, spreadRadius: 1),
                  ],
                )
              : null,
          child: MangaGridCard(
            manga: manga,
            width: cardWidth,
            onTap: isSelectMode
                ? () => controller.handleSelectManga(manga)
                : () => controller.handleMangaCardTap(manga),
            onLongPress: isSelectMode
                ? null
                : () => controller.handleLongPressManga(manga),
          ),
        );
      },
    );
  }
}
