import 'local_image.dart';

class Manga {
  final String path;
  String title;
  int pageCount;
  int size;
  final LocalImage cover;

  Manga({
    required this.path,
    required this.title,
    required this.size,
    this.pageCount = 0,
    required this.cover,
  });

  @override
  bool operator ==(Object other) {
    return other is Manga && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;
}
