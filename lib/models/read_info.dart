import 'package:manga_reader/core/repository/manga_repository.dart';
import 'package:manga_reader/models/local_image.dart';
import 'package:manga_reader/models/manga.dart';

class ReadInfo {
  Manga mangaInfo;
  List<LocalImage> images;
  int lastReadIndex;
  int pageCount;
  MangaRepository? repo;

  ReadInfo({
    this.images = const [],
    required this.mangaInfo,
    this.lastReadIndex = 0,
    required this.pageCount,
    this.repo,
  });
}
