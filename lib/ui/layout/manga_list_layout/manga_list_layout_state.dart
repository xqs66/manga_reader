import 'package:flutter/material.dart';
import 'package:manga_reader/models/manga.dart';

abstract class MangaListLayoutState {
  List<Manga> mangas = [];
  bool isSearchMode = false;
  List<Manga> searchedMangas = [];
  TextEditingController searchTextController = TextEditingController();
}
