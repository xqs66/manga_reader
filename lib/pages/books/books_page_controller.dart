import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart' hide Value;
import 'package:manga_reader/database/dao/group_dao.dart';
import 'package:manga_reader/database/dao/manga_dao.dart';
import 'package:manga_reader/database/database.dart';
import 'package:manga_reader/database/table/group.dart';
import 'package:manga_reader/mixin/scroll_handler.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/models/read_info.dart';
import 'package:manga_reader/pages/books/books_page_state.dart';
import 'package:manga_reader/pages/home_page_controller.dart';
import 'package:manga_reader/routes/routes.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:drift/drift.dart';
import 'package:manga_reader/shared/utils/log_util.dart';

class BooksPageController extends GetxController with ScrollHandler {
  final state = BooksPageState();

  @override
  ScrollState get scrollState => state;

  final appBarId = 'appBarId';
  final bottomBarId = 'bottomBarId';
  final bodyId = 'bodyId';
  final popUpMenuId = 'popUpMenuId';
  final mangaIdPrefix = 'Manga';
  final groupidPrefix = 'Group';
  final mangasInGroupIdPrefix = 'MangasInGroup';

  @override
  void onInit() async {
    super.onInit();

    final groups = await GroupDao.selectAllGroups();
    final expandedGroups = groups.where((group) => group.isExpanded);
    state.groups = groups.map((group) => group.groupName).toList();

    state.displayGroups.addAll(expandedGroups.map((group) => group.groupName));
  }

  void enterMangaDir(String path) {
    state.isAtRoot = false;
    state.currentPath = path;
    state.books = localMangaService.mangasInLocalSettingPaths[path] ?? [];
    update([bodyId, popUpMenuId]);
  }

  void back2Root() {
    state.isAtRoot = true;
    update([bodyId, popUpMenuId]);
  }

  void toggleGroupExpand(int index) {
    final groupName = state.groups[index];
    if (state.displayGroups.contains(groupName)) {
      state.displayGroups.remove(groupName);
      GroupDao.updateGroup(groupName, GroupCompanion(isExpanded: Value(false)));
    } else {
      state.displayGroups.add(groupName);
      GroupDao.updateGroup(groupName, GroupCompanion(isExpanded: Value(true)));
    }
    update([
      '$groupidPrefix::$groupName',
      '$mangasInGroupIdPrefix::$groupName',
    ]);
  }

  void toggleSelectMode() {
    if (state.isSelectMode) {
      state.selectedMangaIds.clear();
    }
    state.isSelectMode = !state.isSelectMode;
    Get.find<HomePageController>().toggleShowBottomBar();
    update([appBarId, bottomBarId]);
  }

  void handleLongPressManga(Manga manga) {
    state.selectedMangaIds.contains(manga.id)
        ? state.selectedMangaIds.remove(manga.id)
        : state.selectedMangaIds.add(manga.id);
    toggleSelectMode();
  }

  void handleSelectManga(Manga manga) {
    state.selectedMangaIds.contains(manga.id)
        ? state.selectedMangaIds.remove(manga.id)
        : state.selectedMangaIds.add(manga.id);

    if (state.selectedMangaIds.isEmpty) {
      toggleSelectMode();
    }
    update([appBarId, '$mangaIdPrefix::${manga.id}']);
  }

  void handleSelectAll() {
    state.selectedMangaIds.assignAll(state.books.map((e) => e.id));
    update([appBarId, bodyId]);
  }

  void handleMangaCardTap(Manga manga) {
    Get.toNamed(
      Routes.reader,
      arguments: ReadInfo(
        mangaInfo: manga,
        images: localMangaService.getMangaImages(manga),
        pageCount: manga.pageCount,
      ),
    );
  }

  void handleMoveMangas2Group(String groupName) async {
    if (state.selectedMangaIds.isEmpty) {
      Fluttertoast.showToast(msg: '请选择漫画');
      return;
    }

    if (!state.groups.contains(groupName)) {
      GroupDao.insertGroup(groupName);
      state.groups.add(groupName);
    }
    MangaDao.updateMangas(
          state.selectedMangaIds
              .map(
                (id) =>
                    MangaCompanion(id: Value(id), groupName: Value(groupName)),
              )
              .toList(),
        )
        .then((_) {
          Fluttertoast.showToast(msg: '改变分组成功');
        })
        .catchError((e) {
          LogUtil.e('改变分组失败', error: e);
          Fluttertoast.showToast(msg: '改变分组失败');
        });
    for (var manga in state.books) {
      if (state.selectedMangaIds.contains(manga.id)) {
        manga.groupName = groupName;
      }
    }
    state.selectedMangaIds.clear();
    toggleSelectMode();
    update([bodyId]);

    Get.back();
  }

  void handleAddGroup(String? groupName) {
    if (groupName == null) {
      Fluttertoast.showToast(msg: '分组名不能为空！');
      return;
    }
    state.groups.add(groupName);
    GroupDao.insertGroup(groupName)
        .then((_) {
          Fluttertoast.showToast(msg: '添加分组成功');
        })
        .catchError((e) {
          LogUtil.e('添加分组失败', error: e);
          Fluttertoast.showToast(msg: '添加分组失败');
        });
    update([bodyId]);
  }

  Future<void> refreshMangas() async {
    await localMangaService.refreshMangasInDir(Directory(state.currentPath));
    state.books =
        localMangaService.mangasInLocalSettingPaths[state.currentPath] ?? [];
    update([bodyId]);
  }

  Future<void> handleDeleteManga(Manga manga) async {
    localMangaService.deleteManga(manga);
    state.books.remove(manga);
    update([bodyId]);
    Get.back();
  }

  Future<void> handleDeleteMangas() async {
    localMangaService.deleteMangas(state.selectedMangas);
    state.selectedMangaIds.forEach((id) {
      state.books.removeWhere((manga) => manga.id == id);
    });
    update([bodyId]);
    Get.back();
  }
}
