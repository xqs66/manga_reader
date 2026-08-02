import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/core/extensions/string_ext.dart';
import 'package:manga_reader/core/extensions/text_ext.dart';
import 'package:manga_reader/core/utils/file_util.dart';
import 'package:manga_reader/core/mixin/scroll_handler.dart';
import 'package:manga_reader/models/discovered_server.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/ui/pages/mangas/components/group_grid_view.dart';
import 'package:manga_reader/ui/pages/mangas/components/group_list_view.dart';
import 'package:manga_reader/ui/layout/grid/components/manga_grid_view.dart';
import 'package:manga_reader/ui/layout/manga_list_layout/manga_list_layout.dart';
import 'package:manga_reader/ui/layout/list/components/manga_list_view.dart';
import 'package:manga_reader/ui/pages/mangas/mangas_page_controller.dart';
import 'package:manga_reader/ui/pages/mangas/mangas_page_state.dart';
import 'package:manga_reader/routes/app_route_observer.dart';
import 'package:manga_reader/settings/path_setting.dart';
import 'package:manga_reader/settings/read_setting.dart';
import 'package:manga_reader/ui/widgets/dialogs/common_dialog.dart';
import 'package:manga_reader/ui/widgets/dialogs/select_dialog.dart';
import 'package:manga_reader/ui/widgets/empty_state.dart';
import 'package:manga_reader/ui/layout/grid/components/manga_grid_card.dart';
import 'package:manga_reader/ui/layout/list/components/manga_list_tile_card.dart';
import 'package:manga_reader/ui/layout/list/components/selected_item_decoration.dart';
import 'package:manga_reader/ui/widgets/selection/selection_app_bar.dart';
import 'package:manga_reader/ui/widgets/sort_sheet.dart';
import 'package:manga_reader/ui/widgets/styled_menu.dart';

class MangasPage extends StatefulWidget
    with MangaListLayout<MangasPageController, MangasPageState> {
  MangasPage({super.key});

  @override
  final controller = Get.put(MangasPageController(), permanent: true);

  @override
  MangasPageState get state => controller.state;

  @override
  State<MangasPage> createState() => _MangasPageState();

  @override
  Widget buildLayout(BuildContext context) {
    return GetBuilder<MangasPageController>(
      id: controller.appBarId,
      builder: (_) {
        // System back on the bookshelf tab walks back one navigation level:
        // search → selection → grid group → subdirectory → root. Only at the
        // root does the default pop (exit app) go through.
        return PopScope(
          canPop: state.isAtRoot &&
              !state.isSearchMode &&
              !state.isSelectMode &&
              state.currentGridGroup == null,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (state.isSearchMode) {
              controller.toggleSearchMode();
            } else if (state.isSelectMode) {
              controller.toggleSelectMode();
            } else if (state.currentGridGroup != null) {
              controller.backFromGridGroup();
            } else if (!state.isAtRoot) {
              controller.backToRoot();
            }
          },
          child: Scaffold(
            appBar: state.isSearchMode
                ? buildSearchAppBar()
                : state.isSelectMode
                ? _buildSelectModeAppbar()
                : buildNormalAppBar(context),
            body: _buildWrappedBody(context),
            bottomNavigationBar: _buildBottomBar(),
          ),
        );
      },
    );
  }

  @override
  PreferredSizeWidget buildNormalAppBar(BuildContext context) {
    final isInGroup = state.currentGridGroup != null;
    return AppBar(
      leading: state.isAtRoot
          ? null
          : isInGroup
          ? IconButton(
              onPressed: controller.backFromGridGroup,
              icon: const Icon(Icons.arrow_back_rounded),
            )
          : IconButton(
              onPressed: controller.backToRoot,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
      title: Row(
        mainAxisSize: .min,
        children: [
          if (state.isRemotePath) ...[
            const Icon(Icons.language_rounded, size: 18),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              isInGroup
                  ? state.currentGridGroup!
                  : state.isAtRoot
                  ? '书架'
                  : state.currentPath?.displayPath() ?? '书架',
              overflow: .ellipsis,
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        if (!state.isAtRoot) ...[
          GetBuilder<MangasPageController>(
            id: controller.normalAppBarActionsId,
            builder: (_) => IconButton(
              onPressed: controller.toggleSearchMode,
              icon: const Icon(Icons.search_rounded),
            ),
          ),
          GetBuilder<MangasPageController>(
            id: controller.normalAppBarActionsId,
            builder: (_) => IconButton(
              onPressed: () => SortSheet.show(context, controller),
              icon: const Icon(Icons.sort_rounded),
              tooltip: '排序',
            ),
          ),
        ],
        GetBuilder<MangasPageController>(
          id: controller.normalAppBarActionsId,
          builder: (_) => _buildPopMenu(),
        ),
      ],
    );
  }

  @override
  Widget buildNormalContent(BuildContext context) {
    if (state.isAtRoot) return _buildRootContent();
    if (state.mangas.isEmpty) return _buildEmptyContent();
    return _buildMangas();
  }

  @override
  Widget buildGridCard(
    BuildContext context,
    int index,
    Manga manga,
    double cardWidth,
  ) {
    return GetBuilder<MangasPageController>(
      id: '${controller.mangaIdPrefix}::${manga.id}',
      builder: (_) {
        final selected =
            state.isSelectMode && state.selectedMangaIds.contains(manga.id);
        return _buildSelectableGridCard(manga, cardWidth, selected);
      },
    );
  }

  @override
  Widget buildListTile(BuildContext context, int index, Manga manga,
      {bool buildCover = true}) {
    return GetBuilder<MangasPageController>(
      id: '${controller.mangaIdPrefix}::${manga.id}',
      builder: (_) {
        final isSelected =
            state.isSelectMode && state.selectedMangaIds.contains(manga.id);
        return SelectedItemDecoration(
          isSelected: isSelected,
          child: _buildListTileCard(manga, index, buildCover: buildCover),
        );
      },
    );
  }

  // ── Body ──

  Widget _buildWrappedBody(BuildContext context) {
    return GetBuilder<MangasPageController>(
      id: controller.bodyId,
      builder: (_) {
        controller.tryAutoRestore();
        return Column(
          children: [
            _buildRefreshIndicator(),
            Expanded(
              child: state.isSearchMode
                  ? buildSearchResults()
                  : buildNormalContent(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRefreshIndicator() {
    return GetBuilder<MangasPageController>(
      id: controller.refreshProgressId,
      builder: (_) {
        if (!state.isRefreshing) return const SizedBox.shrink();
        return const LinearProgressIndicator(minHeight: 3);
      },
    );
  }

  Widget _buildEmptyContent() {
    return const EmptyState(
      icon: Icons.folder_open_rounded,
      title: '未发现漫画',
      subtitle: '请先在设置中添加漫画源路径',
    );
  }

  Widget _buildRootContent() {
    final localPaths = pathSetting.paths;
    final servers = state.connectedServers;
    final hasLocal = localPaths.isNotEmpty;
    final hasLan = servers.isNotEmpty;
    final isEmpty = !hasLocal && !hasLan;

    if (isEmpty) {
      return Column(
        children: [
          const Expanded(child: EmptyState(
            icon: Icons.wifi_find_rounded,
            title: '书架为空',
            subtitle: '添加本地漫画源路径或连接局域网服务器',
          )),
          _buildAddServerButton(),
          const SizedBox(height: 40),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        if (hasLocal) ...[
          _buildSectionHeader('本机'),
          ...localPaths.map((path) => _buildLocalPathCard(path)),
        ],
        if (hasLan) ...[
          const SizedBox(height: 12),
          _buildSectionHeader('局域网'),
          ...servers.map((s) => _buildServerCard(s)),
        ],
        const SizedBox(height: 8),
        _buildAddServerButton(),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLocalPathCard(String path) {
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
        onTap: () => controller.enterMangaDir(path),
      ),
    );
  }

  Widget _buildServerCard(DiscoveredServer server) {
    final connected = server.isConnected;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: .circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (connected ? Colors.green : Colors.grey).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.computer_rounded,
            color: connected ? Colors.green : Colors.grey,
            size: 22,
          ),
        ),
        title: Text(
          server.displayName,
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          connected
              ? '${server.host}:${server.port}'
              : '${server.host}:${server.port} · 未连接',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        trailing: !connected
            ? TextButton(
                onPressed: () => controller.tryConnectServer(server),
                child: const Text('连接'),
              )
            : null,
        shape: RoundedRectangleBorder(borderRadius: .circular(12)),
        onTap: connected ? () => controller.onServerTap(server) : null,
        onLongPress: () => _showServerActions(server),
      ),
    );
  }

  void _showServerActions(DiscoveredServer server) {
    StyledActionSheet.show(
      context: Get.context!,
      title: server.displayName,
      actions: [
        StyledAction(
          label: '删除服务器',
          isDestructive: true,
          onPressed: () => _confirmDeleteServer(server),
        ),
      ],
    );
  }

  void _confirmDeleteServer(DiscoveredServer server) {
    Get.dialog(CommonDialog(
      title: '删除服务器',
      content: Text('确定要删除"${server.displayName}"吗？'),
      onConfirm: () {
        controller.removeConnectedServer(server);
        Get.back();
      },
    ));
  }

  Widget _buildAddServerButton() {
    return TextButton.icon(
      onPressed: () => controller.openAddServer(),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text('添加服务器'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.grey.shade600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget buildSearchResults() {
    if (state.searchedMangas.isEmpty) {
      return const EmptyState(icon: Icons.search_off_rounded, title: '无搜索结果');
    }
    if (readSetting.bookshelfLayout.value == BookshelfLayout.grid) {
      return buildMangaGridView();
    }
    return ScrollWrapper.scrollbar(
      scrollController: controller.listScrollController,
      useDelayedStart: true,
      onStateChanged: () => controller.update([controller.bodyId]),
      builder: (context, handler) => MangaListView(
        mangas: displayMangas,
        scrollController: controller.listScrollController,
        tileBuilder: (context, index, manga) {
          final buildCover =
              !(handler.isScrolling && handler.currentVelocity.abs() > 500);
          return buildListTile(context, index, manga,
              buildCover: buildCover);
        },
      ),
    );
  }

  // ── Manga/group display ──

  Widget _buildMangas() {
    if (state.currentGridGroup != null) {
      final mangas = controller.mangasForCurrentGrid;
      return readSetting.bookshelfLayout.value == BookshelfLayout.grid
          ? MangaGridView(mangas: mangas, cardBuilder: buildGridCard)
          : ScrollWrapper.scrollbar(
              scrollController: controller.listScrollController,
              useDelayedStart: true,
              onStateChanged: () => controller.update([controller.bodyId]),
              builder: (context, handler) => MangaListView(
                mangas: mangas,
                scrollController: controller.listScrollController,
                tileBuilder: (context, index, manga) {
                  final buildCover =
                      !(handler.isScrolling &&
                          handler.currentVelocity.abs() > 500);
                  return buildListTile(context, index, manga,
                      buildCover: buildCover);
                },
              ),
            );
    }
    return readSetting.bookshelfLayout.value == BookshelfLayout.grid
        ? GroupGridView(
            groups: state.groups,
            allMangas: state.mangas,
            controller: controller,
            onEnter: controller.enterGridGroup,
            deleteGroupDialogBuilder: _buildDeleteGroupDialog,
          )
        : GroupListView(
            groups: state.groups,
            allMangas: state.mangas,
            onEnter: controller.enterGridGroup,
            deleteGroupDialogBuilder: _buildDeleteGroupDialog,
          );
  }

  // ── Card / tile builders ──

  Widget _buildListTileCard(Manga manga, int index, {bool buildCover = true}) {
    return MangaListTileCard(
      key: ValueKey(manga.id),
      buildCover: buildCover,
      manga: manga,
      onTap: () => state.isSelectMode
          ? controller.handleSelectManga(manga)
          : controller.handleMangaCardTap(manga),
      onLongPressed: () =>
          state.isSelectMode ? null : controller.handleLongPressManga(manga),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => FileUtil.copyMangaName(manga.title),
            icon: Icons.copy_rounded,
            label: '复制',
          ),
          if (!state.isRemotePath)
            SlidableAction(
              onPressed: (_) => Get.dialog(_buildDeleteMangaDialog(manga)),
              foregroundColor: Colors.red,
              icon: Icons.delete_rounded,
              label: '删除',
            ),
        ],
      ),
    );
  }

  Widget _buildSelectableGridCard(
    Manga manga,
    double cardWidth,
    bool selected,
  ) {
    final isSelect = state.isSelectMode;
    return Stack(
      children: [
        MangaGridCard(
          manga: manga,
          width: cardWidth,
          onTap: () => isSelect
              ? controller.handleSelectManga(manga)
              : controller.handleMangaCardTap(manga),
          onLongPress:
              isSelect ? null : () => controller.handleLongPressManga(manga),
        ),
        if (selected)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: .circular(12),
                  border: Border.all(color: UiConfig.primaryColor, width: 2.5),
                ),
              ),
            ),
          ),
        if (selected)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: UiConfig.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            ),
          ),
      ],
    );
  }

  // ── App bar ──

  StyledPopupMenu<String> _buildPopMenu() {
    final isRemote = state.isRemotePath;
    return StyledPopupMenu<String>(
      items: [
        if (!state.isAtRoot && state.currentGridGroup == null && !isRemote)
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
          onSelected: (_) => controller.toggleLayoutMode(),
        ),
        if (!state.isAtRoot)
          StyledPopupItem(
            value: 'continue_last',
            label: '继续上次阅读',
            icon: Icons.history_rounded,
            onSelected: (_) => controller.openLastReadManga(),
          ),
        if (!state.isAtRoot)
          StyledPopupItem(
            value: 'random',
            label: '打开随机一本',
            icon: Icons.shuffle_rounded,
            onSelected: (_) => controller.openRandomManga(),
          ),
        if (!isRemote)
          StyledPopupItem(
            value: 'refresh',
            label: '刷新',
            icon: Icons.refresh_rounded,
            onSelected: (_) => controller.refreshMangas(),
          ),
      ],
      child: const Padding(
        padding: EdgeInsets.only(left: 6, right: 16),
        child: Icon(Icons.more_vert_rounded),
      ),
    );
  }

  PreferredSizeWidget _buildSelectModeAppbar() {
    final list = state.isSearchMode
        ? state.searchedMangas
        : state.currentGridGroup != null
        ? controller.mangasForCurrentGrid
        : state.mangas;
    return SelectionAppBar(
      selectedCount: state.selectedMangaIds.length,
      onClear: controller.toggleSelectMode,
      onSelectAll: controller.handleSelectAll,
      isAllSelected:
          state.selectedMangaIds.length == list.length && list.isNotEmpty,
    );
  }

  // ── Bottom bar ──

  Widget _buildBottomBar() {
    return GetBuilder<MangasPageController>(
      id: controller.bodyId,
      builder: (_) {
        if (!state.isSelectMode) return const SizedBox.shrink();
        final view = PlatformDispatcher.instance.views.first;
        final bottomInset = view.padding.bottom / view.devicePixelRatio;
        final isRemote = state.isRemotePath;
        return BottomAppBar(
          height: UiConfig.bottomBarHeight + bottomInset,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Row(
            mainAxisAlignment: .spaceEvenly,
            children: [
              if (!isRemote)
                _buildBottomAction(
                  icon: Icons.drive_file_move_rounded,
                  label: '移动',
                  onPressed: () {
                    if (state.selectedMangaIds.isEmpty) {
                      Fluttertoast.showToast(msg: '请先选择漫画');
                      return;
                    }
                    Get.dialog(_buildMoveGroupDialog());
                  },
                ),
              if (!isRemote)
                _buildBottomAction(
                  icon: Icons.delete_rounded,
                  label: '删除',
                  color: Colors.red,
                  onPressed: () {
                    if (state.selectedMangaIds.isEmpty) {
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

  // ── Dialogs ──

  Widget _buildNewGroupDialog() {
    final tc = TextEditingController();
    return CommonDialog(
      title: '新建分组',
      content: TextField(
        autofocus: true,
        controller: tc,
        decoration: const InputDecoration(hintText: '请输入分组名称'),
      ),
      onConfirm: () => controller.handleAddGroup(tc.text.trim()),
    );
  }

  Widget _buildMoveGroupDialog() {
    return SelectDialog(
      title: '移动到分组',
      items: state.groups,
      onConfirm: (i) => controller.handleMoveMangasToGroup(state.groups[i]),
    );
  }

  Widget _buildDeleteMangaDialog(Manga manga) {
    return CommonDialog(
      title: '删除漫画',
      content: Text('确定要删除《${manga.title}》吗？'),
      onConfirm: () => controller.handleDeleteManga(manga),
    );
  }

  Widget _buildDeleteMangasDialog() {
    return CommonDialog(
      title: '批量删除',
      content: Text('确定要删除已选的 ${state.selectedMangaIds.length} 部漫画吗？'),
      onConfirm: controller.handleDeleteMangas,
    );
  }

  Widget _buildDeleteGroupDialog(String groupName) {
    return GetBuilder<MangasPageController>(
      id: controller.deleteGroupDialogId,
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
                value: state.toDefaultGroupOnceDelete,
                onChanged: (v) =>
                    controller.handleChangeDeleteGroupOption(v ?? false),
                title: const Text('移动至默认分组'),
                contentPadding: .zero,
                horizontalTitleGap: 0,
                controlAffinity: .leading,
                dense: true,
              ),
              CheckboxListTile(
                value: state.deleteOnceGroupDeleted,
                onChanged: (v) =>
                    controller.handleChangeDeleteGroupOption(!(v ?? false)),
                title: const Text('同时删除分组下漫画'),
                subtitle: const Text('此操作不可恢复'),
                contentPadding: .zero,
                horizontalTitleGap: 0,
                controlAffinity: .leading,
                dense: true,
              ),
            ],
          ),
          onConfirm: () => controller.handleDeleteGroup(groupName),
        );
      },
    );
  }
}

class _MangasPageState extends State<MangasPage> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() => widget.controller.handlePopNext();

  @override
  Widget build(BuildContext context) => widget.buildLayout(context);
}
