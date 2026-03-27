import 'package:flutter/material.dart';
import 'package:manga_reader/mixin/scroll_handler.dart';

import '../../models/manga.dart';

class BooksPageState with ScrollState {
  Set<int> displayGroups = {0};
  List<Manga> books = [];

  bool isAtRoot = true;

  String currentPath = '';
}