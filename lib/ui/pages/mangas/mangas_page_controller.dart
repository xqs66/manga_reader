import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manga_reader/core/utils/log_util.dart';
import 'package:get/get.dart';
import 'package:manga_reader/core/enums/sort_mode.dart';
import 'package:manga_reader/core/repository/manga_repository.dart';
import 'package:manga_reader/service/storage_service.dart';
import 'package:manga_reader/models/discovered_server.dart';
import 'package:manga_reader/models/result.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/models/manga_id.dart';
import 'package:manga_reader/models/read_info.dart';
import 'package:manga_reader/ui/layout/manga_list_layout/manga_list_layout_controller.dart';
import 'package:manga_reader/ui/pages/mangas/mangas_page_state.dart';
import 'package:manga_reader/ui/pages/home/home_page_controller.dart';
import 'package:manga_reader/routes/routes.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/settings/read_setting.dart';
import 'package:manga_reader/core/constants/constants.dart';

class MangasPageController
    extends MangaListLayoutController<MangasPageState> {
  MangaRepository _repo;

  MangasPageController({MangaRepository? repo})
    : _repo = repo ?? Get.find<MangaRepository>();

  @override
  final state = MangasPageState();

  final listScrollController = ScrollController();

  final normalAppBarActionsId = 'normalAppBarActionsId';
  final mangaIdPrefix = 'Manga';
  final groupIdPrefix = 'Group';
  final mangasInGroupIdPrefix = 'MangasInGroup';
  final deleteGroupDialogId = 'deleteGroupDialogId';
  final refreshProgressId = 'refreshProgressId';

  static const _lastPathKey = 'last_source_path';
  static const _lastGroupKey = 'last_group_name';
  static const _sortModeKey = 'sort_mode';
  static const _sortAscKey = 'sort_ascending';
  bool _autoRestoreAttempted = false;

  @override
  void onInit() {
    super.onInit();
    _restoreSort();
    ever(readSetting.bookshelfLayout, (_) {
      state.currentGridGroup = null;
      update([bodyId, appBarId]);
    });
  }

  void _restoreSort() {
    final modeIndex = storageService.read<int>(_sortModeKey) ?? 0;
    state.sortMode =
        SortMode.values[modeIndex.clamp(0, SortMode.values.length - 1)];
    state.sortAscending = storageService.read<bool>(_sortAscKey) ?? true;
  }

  void _saveSort() {
    storageService.write(_sortModeKey, state.sortMode.index);
    storageService.write(_sortAscKey, state.sortAscending);
  }

  Future<void> tryAutoRestore() async {
    if (_autoRestoreAttempted || !state.isAtRoot) return;
    _autoRestoreAttempted = true;
    final path = storageService.read<String>(_lastPathKey);
    if (path == null) return;
    if (!localMangaService.settingPath2Mangas.containsKey(path)) {
      _autoRestoreAttempted = false;
      Future.delayed(const Duration(seconds: 1), () => tryAutoRestore());
      return;
    }
    await enterMangaDir(path);
    final group = storageService.read<String>(_lastGroupKey);
    if (group != null && state.groups.contains(group)) {
      state.currentGridGroup = group;
      update([bodyId, appBarId]);
    }
  }

  void handlePopNext() {
    if (state.isRemotePath) {
      _reloadRemoteMangas();
    } else {
      state.mangas =
          localMangaService.settingPath2Mangas[state.currentPath] ?? [];
      _syncGroupsFromPath();
      _applySort();
    }
    update([bodyId]);
  }

  Future<void> enterMangaDir(String path, {MangaRepository? repo}) async {
    state.isAtRoot = false;
    state.currentPath = path;
    state.currentGridGroup = null;

    if (repo != null) {
      _repo = repo;
      state.isRemotePath = true;
      final result = await repo.loadMangasInDir(Directory(path));
      if (result is Ok<List<Manga>>) {
        state.mangas = result.value;
      } else {
        state.mangas = [];
        Fluttertoast.showToast(msg: '加载远程漫画失败');
      }
      // Extract groups from manga data for remote paths
      _extractGroupsFromMangas();
    } else {
      _repo = Get.find<MangaRepository>();
      state.isRemotePath = false;
      state.mangas = localMangaService.settingPath2Mangas[path] ?? [];
      await _syncGroupsFromPath();
    }

    _applySort();
    storageService.write(_lastPathKey, path);
    update([bodyId, normalAppBarActionsId, appBarId]);
  }

  void _extractGroupsFromMangas() {
    final groupNames = state.mangas.map((m) => m.groupName).toSet().toList();
    if (groupNames.isEmpty) {
      state.groups = [Constants.defaultGroupName];
    } else {
      state.groups = groupNames;
      state.displayGroups.clear();
      state.displayGroups.addAll(groupNames);
    }
  }

  Future<void> _reloadRemoteMangas() async {
    final path = state.currentPath;
    if (path == null) return;
    final result = await _repo.loadMangasInDir(Directory(path));
    if (result is Ok<List<Manga>>) {
      state.mangas = result.value;
      _extractGroupsFromMangas();
      _applySort();
    } else {
      Fluttertoast.showToast(msg: '连接失败，请检查服务器是否在线');
    }
  }

  void backToRoot() {
    state.isAtRoot = true;
    state.isRemotePath = false;
    _repo = Get.find<MangaRepository>();
    storageService.remove(_lastPathKey);
    update([bodyId, normalAppBarActionsId, appBarId]);
  }

  void enterGridGroup(String groupName) {
    state.currentGridGroup = groupName;
    storageService.write(_lastGroupKey, groupName);
    update([bodyId, normalAppBarActionsId, appBarId]);
  }

  void backFromGridGroup() {
    state.currentGridGroup = null;
    storageService.remove(_lastGroupKey);
    update([bodyId, normalAppBarActionsId, appBarId]);
  }

  List<Manga> get mangasForCurrentGrid => state.currentGridGroup == null
      ? state.mangas
      : state.mangas
            .where((m) => m.groupName == state.currentGridGroup)
            .toList();

  Future<void> _syncGroupsFromPath() async {
    final path = state.currentPath;
    if (path == null) return;
    final result = await _repo.fetchGroups(path);
    if (result is Ok<List<GroupInfo>>) {
      if (result.value.isEmpty) {
        await _repo.addGroup(Constants.defaultGroupName, path);
        state.groups = [Constants.defaultGroupName];
      } else {
        state.groups = result.value.map((g) => g.name).toList();
        state.displayGroups.clear();
        for (final g in result.value) {
          if (g.isExpanded) state.displayGroups.add(g.name);
        }
      }
    } else {
      LogUtil.e('Failed to fetch groups for path $path',
          error: (result as Err).error);
    }
  }

  Future<void> handleAddGroupToPath(String name, String path) async {
    final result = await _repo.addGroup(name, path);
    if (result is Ok) {
      if (state.currentPath == path) state.groups.add(name);
      update([bodyId]);
    }
  }

  Future<void> handleRenameGroupInPath(
    String oldName, String newName, String path) async {
    await _repo.removeGroup(oldName, path);
    await _repo.addGroup(newName, path);
    final mangas = localMangaService.settingPath2Mangas[path] ?? [];
    final ids =
        mangas.where((m) => m.groupName == oldName).map((m) => m.id).toSet();
    final result = await _repo.moveMangasToGroup(ids, newName);
    if (result is Ok) {
      for (final m in mangas.where((m) => m.groupName == oldName)) {
        mangas[mangas.indexOf(m)] = m.copyWith(groupName: newName);
      }
      if (state.currentPath == path) {
        state.groups[state.groups.indexOf(oldName)] = newName;
        if (state.currentGridGroup == oldName) state.currentGridGroup = newName;
      }
      update([bodyId, appBarId]);
    }
  }

  Future<void> handleDeleteGroupInPath(String groupName, String path) async {
    if (state.toDefaultGroupOnceDelete) {
      final mangas = localMangaService.settingPath2Mangas[path] ?? [];
      final ids = mangas
          .where((m) => m.groupName == groupName)
          .map((m) => m.id)
          .toSet();
      await _repo.moveMangasToGroup(ids, Constants.defaultGroupName);
    } else {
      final mangas = localMangaService.settingPath2Mangas[path] ?? [];
      final toDelete = mangas.where((m) => m.groupName == groupName).toList();
      localMangaService.deleteMangas(toDelete);
    }
    await _repo.removeGroup(groupName, path);
    if (state.currentPath == path) {
      state.groups.remove(groupName);
      if (state.currentGridGroup == groupName) state.currentGridGroup = null;
    }
    update([bodyId, appBarId]);
  }

  Future<void> handleRenameGroup(String oldName, String newName) async {
    if (!state.groups.contains(oldName)) return;
    final path = state.currentPath;
    if (path == null) return;
    await _repo.removeGroup(oldName, path);
    await _repo.addGroup(newName, path);
    final result = await _repo.moveMangasToGroup(
      state.mangas
          .where((m) => m.groupName == oldName)
          .map((m) => m.id)
          .toSet(),
      newName,
    );
    if (result is Ok) {
      state.groups[state.groups.indexOf(oldName)] = newName;
      if (state.currentGridGroup == oldName) state.currentGridGroup = newName;
      for (final m in state.mangas.where((m) => m.groupName == oldName)) {
        state.mangas[state.mangas.indexOf(m)] =
            m.copyWith(groupName: newName);
      }
      update([bodyId, appBarId]);
    }
  }

  void toggleGroupExpand(int index) {
    final groupName = state.groups[index];
    if (state.displayGroups.contains(groupName)) {
      state.displayGroups.remove(groupName);
    } else {
      state.displayGroups.add(groupName);
    }
    _repo.updateGroupExpand(
      groupName, state.currentPath!, state.displayGroups.contains(groupName));
    update(['$groupIdPrefix::$groupName', '$mangasInGroupIdPrefix::$groupName']);
  }

  void toggleSelectMode() {
    if (state.isSelectMode) state.selectedMangaIds.clear();
    state.isSelectMode = !state.isSelectMode;
    Get.find<HomePageController>().toggleShowBottomBar();
    // Fire every individual GetBuilder so each item recomputes isSelected.
    // GetX batches the IDs into a single microtask — no per-call overhead.
    for (final m in mangasForCurrentGrid) {
      update(['$mangaIdPrefix::${m.id}']);
    }
    update([appBarId, bodyId]);
  }

  void openRandomManga() {
    final list = state.isSearchMode ? state.searchedMangas : state.mangas;
    if (list.isEmpty) return;
    handleMangaCardTap(list[Random().nextInt(list.length)]);
  }

  void openLastReadManga() {
    final list = state.isSearchMode ? state.searchedMangas : state.mangas;
    Manga? last;
    for (final m in list) {
      if (m.lastReadTime == null) continue;
      if (last == null || m.lastReadTime!.isAfter(last.lastReadTime!)) {
        last = m;
      }
    }
    if (last != null) {
      handleMangaCardTap(last);
    } else {
      Fluttertoast.showToast(msg: '暂无阅读记录');
    }
  }

  void handleSort(SortMode mode) {
    if (mode == SortMode.random) {
      _shuffleMangas();
      return;
    }
    if (state.sortMode == mode) {
      state.sortAscending = !state.sortAscending;
    } else {
      state.sortMode = mode;
      state.sortAscending = mode != SortMode.lastRead;
    }
    _applySort();
    _saveSort();
  }

  void _shuffleMangas() {
    state.mangas.shuffle(Random());
    state.sortMode = SortMode.random;
    state.sortAscending = false;
    _saveSort();
    update([bodyId]);
  }

  void _applySort() {
    int cmp(Manga a, Manga b) {
      return switch (state.sortMode) {
        SortMode.title => a.title.compareTo(b.title),
        SortMode.lastRead => (a.lastReadTime ?? DateTime(2000))
            .compareTo(b.lastReadTime ?? DateTime(2000)),
        SortMode.pageCount => a.pageCount.compareTo(b.pageCount),
        SortMode.random => 0,
      };
    }
    if (state.sortAscending) {
      state.mangas.sort(cmp);
    } else {
      state.mangas.sort((a, b) => cmp(b, a));
    }
    if (state.currentPath != null && !state.isRemotePath) {
      localMangaService.settingPath2Mangas[state.currentPath!] = state.mangas;
    }
    update([bodyId]);
  }

  void handleLongPressManga(Manga manga) {
    if (state.isRemotePath) return;
    if (state.selectedMangaIds.contains(manga.id)) {
      state.selectedMangaIds.remove(manga.id);
    } else {
      state.selectedMangaIds.add(manga.id);
    }
    toggleSelectMode();
  }

  void handleSelectManga(Manga manga) {
    if (state.selectedMangaIds.contains(manga.id)) {
      state.selectedMangaIds.remove(manga.id);
    } else {
      state.selectedMangaIds.add(manga.id);
    }
    if (state.selectedMangaIds.isEmpty) {
      toggleSelectMode();
      return;
    }
    update([appBarId, '$mangaIdPrefix::${manga.id}']);
  }

  void handleSelectAll() {
    final list = state.isSearchMode
        ? state.searchedMangas
        : state.currentGridGroup != null
            ? mangasForCurrentGrid
            : state.mangas;
    if (state.isSelectedAll || state.selectedMangaIds.length == list.length) {
      state.selectedMangaIds.clear();
    } else {
      state.selectedMangaIds.assignAll(list.map((e) => e.id));
    }
    update([appBarId, bodyId]);
  }

  void handleMangaCardTap(Manga manga) {
    final startIndex =
        readSetting.continueFromLastRead.value ? manga.lastReadPage : 0;
    Get.toNamed(Routes.reader,
        arguments: ReadInfo(
            mangaInfo: manga,
            pageCount: manga.pageCount,
            lastReadIndex: startIndex,
            repo: state.isRemotePath ? _repo : null));
  }

  Future<void> handleMoveMangasToGroup(String groupName) async {
    if (state.selectedMangaIds.isEmpty) {
      Fluttertoast.showToast(msg: '请选择漫画');
      return;
    }
    if (!state.groups.contains(groupName)) {
      final added = await _repo.addGroup(groupName, state.currentPath!);
      if (added is Ok) state.groups.add(groupName);
    }
    final result =
        await _repo.moveMangasToGroup(state.selectedMangaIds, groupName);
    if (result is Err) {
      Fluttertoast.showToast(msg: result.message);
      return;
    }
    _updateLocalMangasGroup(state.selectedMangaIds, groupName);
    state.selectedMangaIds.clear();
    toggleSelectMode();
    update([bodyId]);
    Get.back();
  }

  void _updateLocalMangasGroup(Set<MangaId> ids, String groupName) {
    for (var i = 0; i < state.mangas.length; i++) {
      if (ids.contains(state.mangas[i].id)) {
        state.mangas[i] = state.mangas[i].copyWith(groupName: groupName);
      }
    }
  }

  Future<void> handleAddGroup(String? groupName) async {
    if (groupName == null || groupName.isEmpty) {
      Fluttertoast.showToast(msg: '分组名不能为空！');
      return;
    }
    if (groupName.length > 20) {
      Fluttertoast.showToast(msg: '分组名不能超过20个字符');
      return;
    }
    final result = await _repo.addGroup(groupName, state.currentPath!);
    if (result is Err) {
      Fluttertoast.showToast(msg: result.message);
      return;
    }
    if (!state.groups.contains(groupName)) state.groups.add(groupName);
    update([bodyId]);
    Get.back();
  }

  void handleChangeDeleteGroupOption(bool toDefaultGroup) {
    state.toDefaultGroupOnceDelete = toDefaultGroup;
    update([deleteGroupDialogId]);
  }

  Future<void> handleDeleteGroup(String groupName) async {
    if (state.toDefaultGroupOnceDelete) {
      await _repo.resetMangasToDefaultGroup(groupName, state.currentPath);
      for (var i = 0; i < state.mangas.length; i++) {
        if (state.mangas[i].groupName == groupName) {
          state.mangas[i] =
              state.mangas[i].copyWith(groupName: Constants.defaultGroupName);
        }
      }
    } else {
      return;
    }
    final result = await _repo.removeGroup(groupName, state.currentPath!);
    if (result is Err) {
      Fluttertoast.showToast(msg: result.message);
      return;
    }
    state.groups.remove(groupName);
    update([bodyId]);
    Get.back();
  }

  Future<void> refreshMangas() async {
    if (state.currentPath == null) return;
    state.isRefreshing = true;
    update([refreshProgressId]);

    if (state.isRemotePath) {
      final result = await _repo.refreshMangasInDir(Directory(state.currentPath!));
      if (result is Ok) {
        _reloadRemoteMangas();
      }
    } else {
      await localMangaService.refreshMangasInDir(Directory(state.currentPath!));
      state.mangas =
          localMangaService.settingPath2Mangas[state.currentPath] ?? [];
      _syncGroupsFromPath();
      _applySort();
    }

    state.isRefreshing = false;
    update([bodyId, refreshProgressId]);
  }

  Future<void> handleDeleteManga(Manga manga) async {
    final result = await _repo.deleteManga(manga);
    if (result is Err) {
      Fluttertoast.showToast(msg: result.message);
      return;
    }
    state.mangas.removeWhere((m) => m.id == manga.id);
    update([bodyId]);
    Get.back();
  }

  // ── LAN server methods ──

  void addConnectedServer(DiscoveredServer server) {
    if (!state.connectedServers.contains(server)) {
      state.connectedServers.add(server);
      update([bodyId]);
    }
  }

  void removeConnectedServer(DiscoveredServer server) {
    state.connectedServers.remove(server);
    update([bodyId]);
  }

  bool get isRemoteRepo => _repo.isReadOnly;

  // ── Delete methods ──

  Future<void> handleDeleteMangas() async {
    final mangasToDelete = state.mangas
        .where((m) => state.selectedMangaIds.contains(m.id))
        .toList();
    final result = await _repo.deleteMangas(mangasToDelete);
    if (result is Err) {
      Fluttertoast.showToast(msg: result.message);
      return;
    }
    state.mangas.removeWhere((m) => state.selectedMangaIds.contains(m.id));
    state.selectedMangaIds.clear();
    toggleSelectMode();
    update([bodyId]);
    Get.back();
  }
}
