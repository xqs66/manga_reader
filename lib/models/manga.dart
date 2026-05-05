import 'local_image.dart';
import 'manga_id.dart';

class Manga {
  final MangaId id;
  final String path;
  final String title;
  final int pageCount;
  final int lastReadPage;
  final int size;
  final String groupName;
  final LocalImage cover;

  const Manga({
    required this.id,
    required this.path,
    required this.title,
    required this.size,
    required this.lastReadPage,
    required this.pageCount,
    required this.groupName,
    required this.cover,
  });

  Manga copyWith({
    MangaId? id,
    String? path,
    String? title,
    int? pageCount,
    int? size,
    int? lastReadPage,
    String? groupName,
    LocalImage? cover,
  }) {
    return Manga(
      id: id ?? this.id,
      path: path ?? this.path,
      title: title ?? this.title,
      size: size ?? this.size,
      lastReadPage: lastReadPage ?? this.lastReadPage,
      pageCount: pageCount ?? this.pageCount,
      groupName: groupName ?? this.groupName,
      cover: cover ?? this.cover,
    );
  }

  @override
  bool operator ==(Object other) => other is Manga && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
