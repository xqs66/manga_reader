import 'dart:io';

class MergeMangasPageState {
  Directory? selectedDir;
  Directory? outputDir;

  bool get isDirSelected => selectedDir != null;
  bool get isOutputDirSelected => outputDir != null;
  bool get hasSelectedManga => selectedMangaPaths.isNotEmpty;

  List<String> selectedMangaPaths = [];
  Set<int> selectedMangaIndexes = {};
}