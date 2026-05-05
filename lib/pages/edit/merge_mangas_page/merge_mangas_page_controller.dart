import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:manga_reader/mixin/scroll_handler.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/settings/path_setting.dart';
import 'package:manga_reader/shared/utils/file_util.dart';
import 'package:manga_reader/shared/utils/log_util.dart';
import 'package:manga_reader/widgets/manga_list_tile_card.dart';
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
    final outputPath = p.join(
      state.outputDir!.path,
      state.targetDirNameController.text.trim(),
    );
    if (Directory(outputPath).existsSync()) {
      Fluttertoast.showToast(msg: '目标目录下存在同名目录，请重新输入合集名');
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

  Widget _buildMergeProgressDialog() {
    return GetBuilder<MergeMangasPageController>(
      id: mergeProgressId,
      builder: (_) {
        final progress = state.mergeTotal > 0
            ? state.mergeProgress / state.mergeTotal
            : 0.0;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: .circular(16)),
          title: const Text('正在合并...'),
          content: Column(
            mainAxisSize: .min,
            children: [
              ClipRRect(
                borderRadius: .circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${state.mergeProgress} / ${state.mergeTotal}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF616161)),
              ),
            ],
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
