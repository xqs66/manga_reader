import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/core/extensions/string_ext.dart';
import 'package:manga_reader/ui/widgets/empty_state.dart';
import 'package:manga_reader/ui/layout/list/manga_list_tile_card.dart';
import 'package:manga_reader/ui/widgets/path_selector_tile.dart';
import 'package:manga_reader/ui/widgets/progress_view.dart';
import 'package:manga_reader/ui/layout/list/selected_item_decoration.dart';
import 'package:manga_reader/ui/widgets/selection/selection_bottom_bar.dart';

import 'archive_mangas_controller.dart';

class ArchiveMangasPage extends StatefulWidget {
  const ArchiveMangasPage({super.key});

  @override
  State<ArchiveMangasPage> createState() => _ArchiveMangasPageState();
}

class _ArchiveMangasPageState extends State<ArchiveMangasPage> {
  final _controller = Get.put(ArchiveMangasController());
  final _state = Get.find<ArchiveMangasController>().state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: GetBuilder<ArchiveMangasController>(
        id: _controller.bodyId,
        builder: (_) => Column(
          children: [
            _buildSelectArea(),
            const Divider(height: 1),
            Expanded(child: _buildContentArea()),
          ],
        ),
      ),
      bottomNavigationBar: GetBuilder<ArchiveMangasController>(
        id: _controller.titleId,
        builder: (_) {
          if (!_state.hasSelection || _state.isWorking) return const SizedBox.shrink();
          return SelectionBottomBar(
            selectedCount: _state.selectedMangas.length,
            itemLabel: '部',
            actions: [
              SelectionAction(
                icon: Icons.archive_rounded,
                label: '开始归档',
                onPressed: _showConfirmDialog,
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final hasSelection = _state.hasSelection;
    return AppBar(
      title: GetBuilder<ArchiveMangasController>(
        id: _controller.titleId,
        builder: (_) => Text(hasSelection ? '已选 ${_state.selectedMangas.length} 部' : '归档漫画'),
      ),
      centerTitle: true,
      leading: hasSelection
          ? IconButton(onPressed: _controller.clearSelection, icon: const Icon(Icons.close_rounded))
          : null,
    );
  }

  Widget _buildSelectArea() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: PathSelectorTile(
        icon: Icons.folder_open_rounded,
        path: _state.selectedDir?.path,
        hint: '选择包含漫画的目录',
        isSelected: _state.isDirSelected,
        onTap: () => _controller.selectDir(),
      ),
    );
  }

  Widget _buildContentArea() {
    if (!_state.isDirSelected) {
      return const EmptyState(
        icon: Icons.folder_rounded,
        title: '请先选择源目录',
      );
    }
    if (_state.isLoadingMangas) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_state.isWorking) {
      return Center(child: ProgressView(current: _state.progress, total: _state.total));
    }
    if (_state.mangas.isEmpty) {
      return const EmptyState(
        icon: Icons.auto_stories_rounded,
        title: '该目录下未发现可归档漫画',
      );
    }
    return ListView.builder(
      controller: _state.scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _state.mangas.length,
      itemBuilder: (_, index) {
        final manga = _state.mangas[index];
        return GetBuilder<ArchiveMangasController>(
          id: '${_controller.mangaItemIdPrefix}::${manga.id}',
          builder: (_) {
            final isSelected = _state.selectedMangas.contains(manga);
            return SelectedItemDecoration(
              isSelected: isSelected,
              child: MangaListTileCard(
                key: ValueKey(manga.id),
                manga: manga,
                onTap: () => _controller.toggleSelection(manga),
              ),
            );
          },
        );
      },
    );
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: .circular(16)),
        title: const Text('确认归档'),
        content: Column(
          crossAxisAlignment: .start,
          mainAxisSize: .min,
          children: [
            Text('将 ${_state.selectedMangas.length} 部漫画打包为 ZIP，源文件将自动删除。'),
            const SizedBox(height: 8),
            Text(_state.selectedDir!.path.displayPath(), style: const TextStyle(fontSize: 13, color: Color(0xFF616161))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () {
            Navigator.pop(ctx);
            _controller.startArchive();
          }, child: const Text('确认归档')),
        ],
      ),
    );
  }
}
