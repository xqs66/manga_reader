import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/mixin/scroll_handler.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/widgets/dialogs/common_dialog.dart';
import 'package:manga_reader/widgets/empty_state.dart';
import 'package:manga_reader/widgets/manga_list_tile_card.dart';
import 'package:manga_reader/widgets/path_selector_tile.dart';
import 'package:manga_reader/widgets/selected_item_decoration.dart';

import 'merge_mangas_page_controller.dart';

class MergeMangasPage extends StatefulWidget {
  const MergeMangasPage({super.key});

  @override
  State<StatefulWidget> createState() => _MergeMangasPageState();
}

class _MergeMangasPageState extends State<MergeMangasPage> {
  final _controller = Get.put(MergeMangasPageController());
  final _state = Get.find<MergeMangasPageController>().state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: GetBuilder<MergeMangasPageController>(
        id: _controller.titleId,
        builder: (_) => Text(
          _state.hasSelectedManga ? '已选 ${_state.selectedMangas.length} 部' : '合并漫画为合集',
        ),
      ),
      centerTitle: true,
      actions: [
        GetBuilder<MergeMangasPageController>(
          id: _controller.cancelButtonId,
          builder: (_) => _state.hasSelectedManga
              ? TextButton(onPressed: _controller.cancelSelected, child: const Text('清空'))
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return GetBuilder<MergeMangasPageController>(
      id: _controller.bodyId,
      builder: (_) => Column(
        children: [
          _buildSelectPathsArea(),
          const Divider(height: 1),
          Expanded(child: _buildContentArea()),
        ],
      ),
    );
  }

  Widget _buildSelectPathsArea() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: .min,
        children: [
          GetBuilder<MergeMangasPageController>(
            id: _controller.selectDirId,
            builder: (_) => PathSelectorTile(
              icon: Icons.folder_open_rounded,
              label: '源目录',
              path: _state.selectedDir?.path,
              hint: '选择包含漫画的目录',
              isSelected: _state.isDirSelected,
              onTap: () => _controller.selectDir(),
            ),
          ),
          const SizedBox(height: 8),
          GetBuilder<MergeMangasPageController>(
            id: _controller.selectOutputDirId,
            builder: (_) => PathSelectorTile(
              icon: Icons.folder_rounded,
              label: '输出目录',
              path: _state.outputDir?.path,
              hint: '选择合集保存的目录',
              isSelected: _state.isOutputDirSelected,
              onTap: () => _controller.selectOutputDir(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    if (!_state.isDirSelected) {
      return const EmptyState(icon: Icons.folder_rounded, title: '请先选择源目录');
    }
    if (_state.isLoadingMangas) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_state.mangas.isEmpty) {
      return const EmptyState(icon: Icons.auto_stories_rounded, title: '该目录下未发现漫画');
    }
    return ScrollWrapper(
      useDelayedStart: true,
      onStateChanged: () => _controller.update([_controller.mangasId]),
      builder: (context, handler) => GetBuilder<MergeMangasPageController>(
        id: _controller.mangasId,
        builder: (_) => ListView.builder(
          controller: _controller.listScrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _state.mangas.length,
          itemBuilder: (context, index) =>
              _buildMangaListTile(index, _state.mangas[index], isScrolling: handler.isScrolling),
        ),
      ),
    );
  }

  Widget _buildMangaListTile(int index, Manga manga, {required bool isScrolling}) {
    return GetBuilder<MergeMangasPageController>(
      id: '${_controller.mangaListTileIdPrefix}::$index',
      builder: (_) {
        final isSelected = _state.selectedMangas.contains(manga);
        final order = _state.selectedMangas.indexOf(manga) + 1;

        return SelectedItemDecoration(
          isSelected: isSelected,
          child: Row(
            children: [
              _buildSelectionIndicator(isSelected, order),
              const SizedBox(width: 8),
              Expanded(
                child: MangaListTileCard(
                  key: ValueKey(manga.id),
                  manga: manga,
                  buildCover: !isScrolling,
                  onTap: () => _controller.toggleMangaSelection(index, manga),
                  onLongPressed: () => _controller.handleLongPressManga(context, manga),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectionIndicator(bool isSelected, int order) {
    return SizedBox(
      width: 36,
      child: Center(
        child: isSelected
            ? Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(color: UiConfig.primaryColor, shape: BoxShape.circle),
                child: Center(
                  child: Text('$order',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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

  Widget _buildBottomBar() {
    return GetBuilder<MergeMangasPageController>(
      id: _controller.titleId,
      builder: (_) {
        if (!_state.hasSelectedManga) return const SizedBox.shrink();
        return BottomAppBar(
          height: UiConfig.bottomHeightInMergePasge,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text('已选 ${_state.selectedMangas.length} 部漫画',
                      style: const TextStyle(fontSize: 14)),
                ),
                FilledButton.icon(
                  onPressed: () => Get.dialog(_buildMergeDialog(), barrierDismissible: false),
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

  Widget _buildMergeDialog() {
    return GetBuilder<MergeMangasPageController>(
      id: _controller.mergeStartDialogId,
      builder: (_) {
        return CommonDialog(
          title: '新建合集',
          content: Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              TextField(
                autofocus: true,
                controller: _state.targetDirNameController,
                decoration: const InputDecoration(hintText: '请输入合集名称', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _state.outputAsZip,
                onChanged: _controller.handleToggleOutputAsZip,
                title: const Text('输出为 ZIP 压缩包'),
                contentPadding: .zero,
                horizontalTitleGap: 0,
                controlAffinity: .leading,
                dense: true,
              ),
              CheckboxListTile(
                value: _state.deleteSourceMangas,
                onChanged: _controller.handleToggleDeleteSource,
                title: const Text('合并后删除原漫画'),
                subtitle: const Text('此操作不可恢复'),
                contentPadding: .zero,
                horizontalTitleGap: 0,
                controlAffinity: .leading,
                dense: true,
              ),
            ],
          ),
          onConfirm: _controller.handleTapStartMerge,
        );
      },
    );
  }
}
