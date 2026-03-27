import 'package:manga_reader/models/local_image.dart';
import 'package:manga_reader/models/manga.dart';

class ReadInfo {
  final Manga mangaInfo;
  final List<LocalImage> images;
  int lastReadIndex;
  int pageCount;

  ReadInfo({
    required this.images,
    required this.mangaInfo,
    this.lastReadIndex = 0,
    required this.pageCount,
  });
}
