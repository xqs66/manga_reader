import 'dart:async';
import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:manga_reader/pages/books/manags_page_controller.dart';
import 'package:manga_reader/pages/reader/reader_page_state.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/settings/read_setting.dart';
import 'package:manga_reader/shared/utils/log_util.dart';

class ReaderPageController extends GetxController {
  final state = ReaderPageState();
  final String pageId = 'pageId';
  final String imageListId = 'imageListId';
  final String topMenuId = 'topMenuId';
  final String bottomRightInfoId = 'bottomRightInfoId';
  final String bottomMenuId = 'bottomMenuId';

  late Worker toggleImmersiveModeListener;

  @override
  void onReady() {
    super.onReady();

    applyEnableImmersive();

    toggleImmersiveModeListener = ever(readSetting.enableImmersiveMode, (
      value,
    ) {
      applyEnableImmersive();
    });

    state.itemPositionsListener.itemPositions.addListener(_positionListener);
  }

  @override
  void onClose() {
    super.onClose();
    SystemChrome.setEnabledSystemUIMode(.edgeToEdge);
  }

  void applyEnableImmersive() {
    readSetting.enableImmersiveMode.value
        ? SystemChrome.setEnabledSystemUIMode(.immersiveSticky)
        : SystemChrome.setEnabledSystemUIMode(.edgeToEdge);
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

  Future<void> handleDeleteImage(int index) {
    return Get.dialog(
      barrierDismissible: true,
      AlertDialog(
        title: Text('删除图片'),
        content: Text('确定要删除图片吗？'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('取消')),
          TextButton(
            onPressed: () async {
              deleteImage(index);
              Get.back();
            },
            child: Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteImage(int index) async {
    final image = state.readInfo.images[index];
    final readingManga = state.readInfo.mangaInfo;
    final controller = Get.find<BooksPageController>();
    final mangaList = controller.state.mangas;
    final indexOfReadingManga = mangaList.indexOf(readingManga);

    LogUtil.d(mangaList[indexOfReadingManga].title);

    await localMangaService.deleteImage(image);
    state.readInfo.images.removeAt(index);
    state.readInfo.pageCount--;
    update([imageListId]);

    final afterManga = await localMangaService.loadManga(
      Directory(readingManga.path),
    );
    if (afterManga != null) {
      mangaList[indexOfReadingManga] = afterManga;
    }
    controller.update(['${controller.mangaIdPrefix}::$indexOfReadingManga']);
  }
}
