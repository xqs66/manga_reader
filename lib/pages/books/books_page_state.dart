import 'package:flutter/material.dart';
import 'package:manga_reader/mixin/scroll_handler.dart';

import '../../models/manga.dart';

class BooksPageState with ScrollState {
  Set<String> displayGroups = {};

  List<Manga> books = [];

  List<String> groups = [];

  bool isAtRoot = true;

  String? currentPath;

  bool isSelectMode = false;

  bool isSerchMode = false;

  TextEditingController searchTextController = TextEditingController();

  List<Manga> searchedMangas = [];

  Set<String> selectedMangaIds = {};

  List<Manga> get selectedMangas =>
      books.where((manga) => selectedMangaIds.contains(manga.id)).toList();
}
