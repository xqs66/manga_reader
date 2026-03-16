import 'dart:io';
import 'dart:ui';

import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../models/read_info.dart';

class ReaderPageState {
  final itemScrollController = ItemScrollController();
  final photoViewController = PhotoViewController();
  final ReadInfo readInfo = Get.arguments;
  late final List<Size?> imageContainerSizes;
  bool isMenuOpen = false;
  int currentIndex = 0;

  ReaderPageState() {
    imageContainerSizes = List.generate(readInfo.pageCount, (_) => null);
  }
}
