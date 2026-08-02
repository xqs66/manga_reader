import 'package:drift/drift.dart' show OrderingMode, OrderingTerm, Variable;
import 'package:manga_reader/core/repository/manga_repository.dart';
import 'package:manga_reader/database/database.dart';

class MangaDao {
  static Future<int> insertManga(MangaCompanion mangaCompanion) {
    return appDb.into(appDb.manga).insertOnConflictUpdate(mangaCompanion);
  }

  static Future<MangaData?> getManga(String id) {
    return (appDb.select(
      appDb.manga,
    )..where((manga) => manga.id.equals(id))).getSingleOrNull();
  }

  static Future<List<MangaData>> getMangasByIds(List<String> ids) {
    if (ids.isEmpty) return Future.value([]);
    return (appDb.select(appDb.manga)
      ..where((m) => m.id.isIn(ids))).get();
  }

  static Future<List<MangaData>> getRecentlyReadMangas({int limit = 100}) {
    return (appDb.select(appDb.manga)
      ..where((m) => m.lastReadTime.isNotNull())
      ..orderBy([(m) => OrderingTerm(expression: m.lastReadTime, mode: OrderingMode.desc)])
      ..limit(limit))
        .get();
  }

  static Future<ReadingStats> getReadingStats() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));

    final todayQ = appDb.customSelect(
      'SELECT COUNT(*) AS cnt FROM manga WHERE last_read_time >= ?',
      variables: [Variable.withDateTime(todayStart)],
      readsFrom: {appDb.manga},
    );
    final weekQ = appDb.customSelect(
      'SELECT COUNT(*) AS cnt FROM manga WHERE last_read_time >= ?',
      variables: [Variable.withDateTime(weekStart)],
      readsFrom: {appDb.manga},
    );
    final totalReadQ = appDb.customSelect(
      'SELECT COUNT(*) AS cnt FROM manga WHERE last_read_time IS NOT NULL',
      readsFrom: {appDb.manga},
    );
    final totalQ = appDb.customSelect(
      'SELECT COUNT(*) AS cnt FROM manga',
      readsFrom: {appDb.manga},
    );
    final recentQ = appDb.customSelect(
      'SELECT MAX(last_read_time) AS recent FROM manga',
      readsFrom: {appDb.manga},
    );

    final results = await Future.wait([
      todayQ.getSingle(),
      weekQ.getSingle(),
      totalReadQ.getSingle(),
      totalQ.getSingle(),
      recentQ.getSingle(),
    ]);

    return ReadingStats(
      todayCount: results[0].read<int>('cnt'),
      weekCount: results[1].read<int>('cnt'),
      totalReadCount: results[2].read<int>('cnt'),
      totalMangaCount: results[3].read<int>('cnt'),
      mostRecentReadTime: results[4].read<DateTime?>('recent'),
    );
  }

  static Future<int> deleteManga(String id) {
    return (appDb.delete(
      appDb.manga,
    )..where((manga) => manga.id.equals(id))).go();
  }

  static Future<void> updateManga(MangaCompanion mangaCompanion) {
    return (appDb.update(appDb.manga)
          ..where((manga) => manga.id.equals(mangaCompanion.id.value)))
        .write(mangaCompanion);
  }

  static Future<void> updateMangas(List<MangaCompanion> mangas) {
    return appDb.transaction(() async {
      await appDb.batch((batch) {
        for (MangaCompanion manga in mangas) {
          batch.update(
            appDb.manga,
            manga,
            where: (a) => a.id.equals(manga.id.value),
          );
        }
      });
    });
  }
}
