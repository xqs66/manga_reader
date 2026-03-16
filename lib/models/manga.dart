import 'local_image.dart';

class Manga {
  final String path;
  final String title;
  int pageCount;
  final int size;
  final LocalImage cover;

  Manga({
    required this.path,
    required this.title,
    required this.size,
    this.pageCount = 0,
    required this.cover,
  });
}
