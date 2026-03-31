import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:manga_reader/shared/extensions/string_ext.dart';
import 'package:manga_reader/shared/utils/file_util.dart';
import 'package:manga_reader/wigets/group_header.dart';
import 'package:manga_reader/wigets/manga_list_tile_card.dart';
import 'package:get/get.dart';
import 'package:manga_reader/pages/books/books_page_controller.dart';

import '../../config/ui_config.dart';
import '../../models/manga.dart';
import '../../settings/path_setting.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  final _controller = Get.put(BooksPageController(), permanent: true);
  final _state = Get.find<BooksPageController>().state;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BooksPageController>(
      id: _controller.appBarId,
      builder: (_) {
        return Scaffold(
          appBar: _state.isSelectMode
              ? _buildSelectModeAppbar()
              : _buildNormalAppbar(),
          body: _buildBody(),
          bottomNavigationBar: _buildBottomBar(),
        );
      },
    );
  }

  AppBar _buildNormalAppbar() {
    return AppBar(
      title: Text('Books'),
      centerTitle: true,
      actions: [
        GetBuilder<BooksPageController>(
          id: _controller.popUpMenuId,
          builder: (_) {
            return PopupMenuButton(
              itemBuilder: (context) => _buildPopUpMenuItems(),
            );
          },
        ),
      ],
    );
  }

  AppBar _buildSelectModeAppbar() {
    return AppBar(
      leading: IconButton(
        onPressed: _controller.toggleSelectMode,
        icon: Icon(Icons.close),
      ),
      title: Text(_state.selectedMangaIds.length.toString()),
      actions: [
        IconButton(
          onPressed: _controller.handleSelectAll,
          icon: Icon(Icons.select_all),
        ),
      ],
    );
  }

  List<PopupMenuItem> _buildPopUpMenuItems() {
    return [
      PopupMenuItem(
        onTap: _controller.back2Root,
        height: UiConfig.popUpMenuHeight,
        child: Row(
          children: [
            Icon(Icons.arrow_back),
            SizedBox(width: 10),
            Text('返回根目录'),
          ],
        ),
      ),
      PopupMenuItem(
        onTap: _controller.refreshMangas,
        height: UiConfig.popUpMenuHeight,
        child: Row(
          children: [Icon(Icons.refresh), SizedBox(width: 10), Text('刷新')],
        ),
      ),
      PopupMenuItem(
        onTap: () {
          final textController = TextEditingController();
          Get.dialog(
            AlertDialog(
              title: Text('新增分组'),
              content: TextField(
                controller: textController,
                decoration: InputDecoration(hintText: '请输入分组名称'),
              ),
              actions: [
                TextButton(onPressed: () => Get.back(), child: Text('取消')),
                TextButton(
                  onPressed: () {
                    _controller.handleAddGroup(textController.text.trim());
                    Get.back();
                  },
                  child: Text('确定'),
                ),
              ],
            ),
          );
        },
        height: UiConfig.popUpMenuHeight,
        child: Row(
          children: [Icon(Icons.add), SizedBox(width: 10), Text('新增分组')],
        ),
      ),
    ];
  }

  Widget _buildBody() {
    return GetBuilder<BooksPageController>(
      id: _controller.bodyId,
      builder: (_) {
        if (_state.isAtRoot) {
          return _buildLocalPaths();
        } else {
          return _buildGroupedBooksList();
        }
      },
    );
  }

  Widget _buildLocalPaths() {
    return ListView.builder(
      itemCount: pathSetting.paths.length,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            minTileHeight: 30,
            title: Text(
              pathSetting.paths[index].displayPath(),
              overflow: .ellipsis,
              maxLines: 2,
            ),
            onTap: () {
              _controller.enterMangaDir(pathSetting.paths[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildGroupedBooksList() {
    /// TODO: 可配置项，不过设置稍微多点会卡顿
    return CupertinoScrollbar(
      controller: _state.scrollController,
      child: CustomScrollView(
        slivers: _buildSlivers(),
        controller: _state.scrollController,
        cacheExtent: Get.height * 0.5,
      ),
    );
  }

  List<Widget> _buildSlivers() {
    List<Widget> slivers = [];

    for (int i = 0; i < _state.groups.length; i++) {
      slivers.add(_buildGroupSliver(i));
      slivers.add(
        _buildElementSliver(
          i,
          _state.books
              .where((manga) => manga.groupName == _state.groups[i])
              .toList(),
        ),
      );
    }

    return slivers;
  }

  Widget _buildElementSliver(int groupIndex, List<Manga> mangas) {
    return GetBuilder<BooksPageController>(
      id: '${_controller.mangasInGroupIdPrefix}::${_state.groups[groupIndex]}',
      builder: (_) {
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) =>
                _buildElement(context, groupIndex, mangas[index]),
            childCount: mangas.length,
            addAutomaticKeepAlives: true,
          ),
        );
      },
    );
  }

  Widget _buildGroupSliver(int index) {
    return SliverToBoxAdapter(child: _buildGroup(index));
  }

  Widget _buildGroup(int index) {
    final String groupName = _state.groups[index];
    return GetBuilder<BooksPageController>(
      id: '${_controller.groupidPrefix}::$groupName',
      builder: (_) {
        final isDisplay = _state.displayGroups.contains(groupName);
        return GestureDetector(
          onTap: () {
            _controller.toggleOpen(index);
          },
          child: GroupHeader(
            child: Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Text(groupName),
                isDisplay
                    ? Icon(Icons.keyboard_arrow_up)
                    : Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildElement(BuildContext context, int groupIndex, Manga manga) {
    return GetBuilder<BooksPageController>(
      id: '${_controller.mangaIdPrefix}::${manga.id}',
      builder: (_) {
        final isDisplay = _state.displayGroups.contains(
          _state.groups[groupIndex],
        );
        if (!isDisplay) return const SizedBox();

        final isSelected =
            _state.selectedMangaIds.contains(manga.id) && _state.isSelectMode;

        return Stack(
          children: [
            MangaListTileCard(
              onTap: () => _state.isSelectMode
                  ? _controller.handleSelectManga(manga)
                  : _controller.handleMangaCardTap(manga),
              onLongPressed: () => _state.isSelectMode
                  ? null
                  : _controller.handleLongPressManga(manga),
              manga: manga,
            ),
            isSelected
                ? Positioned.fill(
                    child: GestureDetector(
                      onTap: () => _state.isSelectMode
                          ? _controller.handleSelectManga(manga)
                          : null,
                      child: Card(
                        color: const Color(
                          0xFF84C4FF,
                        ).withAlpha((0.35 * 255).toInt()),
                      ),
                    ),
                  )
                : const SizedBox(),
          ],
        ).paddingSymmetric(horizontal: 10);
      },
    );
  }

  Widget _buildBottomBar() {
    return GetBuilder<BooksPageController>(
      id: _controller.bottomBarId,
      builder: (_) {
        if (!_state.isSelectMode) return const SizedBox();
        return BottomAppBar(
          height: 58,
          child: Row(
            mainAxisAlignment: .spaceEvenly,
            crossAxisAlignment: .center,
            children: [
              IconButton(
                onPressed: _controller.handleDeleteMangas,
                icon: Icon(Icons.drive_file_move),
              ),
              IconButton(
                onPressed: _controller.handleDeleteMangas,
                icon: Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
        );
      },
    );
  }

  /// TODO: 添加移动分组功能
}
