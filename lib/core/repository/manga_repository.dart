import 'dart:io';

import 'package:manga_reader/core/result.dart';
import 'package:manga_reader/models/local_image.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/models/manga_id.dart';

class GroupInfo {
  final String name;
  final bool isExpanded;
  const GroupInfo({required this.name, required this.isExpanded});
}

/// Abstract contract for manga data operations.
///
/// Controllers depend on this interface, never on concrete implementations
/// or on [LocalMangaService] directly. Every method that can fail returns
/// a [Result] so callers cannot ignore the error case.
abstract class MangaRepository {
  Future<Result<List<Manga>>> loadMangasInDir(Directory dir);

  Future<Result<Manga>> loadManga(Directory dirOfManga);
  Future<Result<Manga?>> tryLoadManga(Directory dirOfManga);

  List<LocalImage> getMangaImages(Manga manga);
  Future<List<LocalImage>> getMangaImagesAsync(Manga manga);

  Future<Result<List<Manga>>> getMangasForPath(String path);
  Future<Result<void>> refreshMangasInDir(Directory dir);

  Future<Result<Manga>> mergeMangas(
    List<Manga> mangas,
    Directory output, {
    int imageNameStartFrom = 0,
    void Function(int current, int total)? onProgress,
  });

  Future<Result<void>> deleteManga(Manga manga);
  Future<Result<void>> deleteMangas(List<Manga> mangas);
  Future<Result<void>> deleteImage(LocalImage image);

  Future<Result<List<GroupInfo>>> fetchGroups(String parentPath);
  Future<Result<void>> addGroup(String name, String parentPath);
  Future<Result<void>> removeGroup(String name, String parentPath);
  Future<Result<void>> updateGroupExpand(String name, String parentPath, bool isExpanded);
  Future<Result<void>> moveMangasToGroup(Set<MangaId> mangaIds, String groupName);
  Future<Result<void>> resetMangasToDefaultGroup(String groupName, String? path);

  Future<void> updateMangaReadProgress(MangaId id, int lastReadPage);
}
