import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:manga_reader/core/repository/manga_repository.dart';
import 'package:manga_reader/service/storage_service.dart';
import 'package:manga_reader/core/result.dart';
import 'package:manga_reader/mixin/scroll_handler.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/models/manga_id.dart';
import 'package:manga_reader/models/read_info.dart';
import 'package:manga_reader/pages/books/mangas_page_state.dart';
import 'package:manga_reader/pages/home_page_controller.dart';
import 'package:manga_reader/routes/routes.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/settings/read_setting.dart';
import 'package:manga_reader/core/constants/constants.dart';

class MangasPageController extends GetxController with ScrollHandler {
  final state = MangasPageState();
  final MangaRepository _repo;

  MangasPageController({MangaRepository? repo})
      : _repo = repo ?? Get.find<MangaRepository>();

  @override
  ScrollState get scrollState => state;

  final appBarId = 'appBarId';
  final bottomBarId = 'bottomBarId';
  final bodyId = 'bodyId';
  final normalAppBarActionsId = 'normalAppBarActionsId';
  final mangaIdPrefix = 'Manga';
  final groupIdPrefix = 'Group';
  final mangasInGroupIdPrefix = 'MangasInGroup';
  final deleteGroupDialogId = 'deleteGroupDialogId';

  Timer? searchDebounceTimer;

  static const _lastPathKey = 'last_source_path';
  bool _autoRestoreAttempted = false;

  @override
  void onInit() {
    super.onInit();
    ever(readSetting.bookshelfLayout, (_) {
      state.currentGridGroup = null;
      update([bodyId, appBarId]);
    });
  }

  void tryAutoRestore() {
    if (_autoRestoreAttempted || !state.isAtRoot) return;
    _autoRestoreAttempted = true;
    final path = storageService.read<String>(_lastPathKey);
    if (path == null) return;
    if (!localMangaService.settingPath2Mangas.containsKey(path)) {
      // Data may not be loaded yet; retry once
      _autoRestoreAttempted = false;
      Future.delayed(const Duration(seconds: 1), () => tryAutoRestore());
      return;
    }
    enterMangaDir(path);
  }

  void handlePopNext() {
    state.mangas =
        localMangaService.settingPath2Mangas[state.currentPath] ?? [];
    _syncGroupsFromPath();
    update([bodyId]);
  }

  void enterMangaDir(String path) async {
    state.isAtRoot = false;
    state.currentPath = path;
    state.mangas = localMangaService.settingPath2Mangas[path] ?? [];
    await _syncGroupsFromPath();
    storageService.write(_lastPathKey, path);
    update([bodyId, normalAppBarActionsId, appBarId]);
  }

  void backToRoot() {
    state.isAtRoot = true;
    storageService.remove(_lastPathKey);
    update([bodyId, normalAppBarActionsId, appBarId]);
  }

  void toggleLayoutMode() {
    final next = readSetting.bookshelfLayout.value == BookshelfLayout.list
        ? BookshelfLayout.grid
        : BookshelfLayout.list;
    readSetting.saveBookshelfLayout(next);
    state.currentGridGroup = null;
    update([bodyId, normalAppBarActionsId, appBarId]);
  }

  void enterGridGroup(String groupName) {
    state.currentGridGroup = groupName;
    update([bodyId, normalAppBarActionsId, appBarId]);
  }

  void backFromGridGroup() {
    state.currentGridGroup = null;
    update([bodyId, normalAppBarActionsId, appBarId]);
  }

  List<Manga> get mangasForCurrentGrid =>
      state.currentGridGroup == null
          ? state.mangas
          : state.mangas.where((m) => m.groupName == state.currentGridGroup).toList();

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
      groupName,
      state.currentPath!,
      state.displayGroups.contains(groupName),
    );
    update([
      '$groupIdPrefix::$groupName',
      '$mangasInGroupIdPrefix::$groupName',
    ]);
  }

  void toggleSelectMode() {
    if (state.isSelectMode) state.selectedMangaIds.clear();
    state.isSelectMode = !state.isSelectMode;
    Get.find<HomePageController>().toggleShowBottomBar();
    update([appBarId, bottomBarId]);
  }

  void toggleSearchMode() {
    state.isSearchMode = !state.isSearchMode;
    if (!state.isSearchMode) {
      state.searchTextController.clear();
      state.searchedMangas.clear();
    } else {
      state.searchedMangas.assignAll(state.mangas);
    }
    update([appBarId, bodyId]);
  }

  void handleSearch(String keyword) {
    searchDebounceTimer?.cancel();
    searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      state.searchedMangas.assignAll(
        keyword.isEmpty
            ? state.mangas
            : state.mangas.where((m) => m.title.contains(keyword)).toList(),
      );
      update([bodyId]);
    });
  }

  void handleLongPressManga(Manga manga) {
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
    if (state.selectedMangaIds.isEmpty) toggleSelectMode();
    update([appBarId, '$mangaIdPrefix::${manga.id}']);
  }

  void handleSelectAll() {
    if (state.isSelectedAll) {
      state.selectedMangaIds.clear();
    } else {
      state.selectedMangaIds.assignAll(
        (state.isSearchMode ? state.searchedMangas : state.mangas).map((e) => e.id),
      );
    }
    update([appBarId, bodyId]);
  }

  void handleMangaCardTap(Manga manga) {
    final startIndex = readSetting.continueFromLastRead.value ? manga.lastReadPage : 0;
    Get.toNamed(
      Routes.reader,
      arguments: ReadInfo(
        mangaInfo: manga,
        images: localMangaService.getMangaImages(manga),
        pageCount: manga.pageCount,
        lastReadIndex: startIndex,
      ),
    );
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
    final result = await _repo.moveMangasToGroup(state.selectedMangaIds, groupName);
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
    if (!state.groups.contains(groupName)) {
      state.groups.add(groupName);
    }
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

  final String refreshProgressId = 'refreshProgressId';

  Future<void> refreshMangas() async {
    if (state.currentPath == null) return;
    state.isRefreshing = true;
    update([refreshProgressId]);
    await localMangaService.refreshMangasInDir(Directory(state.currentPath!));
    state.mangas =
        localMangaService.settingPath2Mangas[state.currentPath] ?? [];
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

  Future<void> handleDeleteMangas() async {
    final mangasToDelete =
        state.mangas.where((m) => state.selectedMangaIds.contains(m.id)).toList();
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

  @override
  void handleScrollStart(ScrollStartNotification notification) {
    delayedHandleScrollStart(notification);
  }

  @override
  void handleScrollFinish(ScrollEndNotification notification) {
    handleEndWithDelayedStart(notification);
    if (!state.isScrolling) update([bodyId]);
  }

  @override
  void onClose() {
    searchDebounceTimer?.cancel();
    super.onClose();
  }
}
