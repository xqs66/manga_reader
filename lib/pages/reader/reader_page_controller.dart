import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/pages/reader/reader_page_state.dart';

class ReaderPageController extends GetxController {
  final state = ReaderPageState();
  final String topMenuId = 'top_menu_id';

  void toggleMenuOpen() {
    state.isMenuOpen = !state.isMenuOpen;
    update([topMenuId]);
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

  
}