import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/pages/reader/reader_page_state.dart';

class ReaderPageController extends GetxController {
  final state = ReaderPageState();
  final String topMenuId = 'topMenuId';
  final String bottomRightInfoId = 'bottomRightInfoId';
  final String bottomMenuId = 'bottomMenuId';

  @override
  void onReady() {
    super.onReady();
    state.itemPositionsListener.itemPositions.addListener(_positionListener);
  }

  void _positionListener() {
    final index = getCurrentIndex();

    if (index == null) return;

    if (index != state.currentIndex) {
      state.currentIndex = index;
      update([bottomMenuId, bottomRightInfoId]);
    }
  }

  void toggleMenuOpen() {
    state.isMenuOpen = !state.isMenuOpen;
    update([topMenuId, bottomMenuId]);
  }

  void onLoadCompleteCallBack(
    int index,
    ExtendedImageState state,
    Size displayResionSize,
  ) {
    if (state.extendedImageInfo == null ||
        this.state.imageContainerSizes[index] != null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fittedSize = applyBoxFit(
        .fitWidth,
        Size(
          state.extendedImageInfo!.image.width.toDouble(),
          state.extendedImageInfo!.image.height.toDouble(),
        ),
        displayResionSize,
      );
      this.state.imageContainerSizes[index] = fittedSize.destination;
      update(['{ReadPageImage::$index}']);
    });
  }

  void handleSlide(double value) {
    state.currentIndex = value.toInt() - 1;
    update([bottomMenuId]);
  }

  void handleSlideEnd(double value) {
    state.itemScrollController.jumpTo(index: value.toInt() - 1);
    update([bottomRightInfoId]);
  }

  int? getCurrentIndex() {
    final itemPositions = state.itemPositionsListener.itemPositions.value;
    final sortedPositions = itemPositions.toList()
      ..sort((a, b) => a.index - b.index);

    if (sortedPositions.firstOrNull == null ||
        sortedPositions.lastOrNull == null) {
      return null;
    }
    final lastPosition = sortedPositions.lastOrNull;
    final isAtEnd =
        lastPosition?.index == state.readInfo.pageCount - 1 &&
        lastPosition!.itemTrailingEdge <= 1;

    return isAtEnd
        ? state.readInfo.pageCount - 1
        : sortedPositions.firstOrNull!.index;
  }
}
