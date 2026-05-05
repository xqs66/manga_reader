import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../models/read_info.dart';

class ReaderPageState {
  final itemScrollController = ItemScrollController();

  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  final thumbnailScrollController = ScrollController();

  final PageController pageController = PageController();

  final List<File> images = [];

  final photoViewController = PhotoViewController();

  final ReadInfo readInfo = Get.arguments;

  late final List<Size?> imageContainerSizes;

  bool isMenuOpen = false;

  int currentIndex = 0;

  double? _lastLayoutWidth;

  ReaderPageState() {
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
