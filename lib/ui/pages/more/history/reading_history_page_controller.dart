import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:manga_reader/core/repository/manga_repository.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/models/read_info.dart';
import 'package:manga_reader/models/result.dart';
import 'package:manga_reader/routes/routes.dart';
import 'package:manga_reader/service/local_manga_service.dart';

import 'reading_history_page_state.dart';

class ReadingHistoryPageController extends GetxController {
  final state = ReadingHistoryPageState();
  static const String bodyId = 'readingHistoryBodyId';

  @override
  void onReady() {
    super.onReady();
    loadHistory();
  }

  Future<void> loadHistory() async {
    state.isLoading = true;
    update([bodyId]);
    final result = await Get.find<MangaRepository>().getReadingHistory();
    if (result is Ok<List<Manga>>) {
      // Prefer the in-memory manga when available: it has the real filesystem
      // path and a fresh cover path (DB covers go stale when the temp cache
      // or the cover image is deleted).
      state.historyItems =
          result.value.map((m) => _findReal(m) ?? m).toList();
    }
    state.isLoading = false;
    update([bodyId]);
  }

  Manga? _findReal(Manga manga) {
    for (final list in localMangaService.settingPath2Mangas.values) {
      final real = list.where((m) => m.id == manga.id).firstOrNull;
      if (real != null) return real;
    }
    return null;
  }

  Future<void> openManga(Manga manga) async {
    // The manga from DB query has a fake path (the MD5 id). Look up the real
    // manga from the in-memory cache to get the actual filesystem path so the
    // reader can load images from disk.
    final real = _findReal(manga);
    if (real == null) {
      Fluttertoast.showToast(msg: '漫画文件不存在，可能已被移动或删除');
      return;
    }

    await Get.toNamed(Routes.reader, arguments: ReadInfo(
      mangaInfo: real,
      pageCount: real.pageCount,
      lastReadIndex: real.lastReadPage,
    ));
    // Refresh progress after returning from reader
    loadHistory();
  }
}
