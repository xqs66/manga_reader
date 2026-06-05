import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/pages/mangas/layout/manga_list_layout.dart';
import 'package:manga_reader/settings/read_setting.dart';
import 'package:manga_reader/widgets/dialogs/common_dialog.dart';
import 'package:manga_reader/widgets/empty_state.dart';
import 'package:manga_reader/widgets/grid/manga_grid_card.dart';
import 'package:manga_reader/widgets/manga_list_tile_card.dart';
import 'package:manga_reader/widgets/path_selector_tile.dart';
import 'package:manga_reader/widgets/styled_menu.dart';

import 'merge_mangas_page_controller.dart';
import 'merge_mangas_page_state.dart';

class MergeMangasPage extends StatelessWidget
    with MangaListLayout<MergeMangasPageController, MergeMangasPageState> {
  MergeMangasPage({super.key});

  @override
  final controller = Get.put<MergeMangasPageController>(
    MergeMangasPageController(),
  );

  @override
  MergeMangasPageState get state => controller.state;

  @override
  Widget build(BuildContext context) => buildLayout(context);

  // ── Layout overrides ──

  @override
  Widget buildLayout(BuildContext context) {
    return GetBuilder<MergeMangasPageController>(
      id: controller.appBarId,
      builder: (_) {
        return Scaffold(
          appBar: state.isSearchMode
              ? buildSearchAppBar()
              : buildNormalAppBar(context),
          body: buildBody(context),
          bottomNavigationBar: _buildBottomBar(),
        );
      },
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return GetBuilder<MergeMangasPageController>(
      id: controller.bodyId,
      builder: (_) {
        if (state.isSearchMode) return buildSearchResults();
        return buildNormalContent(context);
      },
    );
  }

  // ── Abstract method implementations ──

  @override
  PreferredSizeWidget buildNormalAppBar(BuildContext context) {
    return AppBar(
      title: GetBuilder<MergeMangasPageController>(
        id: controller.titleId,
        builder: (_) => Text(
          state.hasSelectedManga
              ? '已选 ${state.selectedMangas.length} 部'
              : '合并漫画为合集',
        ),
      ),
      centerTitle: true,
      actions: [
        GetBuilder<MergeMangasPageController>(
          id: controller.cancelButtonId,
          builder: (_) => state.hasSelectedManga
              ? IconButton(
                  onPressed: controller.cancelSelected,
                  icon: const Icon(Icons.clear),
                )
              : const SizedBox.shrink(),
        ),
        IconButton(
          onPressed: controller.toggleSearchMode,
          icon: const Icon(Icons.search_rounded),
        ),
        IconButton(
          onPressed: controller.toggleLayoutMode,
          icon: Icon(
            readSetting.bookshelfLayout.value == BookshelfLayout.grid
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded,
          ),
          tooltip: readSetting.bookshelfLayout.value == BookshelfLayout.grid
              ? '切换为列表'
              : '切换为网格',
        ),
      ],
    );
  }

  @override
  Widget buildNormalContent(BuildContext context) {
    return Column(
      children: [
        _buildSelectPathsArea(),
        const Divider(height: 1),
        Expanded(child: _buildContentArea()),
      ],
    );
  }

  @override
  Widget buildGridCard(
    BuildContext context,
    int index,
    Manga manga,
    double cardWidth,
  ) {
    return GetBuilder<MergeMangasPageController>(
      id: '${controller.mangaListTileIdPrefix}::${displayMangas.indexOf(manga)}',
      builder: (_) {
        final isSelected = state.selectedMangas.contains(manga);
        final order = state.selectedMangas.indexOf(manga) + 1;
        return Stack(
          children: [
            MangaGridCard(
              manga: manga,
              width: cardWidth,
              onTap: () => controller.toggleMangaSelection(index, manga),
              onLongPress: () =>
                  controller.handleLongPressManga(context, manga),
            ),
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: UiConfig.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$order',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget buildListTile(BuildContext context, int index, Manga manga) {
    return GetBuilder<MergeMangasPageController>(
      id: '${controller.mangaListTileIdPrefix}::$index',
      builder: (_) {
        final isSelected = state.selectedMangas.contains(manga);
        final order = state.selectedMangas.indexOf(manga) + 1;
        return Row(
          children: [
            _buildSelectionIndicator(isSelected, order),
            const SizedBox(width: 8),
            Expanded(
              child: MangaListTileCard(
                key: ValueKey(manga.id),
                manga: manga,
                onTap: () => controller.toggleMangaSelection(index, manga),
                onLongPressed: () =>
                    controller.handleLongPressManga(context, manga),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Private: path selectors ──

  Widget _buildSelectPathsArea() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: .min,
        children: [
          GetBuilder<MergeMangasPageController>(
            id: controller.selectDirId,
            builder: (_) => PathSelectorTile(
              icon: Icons.folder_open_rounded,
              label: '源目录',
              path: state.selectedDir?.path,
              hint: '选择包含漫画的目录',
              isSelected: state.isDirSelected,
              onTap: () => controller.selectDir(),
            ),
          ),
          const SizedBox(height: 8),
          GetBuilder<MergeMangasPageController>(
            id: controller.selectOutputDirId,
            builder: (_) => PathSelectorTile(
              icon: Icons.folder_rounded,
              label: '输出目录',
              path: state.outputDir?.path,
              hint: '选择合集保存的目录',
              isSelected: state.isOutputDirSelected,
              onTap: () => controller.selectOutputDir(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Private: content area ──

  Widget _buildContentArea() {
    if (!state.isDirSelected) {
      return const EmptyState(icon: Icons.folder_rounded, title: '请先选择源目录');
    }
    if (state.isLoadingMangas) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.mangas.isEmpty) {
      return const EmptyState(
        icon: Icons.auto_stories_rounded,
        title: '该目录下未发现漫画',
      );
    }
    if (readSetting.bookshelfLayout.value == BookshelfLayout.grid) {
      return buildMangaGridView();
    }
    return buildMangaListView();
  }

  // ── Private: selection indicator for list mode ──

  Widget _buildSelectionIndicator(bool isSelected, int order) {
    return SizedBox(
      width: 36,
      child: Center(
        child: isSelected
            ? Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: UiConfig.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$order',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            : Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade400, width: 2),
                ),
              ),
      ),
    );
  }

  // ── Private: bottom bar ──

  Widget _buildBottomBar() {
    return GetBuilder<MergeMangasPageController>(
      id: controller.titleId,
      builder: (_) {
        if (!state.hasSelectedManga) return const SizedBox.shrink();
        return BottomAppBar(
          height: UiConfig.bottomHeightInMergePasge,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '已选 ${state.selectedMangas.length} 部漫画',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => Get.dialog(
                    _buildMergeDialog(),
                    barrierDismissible: false,
                  ),
                  icon: const Icon(Icons.merge_rounded, size: 20),
                  label: const Text('开始合并'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Private: merge dialog ──

  Widget _buildMergeDialog() {
    return GetBuilder<MergeMangasPageController>(
      id: controller.mergeStartDialogId,
      builder: (_) {
        return CommonDialog(
          title: '新建合集',
          content: Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              TextField(
                autofocus: true,
                controller: state.targetDirNameController,
                decoration: const InputDecoration(
                  hintText: '请输入合集名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: state.outputAsZip,
                onChanged: controller.handleToggleOutputAsZip,
                title: const Text('输出为 ZIP 压缩包'),
                contentPadding: .zero,
                horizontalTitleGap: 0,
                controlAffinity: .leading,
                dense: true,
              ),
              CheckboxListTile(
                value: state.deleteSourceMangas,
                onChanged: controller.handleToggleDeleteSource,
                title: const Text('合并后删除原漫画'),
                subtitle: const Text('此操作不可恢复'),
                contentPadding: .zero,
                horizontalTitleGap: 0,
                controlAffinity: .leading,
                dense: true,
              ),
            ],
          ),
          onConfirm: controller.handleTapStartMerge,
        );
      },
    );
  }
}
