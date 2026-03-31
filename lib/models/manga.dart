import 'package:manga_reader/shared/constants/constants.dart';

import 'local_image.dart';

class Manga {
  final String id;
  final String path;
  final String title;
  final int pageCount;
  int size;
  String groupName;
  final LocalImage cover;

  Manga({
    required this.id,
    required this.path,
    required this.title,
    required this.size,
    required this.pageCount,
    required this.groupName,
    required this.cover,
  });

  Manga copyWith({
    String? id,
    String? path,
    String? title,
    int? pageCount,
    int? size,
    String? groupName,
    LocalImage? cover,
  }) {
    return Manga(
      id: id ?? this.id,
      path: path ?? this.path,
      title: title ?? this.title,
      size: size ?? this.size,
      pageCount: pageCount ?? this.pageCount,
      groupName: groupName ?? this.groupName,
      cover: cover ?? this.cover,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Manga && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;
}
