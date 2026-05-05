import 'dart:io';

import 'package:manga_reader/models/manga.dart';

class ArchiveMangasState {
  Directory? selectedDir;
  Directory? outputDir;
  List<Manga> mangas = [];
  final Set<Manga> selectedMangas = {};
  bool isWorking = false;
  int progress = 0;
  int total = 0;
  bool deleteSource = false;

  bool get isDirSelected => selectedDir != null;
  bool get isOutputSelected => outputDir != null;
  bool get hasSelection => selectedMangas.isNotEmpty;
}
