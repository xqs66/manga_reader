import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/pages/books/mangas_page_controller.dart';
import 'package:manga_reader/routes/app_route_observer.dart';
import 'package:manga_reader/settings/path_setting.dart';
import 'package:manga_reader/core/constants/constants.dart';
import 'package:manga_reader/core/extensions/string_ext.dart';
import 'package:manga_reader/core/extensions/text_ext.dart';
import 'package:manga_reader/core/utils/file_util.dart';
import 'package:manga_reader/settings/read_setting.dart';
import 'package:manga_reader/widgets/dialogs/common_dialog.dart';
import 'package:manga_reader/widgets/empty_state.dart';
import 'package:manga_reader/widgets/group_header.dart';
import 'package:manga_reader/widgets/grid/manga_grid_view.dart';
import 'package:manga_reader/widgets/grid/group_grid_view.dart';
import 'package:manga_reader/widgets/manga_list_tile_card.dart';
import 'package:manga_reader/widgets/dialogs/select_dialog.dart';
import 'package:manga_reader/widgets/selected_item_decoration.dart';
import 'package:manga_reader/widgets/selection/selection_app_bar.dart';
import 'package:manga_reader/widgets/styled_menu.dart';

class MangasPage extends StatefulWidget {
  const MangasPage({super.key});

  @override
  State<MangasPage> createState() => _MangasPageState();
}

class _MangasPageState extends State<MangasPage> with RouteAware {
  final _controller = Get.put(MangasPageController(), permanent: true);
  final _state = Get.find<MangasPageController>().state;

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
    return GetBuilder<MangasPageController>(
      id: _controller.appBarId,
      builder: (_) {
        return Scaffold(
          appBar: _state.isSelectMode
              ? _buildSelectModeAppbar()
              : _state.isSearchMode
              ? _buildSearchModeAppbar()
              : _buildNormalAppbar(),
          body: _buildBody(),
          bottomNavigationBar: _buildBottomBar(),
        );
      },
    );
  }

  PreferredSizeWidget _buildNormalAppbar() {
    final isGridGroup =
        readSetting.bookshelfLayout.value == BookshelfLayout.grid && _state.currentGridGroup != null;
    return AppBar(
      leading: _state.isAtRoot
          ? null
          : isGridGroup
              ? IconButton(
                  onPressed: _controller.backFromGridGroup,
                  icon: const Icon(Icons.arrow_back_rounded),
                )
              : IconButton(
                  onPressed: _controller.backToRoot,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
      title: Text(isGridGroup
          ? _state.currentGridGroup!
          : _state.isAtRoot
              ? '书架'
              : _state.currentPath?.split('/').last ?? '书架'),
      centerTitle: true,
      actions: [
        if (!_state.isAtRoot)
          GetBuilder<MangasPageController>(
            id: _controller.normalAppBarActionsId,
            builder: (context) {
              return IconButton(
                onPressed: _controller.toggleSearchMode,
                icon: const Icon(Icons.search_rounded),
              );
            },
          ),
        GetBuilder<MangasPageController>(
          id: _controller.normalAppBarActionsId,
          builder: (_) {
            return StyledPopupMenu<String>(
              items: [
                if (!_state.isAtRoot && _state.currentGridGroup == null)
                  StyledPopupItem(
                    value: 'new_group',
                    label: '新建分组',
                    icon: Icons.create_new_folder_rounded,
                    onSelected: (_) => Get.dialog(_buildNewGroupDialog()),
                  ),
                StyledPopupItem(
                  value: 'toggle_layout',
                  label: readSetting.bookshelfLayout.value == BookshelfLayout.list ? '切换为网格' : '切换为列表',
                  icon: readSetting.bookshelfLayout.value == BookshelfLayout.list
                      ? Icons.grid_view_rounded
                      : Icons.view_list_rounded,
                  onSelected: (_) => _controller.toggleLayoutMode(),
                ),
                StyledPopupItem(
                  value: 'refresh',
                  label: '刷新',
                  icon: Icons.refresh_rounded,
                  onSelected: (_) => _controller.refreshMangas(),
                ),
              ],
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.more_vert_rounded),
              ),
            );
          },
        ),
      ],
    );
  }

  PreferredSizeWidget _buildSelectModeAppbar() {
    return SelectionAppBar(
      selectedCount: _state.selectedMangaIds.length,
      onClear: _controller.toggleSelectMode,
      onSelectAll: _controller.handleSelectAll,
      isAllSelected: _state.isSelectedAll,
    );
  }

  PreferredSizeWidget _buildSearchModeAppbar() {
    return AppBar(
      leading: IconButton(
        onPressed: _controller.toggleSearchMode,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: _buildSearchBox(),
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      autofocus: true,
      controller: _state.searchTextController,
      onChanged: (value) => _controller.handleSearch(value),
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: '搜索漫画...',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
        contentPadding: .symmetric(vertical: 8),
        suffixIcon: _state.searchTextController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _state.searchTextController.clear();
                  _controller.handleSearch('');
                },
                icon: const Icon(Icons.clear_rounded, size: 20),
              )
            : null,
        border: .none,
        isDense: true,
      ),
    );
  }

  Widget _buildBody() {
    return GetBuilder<MangasPageController>(
      id: _controller.bodyId,
      builder: (_) {
        _controller.tryAutoRestore();
        return Column(
          children: [
            _buildRefreshIndicator(),
            Expanded(child: _buildBodyContent()),
          ],
        );
      },
    );
  }

  Widget _buildRefreshIndicator() {
    return GetBuilder<MangasPageController>(
      id: _controller.refreshProgressId,
      builder: (_) {
        if (!_state.isRefreshing) return const SizedBox.shrink();
        return const LinearProgressIndicator(minHeight: 3);
      },
    );
  }

  Widget _buildBodyContent() {
    if (_state.isAtRoot) return _buildLocalPaths();
    if (_state.isSearchMode) return _buildMangaListWithoutGroup();
    if (_state.mangas.isEmpty) return _buildEmptyState();
    if (readSetting.bookshelfLayout.value == BookshelfLayout.grid) return _buildGridLayout();
    return _buildGroupedBooksList();
  }

  // ── Grid layout ──

  Widget _buildGridLayout() {
    if (_state.currentGridGroup != null) {
      return _buildMangaGrid(_controller.mangasForCurrentGrid);
    }
    return _buildGroupFoldersGrid();
  }

  Widget _buildGroupFoldersGrid() {
    return GroupGridView(
      groups: _state.groups,
      allMangas: _state.mangas,
      controller: _controller,
      onEnter: _controller.enterGridGroup,
      deleteGroupDialogBuilder: _buildDeleteGroupDialog,
    );
  }

  Widget _buildMangaGrid(List<Manga> mangas) {
    return MangaGridView(mangas: mangas, controller: _controller);
  }

  Widget _buildEmptyState() {
    return const EmptyState(
      icon: Icons.folder_open_rounded,
      title: '未发现漫画',
      subtitle: '请先在设置中添加漫画源路径',
    );
  }

  Widget _buildLocalPaths() {
    if (pathSetting.paths.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: pathSetting.paths.length,
      itemBuilder: (context, index) {
        final path = pathSetting.paths[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: .circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.folder_rounded,
              color: UiConfig.primaryColor,
            ),
            title: Text(
              path.displayPath(),
              maxLines: 2,
              overflow: .ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            shape: RoundedRectangleBorder(borderRadius: .circular(12)),
            onTap: () => _controller.enterMangaDir(path),
          ),
        );
      },
    );
  }

  Widget _buildMangaListWithoutGroup() {
    if (_state.searchedMangas.isEmpty) {
      return const EmptyState(icon: Icons.search_off_rounded, title: '无搜索结果');
    }
    if (readSetting.bookshelfLayout.value == BookshelfLayout.grid) {
      return _buildMangaGrid(_state.searchedMangas);
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _state.searchedMangas.length,
      itemBuilder: (context, index) =>
          _buildElement(true, _state.searchedMangas[index]),
    );
  }

  Widget _buildGroupedBooksList() {
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
    final List<Widget> slivers = [];
    for (int i = 0; i < _state.groups.length; i++) {
      final mangasInGroup = _state.mangas
          .where((m) => m.groupName == _state.groups[i])
          .toList();
      slivers.add(_buildGroupSliver(i));
      if (mangasInGroup.isEmpty) continue;
      slivers.add(_buildElementSliver(i, mangasInGroup));
    }
    return slivers;
  }

  Widget _buildElementSliver(int groupIndex, List<Manga> mangas) {
    return GetBuilder<MangasPageController>(
      id: '${_controller.mangasInGroupIdPrefix}::${_state.groups[groupIndex]}',
      builder: (_) {
        final isDisplay = _state.displayGroups.contains(
          _state.groups[groupIndex],
        );
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildElement(isDisplay, mangas[index]),
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
    return GetBuilder<MangasPageController>(
      id: '${_controller.groupIdPrefix}::$groupName',
      builder: (_) {
        final isDisplay = _state.displayGroups.contains(groupName);
        final mangaCount = _state.mangas
            .where((m) => m.groupName == groupName)
            .length;
        return GroupHeader(
          onTap: () => _controller.toggleGroupExpand(index),
          onLongPress: () {
            if (groupName == Constants.defaultGroupName) return;
            StyledActionSheet.show(
              context: context,
              actions: [
                StyledAction(
                  label: '删除分组',
                  isDestructive: true,
                  onPressed: () =>
                      Get.dialog(_buildDeleteGroupDialog(groupName)),
                ),
              ],
            );
          },
          child: Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        groupName,
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$mangaCount',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isDisplay
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildElement(bool isDisplay, Manga manga) {
    return GetBuilder<MangasPageController>(
      id: '${_controller.mangaIdPrefix}::${manga.id}',
      builder: (_) {
        if (!isDisplay) return const SizedBox.shrink();

        final isSelected =
            _state.selectedMangaIds.contains(manga.id) && _state.isSelectMode;

        return SelectedItemDecoration(
          isSelected: isSelected,
          child: Stack(
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
                      icon: Icons.copy_rounded,
                      label: '复制',
                    ),
                    SlidableAction(
                      onPressed: (_) =>
                          Get.dialog(_buildDeleteMangaDialog(manga)),
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

  Widget _buildBottomBar() {
    return GetBuilder<MangasPageController>(
      id: _controller.bottomBarId,
      builder: (_) {
        if (!_state.isSelectMode) return const SizedBox.shrink();

        final view = PlatformDispatcher.instance.views.first;
        final bottomInset = view.padding.bottom / view.devicePixelRatio;

        return BottomAppBar(
          height: UiConfig.bottomBarHeight + bottomInset,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Row(
            mainAxisAlignment: .spaceEvenly,
            children: [
              _buildBottomAction(
                icon: Icons.drive_file_move_rounded,
                label: '移动',
                onPressed: () {
                  if (_state.selectedMangaIds.isEmpty) {
                    Fluttertoast.showToast(msg: '请先选择漫画');
                    return;
                  }
                  Get.dialog(_buildMoveGroupDialog());
                },
              ),
              _buildBottomAction(
                icon: Icons.delete_rounded,
                label: '删除',
                color: Colors.red,
                onPressed: () {
                  if (_state.selectedMangaIds.isEmpty) {
                    Fluttertoast.showToast(msg: '请先选择漫画');
                    return;
                  }
                  Get.dialog(_buildDeleteMangasDialog());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomAction({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color)),
    );
  }

  Widget _buildNewGroupDialog() {
    final textController = TextEditingController();
    return CommonDialog(
      title: '新建分组',
      content: TextField(
        autofocus: true,
        controller: textController,
        decoration: const InputDecoration(hintText: '请输入分组名称'),
      ),
      onConfirm: () => _controller.handleAddGroup(textController.text.trim()),
    );
  }

  Widget _buildMoveGroupDialog() {
    return SelectDialog(
      title: '移动到分组',
      items: _state.groups,
      onConfirm: (index) =>
          _controller.handleMoveMangasToGroup(_state.groups[index]),
    );
  }

  Widget _buildDeleteMangaDialog(Manga manga) {
    return CommonDialog(
      title: '删除漫画',
      content: Text('确定要删除《${manga.title}》吗？'),
      onConfirm: () => _controller.handleDeleteManga(manga),
    );
  }

  Widget _buildDeleteMangasDialog() {
    return CommonDialog(
      title: '批量删除',
      content: Text('确定要删除已选的 ${_state.selectedMangaIds.length} 部漫画吗？'),
      onConfirm: _controller.handleDeleteMangas,
    );
  }

  Widget _buildDeleteGroupDialog(String groupName) {
    return GetBuilder<MangasPageController>(
      id: _controller.deleteGroupDialogId,
      builder: (_) {
        return CommonDialog(
          title: '删除分组"$groupName"',
          content: Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              const Text('请选择对该分组下漫画的处理方式：').size(15),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _state.toDefaultGroupOnceDelete,
                onChanged: (value) =>
                    _controller.handleChangeDeleteGroupOption(value ?? false),
                title: const Text('移动至默认分组'),
                contentPadding: .zero,
                horizontalTitleGap: 0,
                controlAffinity: .leading,
                dense: true,
              ),
              CheckboxListTile(
                value: _state.deleteOnceGroupDeleted,
                onChanged: (value) => _controller.handleChangeDeleteGroupOption(
                  !(value ?? false),
                ),
                title: const Text('同时删除分组下漫画'),
                subtitle: const Text('此操作不可恢复'),
                contentPadding: .zero,
                horizontalTitleGap: 0,
                controlAffinity: .leading,
                dense: true,
              ),
            ],
          ),
          onConfirm: () => _controller.handleDeleteGroup(groupName),
        );
      },
    );
  }
}
