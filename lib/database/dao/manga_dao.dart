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
       appDb.batch((batch) {
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
