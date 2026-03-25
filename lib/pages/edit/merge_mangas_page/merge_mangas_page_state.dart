import 'dart:io';

import 'package:flutter/material.dart';
import 'package:manga_reader/models/manga.dart';

class MergeMangasPageState {
  Directory? selectedDir;
  Directory? outputDir;

  bool get isDirSelected => selectedDir != null;
  bool get isOutputDirSelected => outputDir != null;
  bool get hasSelectedManga => selectedMangas.isNotEmpty;

  List<Manga> selectedMangas = [];
  Set<int> selectedMangaIndexes = {};

  final TextEditingController targetDirNameController = TextEditingController();

  bool isMerging = false;
}
