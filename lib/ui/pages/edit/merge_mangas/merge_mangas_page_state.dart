import 'dart:io';

import 'package:flutter/material.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/ui/layout/manga_list_layout/manga_list_layout_state.dart';

class MergeMangasPageState extends MangaListLayoutState {
  Directory? selectedDir;
  Directory? outputDir;

  bool isLoadingMangas = false;

  bool get isDirSelected => selectedDir != null;
  bool get isOutputDirSelected => outputDir != null;
  bool get hasSelectedManga => selectedMangas.isNotEmpty;

  List<Manga> selectedMangas = [];
  Set<int> selectedMangaIndexes = {};

  final TextEditingController targetDirNameController =
      TextEditingController();

  bool isMerging = false;
  bool hasMerged = false;

  bool deleteSourceMangas = false;
  bool outputAsZip = false;

  int mergeProgress = 0;
  int mergeTotal = 0;
}
