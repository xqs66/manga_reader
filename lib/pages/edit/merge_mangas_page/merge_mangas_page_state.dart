import 'dart:io';

import 'package:flutter/material.dart';
import 'package:manga_reader/mixin/scroll_handler.dart';
import 'package:manga_reader/models/manga.dart';

class MergeMangasPageState with ScrollState {
  Directory? selectedDir;
  Directory? outputDir;

  List<Manga> mangas = [];

  bool get isDirSelected => selectedDir != null;
  bool get isOutputDirSelected => outputDir != null;
  bool get hasSelectedManga => selectedMangas.isNotEmpty;

  List<Manga> selectedMangas = [];
  Set<int> selectedMangaIndexes = {};

  final TextEditingController targetDirNameController = TextEditingController();

  bool isMerging = false;

  bool hasMerged = false;

  bool deleteSourceMangas = false;
}
