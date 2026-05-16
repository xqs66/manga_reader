import 'dart:io';

import 'package:flutter/material.dart';
import 'package:manga_reader/models/manga.dart';

class MergeMangasPageState {
  Directory? selectedDir;
  Directory? outputDir;

  List<Manga> mangas = [];
  bool isLoadingMangas = false;

  bool get isDirSelected => selectedDir != null;
  bool get isOutputDirSelected => outputDir != null;
  bool get hasSelectedManga => selectedMangas.isNotEmpty;

  List<Manga> selectedMangas = [];
  Set<int> selectedMangaIndexes = {};

  final TextEditingController targetDirNameController = TextEditingController();

  bool isMerging = false;

  bool hasMerged = false;

  bool deleteSourceMangas = false;
  bool outputAsZip = false;

  int mergeProgress = 0;
  int mergeTotal = 0;
}
