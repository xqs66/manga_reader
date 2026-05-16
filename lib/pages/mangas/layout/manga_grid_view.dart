import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/pages/mangas/mangas_page_controller.dart';
import 'package:manga_reader/pages/mangas/layout/grid_layout.dart';
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

    if (!controller.state.isSelectMode) {
      return MangaGridCard(
        manga: manga,
        width: cardWidth,
        onTap: () => controller.handleMangaCardTap(manga),
        onLongPress: () => controller.handleLongPressManga(manga),
      );
    }

    return GetBuilder<MangasPageController>(
      id: '${controller.mangaIdPrefix}::${manga.id}',
      builder: (_) {
        final selected = controller.state.selectedMangaIds.contains(manga.id);
        return _buildSelectableCard(manga, cardWidth, selected);
      },
    );
  }

  Widget _buildSelectableCard(Manga manga, double cardWidth, bool selected) {
    return Stack(
      children: [
        MangaGridCard(
          manga: manga,
          width: cardWidth,
          onTap: () => controller.handleSelectManga(manga),
          onLongPress: null,
        ),
        if (selected)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: .circular(12),
                  border: Border.all(color: UiConfig.primaryColor, width: 2.5),
                ),
              ),
            ),
          ),
        if (selected)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: UiConfig.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            ),
          ),
      ],
    );
  }
}
