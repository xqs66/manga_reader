import '../../models/manga.dart';

class BooksPageState {
  Set<int> displayGroups = {};
  List<Manga> books = [];

  bool isAtRoot = true;

  String currentPath = '';
}