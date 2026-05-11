import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:manga_reader/mixin/scroll_handler.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/settings/path_setting.dart';
import 'package:manga_reader/core/utils/file_util.dart';
import 'package:manga_reader/core/utils/log_util.dart';
import 'package:manga_reader/widgets/progress_view.dart';
import 'package:manga_reader/widgets/styled_menu.dart';
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
  final String mergeProgressId = 'mergeProgressId';

  void selectDir() async {
    final dir = await FileUtil.selectDir();
    if (dir != null) {
      state.selectedDir = dir;
      state.selectedMangas.clear();
      state.selectedMangaIndexes.clear();
      await _loadMangaList();
      update([selectDirId, bodyId, titleId]);
    }
  }

  Future<void> _loadMangaList() async {
    state.mangas = [];
    state.isLoadingMangas = true;
    update([bodyId]);
    final all = await localMangaService.getMangasInDir(state.selectedDir!);
    state.mangas = all;
    state.isLoadingMangas = false;
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
    update([titleId, cancelButtonId]);
  }

  void handleLongPressManga(BuildContext context, Manga manga) {
    StyledActionSheet.show(
      context: context,
      actions: [
        StyledAction(
          label: '复制漫画名',
          onPressed: () => FileUtil.copyMangaName(manga.title),
        ),
      ],
    );
  }

  void cancelSelected() {
    final idsNeedUpdate = _getSelectedMangaItemIds();
    state.selectedMangas.clear();
    state.selectedMangaIndexes.clear();
    update([...idsNeedUpdate, titleId, cancelButtonId]);
  }

  List<String> _getSelectedMangaItemIds() {
    return state.selectedMangaIndexes
        .map((i) => '$mangaListTileIdPrefix::$i')
        .toList();
  }

  Future<void> handleTapStartMerge() async {
    if (state.selectedDir == null || state.outputDir == null) {
      Fluttertoast.showToast(msg: '请选择目录');
      return;
    }
    if (state.targetDirNameController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: '请输入合集名');
      return;
    }
    final targetName = state.targetDirNameController.text.trim();
    final outputPath = p.join(state.outputDir!.path, targetName);
    final finalPath = state.outputAsZip ? '$outputPath.zip' : outputPath;
    if (Directory(finalPath).existsSync() || File(finalPath).existsSync()) {
      Fluttertoast.showToast(msg: '目标路径已存在，请重新输入合集名');
      return;
    }
    if (state.selectedMangas.isEmpty) {
      Fluttertoast.showToast(msg: '请选择要合并的漫画');
      Get.back();
      return;
    }

    state.isMerging = true;
    state.mergeProgress = 0;
    state.mergeTotal = 0;
    Get.back();
    Get.dialog(_buildMergeProgressDialog(), barrierDismissible: false);

    final mangas = state.selectedMangas;
    try {
      final outputManga = await localMangaService.mergeMangas(
        mangas,
        Directory(outputPath),
        outputAsZip: state.outputAsZip,
        onProgress: (current, total) {
          state.mergeProgress = current;
          state.mergeTotal = total;
          update([mergeProgressId]);
        },
      );
      Fluttertoast.showToast(msg: '合并成功');
      _onMergeCompleted(mangas, outputManga);
    } catch (e) {
      LogUtil.e('合并失败', error: e);
      Fluttertoast.showToast(msg: '合并失败');
      _onMergeCompleted(mangas, null);
    }
  }

  void _onMergeCompleted(List<Manga> selectedMangas, Manga? outputManga) {
    if (outputManga != null) {
      if (state.deleteSourceMangas) {
        localMangaService.deleteMangas(selectedMangas, showToast: false);
        if (pathSetting.paths.contains(state.selectedDir?.path)) {
          localMangaService.settingPath2Mangas[state.selectedDir?.path]
              ?.removeWhere((m) => selectedMangas.contains(m));
        }
        state.mangas.removeWhere((m) => selectedMangas.contains(m));
      }
      if (pathSetting.paths.contains(state.outputDir?.path)) {
        localMangaService.settingPath2Mangas[state.outputDir?.path]
          ?..add(outputManga)
          ..sort((a, b) => FileUtil.naturalCompare(a.title, b.title));
      }
      state.hasMerged = true;
    }
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

  void handleToggleOutputAsZip(bool? value) {
    state.outputAsZip = value ?? false;
    update([mergeStartDialogId]);
  }

  Widget _buildMergeProgressDialog() {
    return GetBuilder<MergeMangasPageController>(
      id: mergeProgressId,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: .circular(16)),
          title: const Text('正在合并...'),
          content: ProgressView(
            current: state.mergeProgress,
            total: state.mergeTotal,
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          ),
        );
      },
    );
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
}
