import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/settings/read_setting.dart';
import 'package:photo_view/photo_view.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:manga_reader/models/read_info.dart';

class ReaderPageState {
  final itemScrollController = ItemScrollController();

  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  final thumbnailScrollController = ScrollController();

  late final PageController pageController;

  final List<File> images = [];

  final photoViewController = PhotoViewController();

  final ReadInfo readInfo = Get.arguments;

  late final List<Size?> imageContainerSizes;

  bool isMenuOpen = false;

  late int currentIndex;

  double? _lastLayoutWidth;

  ReaderPageState() {
    final lastRead = readInfo.lastReadIndex;
    if (readSetting.readingMode.value.isDoublePage) {
      final spread = lastRead == 0 ? 0 : 1 + (lastRead - 1) ~/ 2;
      pageController = PageController(initialPage: spread);
      currentIndex = spread == 0 ? 0 : 1 + (spread - 1) * 2;
    } else {
      currentIndex = readInfo.lastReadIndex;
      pageController = PageController(initialPage: readInfo.lastReadIndex);
    }
    imageContainerSizes = List.generate(readInfo.pageCount, (_) => null);
  }

  /// Call when layout width changes (e.g. orientation change).
  /// Clears cached image sizes so they recalculate for the new width.
  void onLayoutWidthChanged(double newWidth) {
    if (_lastLayoutWidth != null && _lastLayoutWidth != newWidth) {
      for (var i = 0; i < imageContainerSizes.length; i++) {
        imageContainerSizes[i] = null;
      }
    }
    _lastLayoutWidth = newWidth;
  }
}
