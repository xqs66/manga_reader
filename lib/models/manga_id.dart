import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Strongly-typed identifier for [Manga], backed by an MD5 hash of the path.
class MangaId {
  final String value;

  const MangaId(this.value);

  factory MangaId.fromPath(String path) => MangaId(_md5(path));

  static String _md5(String input) => md5.convert(utf8.encode(input)).toString();

  @override
  bool operator ==(Object other) => other is MangaId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
