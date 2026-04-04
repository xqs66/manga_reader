import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:manga_reader/mixin/scroll_handler.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/pages/books/books_page_controller.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/settings/path_setting.dart';
import 'package:manga_reader/shared/utils/file_util.dart';
import 'package:manga_reader/shared/utils/log_util.dart';
import 'package:manga_reader/wigets/manga_list_tile_card.dart';
import 'package:path/path.dart' as p;

import 'merge_mangas_page_state.dart';

class MergeMangasPageController extends GetxController with ScrollHandler {
  @override
  ScrollState get scrollState => state;

  final state = MergeMangasPageState();

  final String bodyId = 'bodyId';
  final String mangasId = 'mangasId';
  final String selectDirId = 'selectDirId';
  final String selectOutputDirId = 'selectOutputDirId';
  final String mangaListTileIdPrefix = 'mangaListTile';
  final String titleId = 'titleId';
  final String cancelButtonId = 'cancelButtonId';
  final String mergeStartDialogId = 'mergeStartDialogId';

  void selectDir() async {
    final dir = await FileUtil.selectDir();
    if (dir != null) {
      state.selectedDir = dir;
      update([selectDirId, bodyId, titleId]);
    }
  }

  void selectOutputDir() async {
    final dir = await FileUtil.selectDir();
    if (dir != null) {
      state.outputDir = dir;
      update([selectOutputDirId]);
    }
  }

  void toggleMangaSelection(int index, Manga manga) {
    if (state.selectedMangas.contains(manga)) {
      final idsNeedUpdate = _getSelectedMangaItemIds();
      state.selectedMangas.remove(manga);
      state.selectedMangaIndexes.remove(index);
      update(idsNeedUpdate);
    } else {
      state.selectedMangas.add(manga);
      state.selectedMangaIndexes.add(index);
      update(['$mangaListTileIdPrefix::$index']);
    }
    LogUtil.d('当前state:${state.isScrolling}', tag: '测试');
    update([titleId, cancelButtonId]);
  }

  void handleLongPressManga(BuildContext context, List<SheetAction> actions) {
    LongPressActionSheet.show(context: context, actions: actions);
  }

  void cancelSelected() {
    final idsNeedUpdate = _getSelectedMangaItemIds();
    state.selectedMangas.clear();
    state.selectedMangaIndexes.clear();
    update([...idsNeedUpdate, titleId, cancelButtonId]);
  }

  List<String> _getSelectedMangaItemIds() {
    return state.selectedMangaIndexes
        .map((index) => '$mangaListTileIdPrefix::$index')
        .toList();
  }

  void handleTapStartMerge() async {
    late final Manga? outputManga;

    if (state.selectedDir == null || state.outputDir == null) {
      Fluttertoast.showToast(msg: '请选择目录');
      return;
    }
    if (state.targetDirNameController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: '请输入目录名');
      return;
    }
    if (state.selectedMangas.isEmpty) {
      Fluttertoast.showToast(msg: '请选择要合并的漫画');
      Get.back();
      return;
    }

    state.isMerging = true;
    Get.back();
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    final mangas = state.selectedMangas;
    final outputDir = p.join(
      state.outputDir!.path,
      state.targetDirNameController.text.trim(),
    );

    localMangaService
        .mergeMangas(mangas, Directory(outputDir))
        .then((result) {
          outputManga = result;
          Fluttertoast.showToast(msg: '合并成功');
        })
        .catchError((e) {
          LogUtil.e('合并失败', error: e);
          Fluttertoast.showToast(msg: '合并失败');
        })
        .whenComplete(() {
          handleMergeCompeleted(mangas, outputManga);
        });
  }

  void handleMergeCompeleted(List<Manga> selectedMangas, Manga? outputManga) {
    if (outputManga == null) {
      return;
    }
    if (state.deleteSourceMangas) {
      localMangaService.deleteMangas(selectedMangas, showToast: false);
      if (pathSetting.paths.contains(state.selectedDir?.path)) {
        localMangaService.mangasInLocalSettingPaths[state.selectedDir?.path]
            ?.removeWhere((manga) => selectedMangas.contains(manga));
      }
      state.mangas.removeWhere((manga) => selectedMangas.contains(manga));
    }
    if (pathSetting.paths.contains(state.outputDir?.path)) {
      localMangaService.mangasInLocalSettingPaths[state.outputDir?.path]
        ?..add(outputManga)
        ..sort(
          (mangaA, mangaB) =>
              FileUtil.naturalCompare(mangaA.title, mangaB.title),
        );
    }
    if (state.outputDir?.path == state.selectedDir?.path) {
      state.mangas
        ..add(outputManga)
        ..sort(
          (mangaA, mangaB) =>
              FileUtil.naturalCompare(mangaA.title, mangaB.title),
        );
    }
    state.hasMerged = true;
    state.isMerging = false;
    state.targetDirNameController.clear();
    state.selectedMangaIndexes.clear();
    state.selectedMangas.clear();
    update([mangasId, titleId, cancelButtonId]);
    Get.back();
  }

  void handleToggleDeleteSource(bool? value) {
    state.deleteSourceMangas = value ?? false;
    update([mergeStartDialogId]);
  }

  @override
  void handleScrollStart(ScrollStartNotification notification) {
    delayedHandleScrollStart(notification);
  }

  @override
  void handleScrollFinish(ScrollEndNotification notification) {
    handleEndWithDelayedStart(notification);
    if (!state.isScrolling) {
      update([mangasId]);
    }
  }

  @override
  void onClose() {
    if (state.hasMerged) {
      final List<Future> futures = [];
      final controller = Get.find<BooksPageController>();
      if (pathSetting.paths.contains(state.selectedDir?.path)) {
        futures.add(localMangaService.refreshMangasInDir(state.selectedDir!));
      }
      if (pathSetting.paths.contains(state.outputDir?.path)) {
        futures.add(localMangaService.refreshMangasInDir(state.outputDir!));
      }
      Future.wait(futures).then((_) => controller.refreshMangas());
    }
    super.onClose();
  }
}
