import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:manga_reader/routes/app_route_observer.dart';
import 'package:manga_reader/shared/extensions/string_ext.dart';
import 'package:manga_reader/shared/utils/file_util.dart';
import 'package:manga_reader/shared/utils/log_util.dart';
import 'package:manga_reader/wigets/group_header.dart';
import 'package:manga_reader/wigets/manga_list_tile_card.dart';
import 'package:get/get.dart';
import 'package:manga_reader/pages/books/books_page_controller.dart';
import 'package:manga_reader/wigets/select_dialog.dart';

import '../../config/ui_config.dart';
import '../../models/manga.dart';
import '../../settings/path_setting.dart';
import '../../wigets/common_dialog.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> with RouteAware {
  final _controller = Get.put(BooksPageController(), permanent: true);
  final _state = Get.find<BooksPageController>().state;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    _controller.handlePopNext();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BooksPageController>(
      id: _controller.appBarId,
      builder: (_) {
        return Scaffold(
          appBar: _state.isSelectMode
              ? _buildSelectModeAppbar()
              : _state.isSerchMode
              ? _buildSearchModeAppbar()
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

  AppBar _buildSearchModeAppbar() {
    return AppBar(
      leading: IconButton(
        onPressed: _controller.toggleSearchMode,
        icon: Icon(Icons.arrow_back),
      ),
      title: _buildSearchBox(),
      actions: [],
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      controller: _state.searchTextController,
      onChanged: (value) => _controller.handleSearch(value),
      decoration: InputDecoration(
        hintText: '搜索...',
        contentPadding: .symmetric(vertical: 12.0),
        suffixIcon: IconButton(
          onPressed: () {
            _state.searchTextController.clear();
            _controller.handleSearch('');
          },
          icon: Icon(Icons.clear),
        ),
        border: .none,
      ),
    );
  }

  List<PopupMenuItem> _buildPopUpMenuItems() {
    LogUtil.d(_state.isAtRoot.toString());
    return [
      PopupMenuItem(
        onTap: _controller.refreshMangas,
        height: UiConfig.popUpMenuHeight,
        child: Row(
          children: [Icon(Icons.refresh), SizedBox(width: 10), Text('刷新')],
        ),
      ),
      ..._state.isAtRoot
          ? []
          : [
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
                onTap: _controller.toggleSearchMode,
                height: UiConfig.popUpMenuHeight,
                child: Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 10),
                    Text('搜索'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () => Get.dialog(_buildNewGroupDialog()),
                height: UiConfig.popUpMenuHeight,
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 10),
                    Text('新增分组'),
                  ],
                ),
              ),
            ],
    ];
  }

  Widget _buildBody() {
    return GetBuilder<BooksPageController>(
      id: _controller.bodyId,
      builder: (_) {
        if (_state.isAtRoot) {
          return _buildLocalPaths();
        } else {
          return _state.isSerchMode
              ? _buildMangaListWithoutGroup()
              : _buildGroupedBooksList();
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

  Widget _buildMangaListWithoutGroup() {
    return ListView.builder(
      itemCount: _state.searchedMangas.length,
      itemBuilder: (context, index) =>
          _buildElement(context, true, _state.searchedMangas[index]),
    );
  }

  Widget _buildGroupedBooksList() {
    /// TODO: 可配置项，不过设置稍微多点会卡顿
    return CupertinoScrollbar(
      controller: _state.scrollController,
      child: NotificationListener(
        onNotification: (ScrollNotification notification) =>
            _controller.handleScrollEvent(notification),
        child: CustomScrollView(
          slivers: _buildSlivers(),
          controller: _state.scrollController,
          cacheExtent: Get.height * 0.5,
        ),
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
        final isDisplay = _state.displayGroups.contains(
          _state.groups[groupIndex],
        );
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) =>
                _buildElement(context, isDisplay, mangas[index]),
            childCount: mangas.length,
            addAutomaticKeepAlives: true,
            addRepaintBoundaries: true,
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
        return GroupHeader(
          onTap: () => _controller.toggleGroupExpand(index),
          child: Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Expanded(
                child: Text(groupName, maxLines: 1, overflow: .ellipsis),
              ),
              isDisplay
                  ? Icon(Icons.keyboard_arrow_up)
                  : Icon(Icons.keyboard_arrow_down),
            ],
          ),
        );
      },
    );
  }

  Widget _buildElement(BuildContext context, bool isDisplay, Manga manga) {
    return GetBuilder<BooksPageController>(
      id: '${_controller.mangaIdPrefix}::${manga.id}',
      builder: (_) {
        if (!isDisplay) return const SizedBox();

        final isSelected =
            _state.selectedMangaIds.contains(manga.id) && _state.isSelectMode;

        return Stack(
          children: [
            MangaListTileCard(
              key: ValueKey(manga.id),
              buildCover:
                  !(_state.isScrolling && _state.currentVelocity.abs() > 500),
              onTap: () => _state.isSelectMode
                  ? _controller.handleSelectManga(manga)
                  : _controller.handleMangaCardTap(manga),
              onLongPressed: () => _state.isSelectMode
                  ? null
                  : _controller.handleLongPressManga(manga),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) => FileUtil.copyMangaName(manga.title),
                    // foregroundColor: Colors.red,
                    icon: Icons.copy,
                  ),
                  SlidableAction(
                    onPressed: (_) =>
                        Get.dialog(_buildDeleteMangaDialog(manga)),
                    foregroundColor: Colors.red,
                    icon: Icons.delete,
                  ),
                ],
              ),
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
          height: UiConfig.bottomBarHeight,
          child: Row(
            mainAxisAlignment: .spaceEvenly,
            crossAxisAlignment: .center,
            children: [
              IconButton(
                onPressed: () => Get.dialog(_buildMoveGroupDialog()),
                icon: Icon(Icons.drive_file_move),
              ),
              IconButton(
                onPressed: () => Get.dialog(_buildDeleteMangasDialog()),
                icon: Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
        ).paddingOnly(bottom: Get.bottomBarHeight - UiConfig.bottomBarHeight);
      },
    );
  }

  Widget _buildNewGroupDialog() {
    final textController = TextEditingController();
    return CommonDialog(
      title: '新建分组',
      content: TextField(
        controller: textController,
        decoration: InputDecoration(hintText: '请输入分组名称'),
      ),
      onConfirm: () => _controller.handleAddGroup(textController.text.trim()),
    );
  }

  Widget _buildMoveGroupDialog() {
    return SelectDialog(
      title: '请选择分组',
      items: _state.groups,
      onConfirm: (index) =>
          _controller.handleMoveMangas2Group(_state.groups[index]),
    );
  }

  Widget _buildDeleteMangaDialog(Manga manga) {
    return CommonDialog(
      title: '删除漫画',
      content: Text('确定要删除漫画吗？'),
      onConfirm: () => _controller.handleDeleteManga(manga),
    );
  }

  Widget _buildDeleteMangasDialog() {
    return CommonDialog(
      title: '删除所选漫画',
      content: Text('确定要删除所选漫画吗？'),
      onConfirm: _controller.handleDeleteMangas,
    );
  }
}
