import 'package:manga_reader/core/enums/sort_mode.dart';
import 'package:manga_reader/models/manga_id.dart';
import 'package:manga_reader/ui/layout/manga_list_layout/manga_list_layout_state.dart';
import 'package:manga_reader/models/manga.dart';

class MangasPageState extends MangaListLayoutState {
  Set<String> displayGroups = {};

  List<String> groups = [];

  Set<MangaId> selectedMangaIds = {};

  bool isAtRoot = true;

  String? currentPath;

  bool isSelectMode = false;

  bool get isSelectedAll => selectedMangaIds.length == mangas.length;

  List<Manga> get selectedMangas =>
      mangas.where((m) => selectedMangaIds.contains(m.id)).toList();

  bool toDefaultGroupOnceDelete = true;

  bool get deleteOnceGroupDeleted => !toDefaultGroupOnceDelete;

  bool isRefreshing = false;

  String? currentGridGroup;

  SortMode sortMode = SortMode.title;
  bool sortAscending = true;
}
