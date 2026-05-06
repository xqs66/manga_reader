import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/shared/extensions/string_ext.dart';
import 'package:manga_reader/widgets/manga_list_tile_card.dart';

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
      appBar: AppBar(
        title: GetBuilder<ArchiveMangasController>(
          id: _controller.titleId,
          builder: (_) => Text(_state.hasSelection ? '已选 ${_state.selectedMangas.length} 部' : '归档漫画'),
        ),
        centerTitle: true,
        actions: [
          GetBuilder<ArchiveMangasController>(
            id: _controller.titleId,
            builder: (_) => _state.hasSelection
                ? TextButton(onPressed: _controller.clearSelection, child: const Text('清空'))
                : const SizedBox.shrink(),
          ),
        ],
      ),
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
          return BottomAppBar(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: Text('已选 ${_state.selectedMangas.length} 部', style: const TextStyle(fontSize: 14))),
                  FilledButton.icon(
                    onPressed: _showConfirmDialog,
                    icon: const Icon(Icons.archive_rounded, size: 20),
                    label: const Text('开始归档'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectArea() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: _buildPathSelector(
        icon: Icons.folder_open_rounded,
        path: _state.selectedDir?.path,
        hint: '选择包含漫画的目录',
        isSelected: _state.isDirSelected,
        onTap: () => _controller.selectDir(),
      ),
    );
  }

  Widget _buildPathSelector({
    required IconData icon,
    String? path,
    required String hint,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: .circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: .circular(10),
            border: .all(color: isSelected ? UiConfig.primaryColor.withValues(alpha: 0.4) : Colors.grey.shade300),
            color: isSelected ? UiConfig.primaryColor.withValues(alpha: 0.04) : Colors.grey.shade50,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isSelected ? UiConfig.primaryColor : Colors.grey.shade500),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isSelected ? path!.displayPath() : hint,
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: TextStyle(fontSize: 13, color: isSelected ? Colors.black87 : Colors.grey.shade500),
                ),
              ),
              Icon(isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded, size: 20,
                  color: isSelected ? UiConfig.primaryColor : Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea() {
    if (!_state.isDirSelected) {
      return Center(
        child: Column(
          mainAxisSize: .min,
          children: [
            Icon(Icons.folder_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('请先选择源目录', style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    if (_state.isLoadingMangas) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_state.isWorking) return _buildProgressView();
    if (_state.mangas.isEmpty) {
      return Center(child: Text('该目录下未发现可归档漫画', style: TextStyle(fontSize: 15, color: Colors.grey.shade500)));
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
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: isSelected
                      ? BoxDecoration(
                          borderRadius: .circular(12),
                          border: Border.all(color: UiConfig.primaryColor.withValues(alpha: 0.5), width: 2),
                          boxShadow: [BoxShadow(color: UiConfig.primaryColor.withValues(alpha: 0.25), blurRadius: 8)],
                        )
                      : null,
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

  Widget _buildProgressView() {
    final progress = _state.total > 0 ? _state.progress / _state.total : 0.0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: .min,
          children: [
            ClipRRect(borderRadius: .circular(4), child: LinearProgressIndicator(value: progress, minHeight: 8)),
            const SizedBox(height: 16),
            Text('${_state.progress} / ${_state.total}', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
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
