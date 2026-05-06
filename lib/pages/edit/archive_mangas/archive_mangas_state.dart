import 'dart:io';

import 'package:flutter/material.dart';
import 'package:manga_reader/models/manga.dart';

class ArchiveMangasState {
  Directory? selectedDir;
  List<Manga> mangas = [];
  final Set<Manga> selectedMangas = {};
  final ScrollController scrollController = ScrollController();
  bool isLoadingMangas = false;
  bool isWorking = false;
  int progress = 0;
  int total = 0;

  bool get isDirSelected => selectedDir != null;
  bool get hasSelection => selectedMangas.isNotEmpty;
}
