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
  final String mangaItemIdPrefix = 'archiveMangaItem';

  Future<void> selectDir() async {
    final dir = await FileUtil.selectDir();
    if (dir != null) {
      state.selectedDir = dir;
      state.selectedMangas.clear();
      await _loadMangaList();
      update([bodyId, titleId]);
    }
  }

  Future<void> _loadMangaList() async {
    state.mangas = [];
    state.isLoadingMangas = true;
    update([bodyId]);
    final all = await localMangaService.getMangasInDir(state.selectedDir!);
    state.mangas = all.where((m) => !localMangaService.isZipFile(m.path)).toList();
    state.isLoadingMangas = false;
  }

  void toggleSelection(Manga manga) {
    if (state.selectedMangas.contains(manga)) {
      state.selectedMangas.remove(manga);
    } else {
      state.selectedMangas.add(manga);
    }
    update([titleId, '$mangaItemIdPrefix::${manga.id}']);
  }

  void clearSelection() {
    final ids = state.selectedMangas
        .map((m) => '$mangaItemIdPrefix::${m.id}')
        .toList();
    state.selectedMangas.clear();
    update([...ids, titleId]);
  }

  Future<int> startArchive() async {
    if (state.selectedMangas.isEmpty || state.selectedDir == null) return 0;

    state.isWorking = true;
    state.progress = 0;
    state.total = state.selectedMangas.length;
    update([bodyId]);

    final count = await localMangaService.archiveMangasInPlace(
      state.selectedMangas.toList(),
      onProgress: (c, t) {
        state.progress = c;
        state.total = t;
        update([bodyId]);
      },
    );

    state.isWorking = false;
    state.selectedMangas.clear();
    await _loadMangaList();
    update([bodyId, titleId]);
    Fluttertoast.showToast(msg: '归档完成：$count 部');
    return count;
  }
}
