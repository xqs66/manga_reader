import 'dart:io';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/shared/utils/file_util.dart';
import 'package:manga_reader/shared/utils/log_util.dart';
import 'package:path/path.dart' as p;

import 'merge_mangas_page_state.dart';

class MergeMangasPageController extends GetxController {
  final state = MergeMangasPageState();
  final String bodyId = 'bodyId';
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
    update([titleId, cancelButtonId]);
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
    update([mergeStartDialogId]);

    final mangas = state.selectedMangas;
    final outputDir = p.join(
      state.outputDir!.path,
      state.targetDirNameController.text.trim(),
    );

    localMangaService
        .mergeMangas(mangas, Directory(outputDir))
        .then((_) {
          Fluttertoast.showToast(msg: '合并成功');
        })
        .catchError((e) {
          LogUtil.e('合并失败', error: e);
          Fluttertoast.showToast(msg: '合并失败');
        })
        .whenComplete(() {
          state.isMerging = false;
          update([mergeStartDialogId]);
          Get.back();
        });
  }
}
