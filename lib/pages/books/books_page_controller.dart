import 'package:get/get.dart';
import 'package:manga_reader/pages/books/books_page_state.dart';
import 'package:manga_reader/service/local_manga_service.dart';

class BooksPageController extends GetxController {
  final state = BooksPageState();
  final bodyId = 'bodyId';
  final popUpMenuId = 'popUpMenuId';

  void enterMangaDir(String path) {
    state.isAtRoot = false;
    state.currentPath = path;
    state.books = localMangaService.mangasInLocalSettingPaths[path] ?? [];
    update([bodyId, popUpMenuId]);
  }

  void back2Root() {
    state.isAtRoot = true;
    update([bodyId, popUpMenuId]);
  }

  void toggleOpen(int index) {
    if (state.displayGroups.contains(index)) {
      state.displayGroups.remove(index);
    } else {
      state.displayGroups.add(index);
    }
    update(['Group::$index']);
  }

  Future<void> refreshMangas() async {
    await localMangaService.loadMangasInLocalSettingPaths();
    state.books = localMangaService.mangasInLocalSettingPaths[state.currentPath] ?? [];
    update([bodyId]);
  }
}
