import 'package:get/get.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/shared/utils/file_util.dart';
import 'package:manga_reader/shared/utils/log_util.dart';

import 'merge_mangas_page_state.dart';

class MergeMangasPageController extends GetxController {
  final state = MergeMangasPageState();
  final String bodyId = 'bodyId';
  final String selectDirId = 'selectDirId';
  final String selectOutputDirId = 'selectOutputDirId';
  final String mangaListTileIdPrefix = 'mangaListTile';
  final String titleId = 'titleId';
  final String cancelButtonId = 'cancelButtonId';

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
    if (state.selectedMangaPaths.contains(manga.path)) {
      final idsNeedUpdate = _getSelectedMangaItemIds();
      state.selectedMangaPaths.remove(manga.path);
      state.selectedMangaIndexes.remove(index);
      update(idsNeedUpdate);
    } else {
      state.selectedMangaPaths.add(manga.path);
      state.selectedMangaIndexes.add(index);
      update(['$mangaListTileIdPrefix::$index']);
    }
    update([titleId, cancelButtonId]);
  }

  void cancelSelected() {
    final idsNeedUpdate = _getSelectedMangaItemIds();
    state.selectedMangaPaths.clear();
    state.selectedMangaIndexes.clear();
    update([...idsNeedUpdate, titleId, cancelButtonId]);
  }

  List<String> _getSelectedMangaItemIds() {
    return state.selectedMangaIndexes
        .map((index) => '$mangaListTileIdPrefix::$index')
        .toList();
  }
}
