import 'package:get/get.dart';
import 'package:manga_reader/core/repository/manga_repository.dart';
import 'package:manga_reader/models/result.dart';

import 'reading_stats_page_state.dart';

class ReadingStatsPageController extends GetxController {
  final state = ReadingStatsPageState();
  static const String bodyId = 'readingStatsBodyId';

  @override
  void onReady() {
    super.onReady();
    loadStats();
  }

  Future<void> loadStats() async {
    state.isLoading = true;
    update([bodyId]);
    final result = await Get.find<MangaRepository>().getReadingStats();
    if (result is Ok<ReadingStats>) {
      state.stats = result.value;
    }
    state.isLoading = false;
    update([bodyId]);
  }
}
