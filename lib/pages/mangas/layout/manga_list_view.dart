import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:manga_reader/core/utils/file_util.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/mixin/scroll_handler.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/pages/mangas/layout/list_layout.dart';
import 'package:manga_reader/pages/mangas/mangas_page_controller.dart';
import 'package:manga_reader/widgets/manga_list_tile_card.dart';
import 'package:manga_reader/widgets/selected_item_decoration.dart';

class MangaListView extends ListLayout {
  final List<Manga> mangas;
  final MangasPageController controller;
  final ScrollState scrollState;
  final void Function(Manga)? onDeleteManga;

  MangaListView({
    super.key,
    required this.mangas,
    required this.controller,
    required super.scrollController,
    required this.scrollState,
    this.onDeleteManga,
  }) : super(itemExtent: UiConfig.mangaListItemExtent);

  @override
  int get itemCount => mangas.length;

  @override
  Widget buildItem(BuildContext context, int index) {
    final manga = mangas[index];
    final state = controller.state;

    return GetBuilder<MangasPageController>(
      id: '${controller.mangaIdPrefix}::${manga.id}',
      builder: (_) {
        final isSelected =
            state.selectedMangaIds.contains(manga.id) && state.isSelectMode;

        return SelectedItemDecoration(
          isSelected: isSelected,
          child: Stack(
            children: [
              MangaListTileCard(
                key: ValueKey(manga.id),
                buildCover: !(scrollState.isScrolling && scrollState.currentVelocity.abs() > 500),
                onTap: () => state.isSelectMode
                    ? controller.handleSelectManga(manga)
                    : controller.handleMangaCardTap(manga),
                onLongPressed: () => state.isSelectMode
                    ? null
                    : controller.handleLongPressManga(manga),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) => FileUtil.copyMangaName(manga.title),
                      icon: Icons.copy_rounded,
                      label: '复制',
                    ),
                    SlidableAction(
                      onPressed: (_) => onDeleteManga?.call(manga),
                      foregroundColor: Colors.red,
                      icon: Icons.delete_rounded,
                      label: '删除',
                    ),
                  ],
                ),
                manga: manga,
              ),
            ],
          ),
        );
      },
    );
  }
}
