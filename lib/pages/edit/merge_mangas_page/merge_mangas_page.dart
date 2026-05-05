import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/shared/extensions/string_ext.dart';
import 'package:manga_reader/shared/utils/file_util.dart';
import 'package:manga_reader/widgets/common_dialog.dart';
import 'package:manga_reader/widgets/manga_list_tile_card.dart';

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

  AppBar _buildAppBar() {
    return AppBar(
      title: GetBuilder<MergeMangasPageController>(
        id: _controller.titleId,
        builder: (context) {
          return Text(
            _state.hasSelectedManga
                ? '已选 ${_state.selectedMangas.length} 部'
                : '合并漫画为合集',
          );
        },
      ),
      centerTitle: true,
      actions: [
        GetBuilder<MergeMangasPageController>(
          id: _controller.cancelButtonId,
          builder: (context) {
            return _state.hasSelectedManga
                ? TextButton(
                    onPressed: _controller.cancelSelected,
                    child: const Text('清空'),
                  )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return GetBuilder<MergeMangasPageController>(
      id: _controller.bodyId,
      builder: (context) {
        return Column(
          children: [
            _buildSelectPathsArea(),
            const Divider(height: 1),
            Expanded(child: _buildContentArea()),
          ],
        );
      },
    );
  }

  Widget _buildSelectPathsArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: .min,
        children: [
          GetBuilder<MergeMangasPageController>(
            id: _controller.selectDirId,
            builder: (context) {
              return _buildPathSelector(
                icon: Icons.folder_open_rounded,
                label: '源目录',
                path: _state.selectedDir?.path,
                hint: '选择包含漫画的目录',
                isSelected: _state.isDirSelected,
                onTap: () => _controller.selectDir(),
              );
            },
          ),
          const SizedBox(height: 8),
          GetBuilder<MergeMangasPageController>(
            id: _controller.selectOutputDirId,
            builder: (context) {
              return _buildPathSelector(
                icon: Icons.folder_rounded,
                label: '输出目录',
                path: _state.outputDir?.path,
                hint: '选择合集保存的目录',
                isSelected: _state.isOutputDirSelected,
                onTap: () => _controller.selectOutputDir(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPathSelector({
    required IconData icon,
    required String label,
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
            border: Border.all(
              color: isSelected
                  ? UiConfig.primaryColor.withValues(alpha: 0.4)
                  : Colors.grey.shade300,
            ),
            color: isSelected
                ? UiConfig.primaryColor.withValues(alpha: 0.04)
                : Colors.grey.shade50,
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: isSelected
                      ? UiConfig.primaryColor
                      : Colors.grey.shade500),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isSelected ? path!.displayPath() : hint,
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isSelected ? Colors.black87 : Colors.grey.shade500,
                  ),
                ),
              ),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
                size: 20,
                color: isSelected
                    ? UiConfig.primaryColor
                    : Colors.grey.shade400,
              ),
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
            Text(
              '请先选择源目录',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return _buildMangaListArea(_state.selectedDir!);
  }

  Widget _buildMangaListArea(Directory dir) {
    return FutureBuilder(
      future: localMangaService.getMangasInDir(dir),
      builder: (context, snapshot) {
        if (snapshot.connectionState == .waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.connectionState == .done) {
          _state.mangas = snapshot.data ?? [];
          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: .min,
                children: [
                  Icon(Icons.auto_stories_rounded,
                      size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    '该目录下未发现漫画',
                    style:
                        TextStyle(fontSize: 15, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }
          return CupertinoScrollbar(
            controller: _state.scrollController,
            child: NotificationListener(
              onNotification: (ScrollNotification notification) =>
                  _controller.handleScrollEvent(notification),
              child: _buildMangaList(),
            ),
          );
        }
        return Center(
          child: Text('加载失败', style: TextStyle(color: Colors.red.shade400)),
        );
      },
    );
  }

  Widget _buildMangaList() {
    return GetBuilder<MergeMangasPageController>(
      id: _controller.mangasId,
      builder: (_) {
        return ListView.builder(
          controller: _state.scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _state.mangas.length,
          itemBuilder: (context, index) =>
              _buildMangaListTile(index, _state.mangas[index]),
        );
      },
    );
  }

  Widget _buildMangaListTile(int index, Manga manga) {
    return GetBuilder<MergeMangasPageController>(
      id: '${_controller.mangaListTileIdPrefix}::$index',
      builder: (_) {
        final isSelected = _state.selectedMangas.contains(manga);
        final order = _state.selectedMangas.indexOf(manga) + 1;

        return AnimatedContainer(
          key: ValueKey('manga_tile_${manga.id}'),
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: isSelected
              ? BoxDecoration(
                  borderRadius: .circular(12),
                  color: UiConfig.primaryColor.withValues(alpha: 0.06),
                  border: Border.all(
                    color: UiConfig.primaryColor.withValues(alpha: 0.3),
                  ),
                )
              : null,
          child: Row(
            children: [
              _buildSelectionIndicator(isSelected, order),
              const SizedBox(width: 8),
              Expanded(
                child: MangaListTileCard(
                  key: ValueKey(manga.id),
                  manga: manga,
                  buildCover: !_state.isScrolling,
                  onTap: () =>
                      _controller.toggleMangaSelection(index, manga),
                  onLongPressed: () =>
                      _controller.handleLongPressManga(
                    context,
                    _buildLongPressActions(manga),
                  ),
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

  List<SheetAction> _buildLongPressActions(Manga manga) {
    return [
      SheetAction(
        label: '复制漫画名',
        onPressed: () => FileUtil.copyMangaName(manga.title),
      ),
    ];
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
                  child: Text(
                    '已选 ${_state.selectedMangas.length} 部漫画',
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

  Widget _buildMergeDialog() {
    return GetBuilder<MergeMangasPageController>(
      id: _controller.mergeStartDialogId,
      builder: (context) {
        return CommonDialog(
          title: '新建合集',
          content: Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              TextField(
                autofocus: true,
                controller: _state.targetDirNameController,
                decoration: const InputDecoration(
                  hintText: '请输入合集名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
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
