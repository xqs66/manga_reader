import 'package:flutter/material.dart';
import 'package:manga_reader/mixin/scroll_handler.dart';

import '../../models/manga.dart';

class BooksPageState with ScrollState {
  Set<String> displayGroups = {};

  List<Manga> mangas = [];

  List<String> groups = [];

  bool isAtRoot = true;

  String? currentPath;

  bool isSelectMode = false;

  bool isSerchMode = false;

  TextEditingController searchTextController = TextEditingController();

  List<Manga> searchedMangas = [];

  Set<String> selectedMangaIds = {};

  bool get isSelectedAll => selectedMangaIds.length == mangas.length;

  List<Manga> get selectedMangas =>
      mangas.where((manga) => selectedMangaIds.contains(manga.id)).toList();

  bool toDefaultGroupOnceDelete = true;

  bool get deleteOnceGroupDeleted => !toDefaultGroupOnceDelete;
}
