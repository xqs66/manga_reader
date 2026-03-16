import 'package:manga_reader/models/local_image.dart';

class ReadInfo {
  final String title;
  final List<LocalImage> images;
  int lastReadIndex;
  final int pageCount;

  ReadInfo({
    required this.title,
    required this.images,
    this.lastReadIndex = 0,
    required this.pageCount,
  });
}
