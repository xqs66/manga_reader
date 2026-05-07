import 'package:flutter/material.dart';
import 'package:manga_reader/mixin/scroll_handler.dart';
import 'package:manga_reader/models/manga_id.dart';

import '../../models/manga.dart';

class MangasPageState with ScrollState {
  Set<String> displayGroups = {};

  List<Manga> mangas = [];

  List<String> groups = [];

  Set<MangaId> selectedMangaIds = {};

  bool isAtRoot = true;

  String? currentPath;

  bool isSelectMode = false;

  bool isSearchMode = false;

  TextEditingController searchTextController = TextEditingController();

  List<Manga> searchedMangas = [];

  bool get isSelectedAll => selectedMangaIds.length == mangas.length;

  List<Manga> get selectedMangas =>
      mangas.where((m) => selectedMangaIds.contains(m.id)).toList();

  bool toDefaultGroupOnceDelete = true;

  bool get deleteOnceGroupDeleted => !toDefaultGroupOnceDelete;

  bool isRefreshing = false;

  /// When non-null in grid mode, shows only mangas from this group.
  String? currentGridGroup;
}
