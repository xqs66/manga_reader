import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/shared/utils/file_util.dart';

import 'archive_mangas_state.dart';

class ArchiveMangasController extends GetxController {
  final state = ArchiveMangasState();

  final String bodyId = 'bodyId';
  final String titleId = 'titleId';

  Future<void> selectDir() async {
    final dir = await FileUtil.selectDir();
    if (dir != null) {
      state.selectedDir = dir;
      update([bodyId, titleId]);
    }
  }

  Future<void> selectOutputDir() async {
    final dir = await FileUtil.selectDir();
    if (dir != null) {
      state.outputDir = dir;
      update([bodyId]);
    }
  }

  void toggleSelection(Manga manga) {
    if (state.selectedMangas.contains(manga)) {
      state.selectedMangas.remove(manga);
    } else {
      state.selectedMangas.add(manga);
    }
    update([bodyId, titleId]);
  }

  void clearSelection() {
    state.selectedMangas.clear();
    update([bodyId, titleId]);
  }

  void setDeleteSource(bool value) {
    state.deleteSource = value;
  }

  Future<int> startArchive() async {
    if (state.selectedMangas.isEmpty) return 0;

    state.isWorking = true;
    state.progress = 0;
    state.total = state.selectedMangas.length;
    update([bodyId]);

    final count = await localMangaService.archiveMangas(
      state.selectedMangas.toList(),
      state.outputDir!,
      deleteSource: state.deleteSource,
      onProgress: (c, t) {
        state.progress = c;
        state.total = t;
        update([bodyId]);
      },
    );

    state.isWorking = false;
    state.selectedMangas.clear();
    update([bodyId, titleId]);
    Fluttertoast.showToast(msg: '归档完成：$count 部');
    return count;
  }
}
