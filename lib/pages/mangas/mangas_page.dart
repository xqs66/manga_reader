import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/pages/mangas/mangas_page_controller.dart';
import 'package:manga_reader/widgets/sort_sheet.dart';
import 'package:manga_reader/routes/app_route_observer.dart';
import 'package:manga_reader/settings/path_setting.dart';
import 'package:manga_reader/core/extensions/string_ext.dart';
import 'package:manga_reader/core/extensions/text_ext.dart';
import 'package:manga_reader/settings/read_setting.dart';
import 'package:manga_reader/widgets/dialogs/common_dialog.dart';
import 'package:manga_reader/widgets/empty_state.dart';
import 'package:manga_reader/pages/mangas/layout/manga_grid_view.dart';
import 'package:manga_reader/pages/mangas/layout/group_grid_view.dart';
import 'package:manga_reader/pages/mangas/layout/manga_list_view.dart';
import 'package:manga_reader/pages/mangas/layout/group_list_view.dart';
import 'package:manga_reader/widgets/dialogs/select_dialog.dart';
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
    final isInGroup = _state.currentGridGroup != null;
    return AppBar(
      leading: _state.isAtRoot
          ? null
          : isInGroup
          ? IconButton(
              onPressed: _controller.backFromGridGroup,
              icon: const Icon(Icons.arrow_back_rounded),
            )
          : IconButton(
              onPressed: _controller.backToRoot,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
      title: Text(
        isInGroup
            ? _state.currentGridGroup!
            : _state.isAtRoot
            ? '书架'
            : _state.currentPath?.displayPath() ?? '书架',
      ),
      centerTitle: true,
      actions: [
        if (!_state.isAtRoot) ...[
          GetBuilder<MangasPageController>(
            id: _controller.normalAppBarActionsId,
            builder: (_) {
              return IconButton(
                onPressed: _controller.toggleSearchMode,
                icon: const Icon(Icons.search_rounded),
              );
            },
          ),
          GetBuilder<MangasPageController>(
            id: _controller.normalAppBarActionsId,
            builder: (_) {
              return IconButton(
                onPressed: () => SortSheet.show(context, _controller),
                icon: const Icon(Icons.sort_rounded),
                tooltip: '排序',
              );
            },
          ),
        ],
        GetBuilder<MangasPageController>(
          id: _controller.normalAppBarActionsId,
          builder: (_) => _buildPopMenu(),
        ),
      ],
    );
  }

  StyledPopupMenu<String> _buildPopMenu() {
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
          label: readSetting.bookshelfLayout.value == BookshelfLayout.list
              ? '切换为网格'
              : '切换为列表',
          icon: readSetting.bookshelfLayout.value == BookshelfLayout.list
              ? Icons.grid_view_rounded
              : Icons.view_list_rounded,
          onSelected: (_) => _controller.toggleLayoutMode(),
        ),
        if (!_state.isAtRoot)
          StyledPopupItem(
            value: 'continue_last',
            label: '继续上次阅读',
            icon: Icons.history_rounded,
            onSelected: (_) => _controller.openLastReadManga(),
          ),
        if (!_state.isAtRoot)
          StyledPopupItem(
            value: 'random',
            label: '打开随机一本',
            icon: Icons.shuffle_rounded,
            onSelected: (_) => _controller.openRandomManga(),
          ),
        StyledPopupItem(
          value: 'refresh',
          label: '刷新',
          icon: Icons.refresh_rounded,
          onSelected: (_) => _controller.refreshMangas(),
        ),
      ],
      child: const Padding(
        padding: EdgeInsets.only(right: 12),
        child: Icon(Icons.more_vert_rounded),
      ),
    );
  }

  PreferredSizeWidget _buildSelectModeAppbar() {
    final list = _state.isSearchMode
        ? _state.searchedMangas
        : _state.currentGridGroup != null
        ? _controller.mangasForCurrentGrid
        : _state.mangas;
    return SelectionAppBar(
      selectedCount: _state.selectedMangaIds.length,
      onClear: _controller.toggleSelectMode,
      onSelectAll: _controller.handleSelectAll,
      isAllSelected:
          _state.selectedMangaIds.length == list.length && list.isNotEmpty,
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
    if (_state.isSearchMode) return _buildSearchResults();
    if (_state.mangas.isEmpty) return _buildEmptyState();
    return _buildMangas();
  }

  // ── Unified manga/group display ──

  /// Dispatches to the correct layout widget based on [readSetting.bookshelfLayout]
  /// and whether a group folder is currently selected.
  Widget _buildMangas() {
    if (_state.currentGridGroup != null) {
      return readSetting.bookshelfLayout.value == BookshelfLayout.grid
          ? MangaGridView(
              mangas: _controller.mangasForCurrentGrid,
              controller: _controller,
            )
          : MangaListView(
              mangas: _controller.mangasForCurrentGrid,
              controller: _controller,
              scrollController: _state.scrollController,
              onScroll: _controller.handleScrollEvent,
              onDeleteManga: (m) => Get.dialog(_buildDeleteMangaDialog(m)),
            );
    }
    return readSetting.bookshelfLayout.value == BookshelfLayout.grid
        ? GroupGridView(
            groups: _state.groups,
            allMangas: _state.mangas,
            controller: _controller,
            onEnter: _controller.enterGridGroup,
            deleteGroupDialogBuilder: _buildDeleteGroupDialog,
          )
        : GroupListView(
            groups: _state.groups,
            allMangas: _state.mangas,
            onEnter: _controller.enterGridGroup,
            deleteGroupDialogBuilder: _buildDeleteGroupDialog,
          );
  }

  Widget _buildSearchResults() {
    if (_state.searchedMangas.isEmpty) {
      return const EmptyState(icon: Icons.search_off_rounded, title: '无搜索结果');
    }
    if (readSetting.bookshelfLayout.value == BookshelfLayout.grid) {
      return MangaGridView(
        mangas: _state.searchedMangas,
        controller: _controller,
      );
    }
    return MangaListView(
      mangas: _state.searchedMangas,
      controller: _controller,
      scrollController: _state.scrollController,
      onScroll: _controller.handleScrollEvent,
      onDeleteManga: (m) => Get.dialog(_buildDeleteMangaDialog(m)),
    );
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
