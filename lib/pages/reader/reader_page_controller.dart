import 'dart:async';
import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:manga_reader/core/repository/manga_repository.dart';
import 'package:manga_reader/core/result.dart';
import 'package:manga_reader/pages/books/mangas_page_controller.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/pages/reader/reader_page_state.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/settings/read_setting.dart';

class ReaderPageController extends GetxController {
  final state = ReaderPageState();
  final String pageId = 'pageId';
  final String imageListId = 'imageListId';
  final String pageListId = 'pageListId';
  final String topMenuId = 'topMenuId';
  final String bottomRightInfoId = 'bottomRightInfoId';
  final String bottomMenuId = 'bottomMenuId';

  late Worker _immersiveModeListener;
  late Worker _readingModeListener;

  @override
  void onReady() {
    super.onReady();

    applyEnableImmersive();

    _immersiveModeListener = ever(readSetting.enableImmersiveMode, (value) {
      applyEnableImmersive();
    });

    _readingModeListener = ever(readSetting.readingMode, (_) {
      update([pageId]);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        update([pageListId]);
      });
    });

    state.itemPositionsListener.itemPositions.addListener(_positionListener);
  }

  @override
  void onClose() {
    _immersiveModeListener.dispose();
    _readingModeListener.dispose();
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
      scrollThumbnailToCurrent();
      update([bottomMenuId, bottomRightInfoId]);
    }
  }

  void scrollThumbnailToCurrent() {
    final controller = state.thumbnailScrollController;
    if (!controller.hasClients) return;
    final itemWidth = UiConfig.thumbnailStripWidth + 6; // 3px margin on each side
    final targetCenter = state.currentIndex * itemWidth + itemWidth / 2;
    final offset = targetCenter - Get.width / 2 + 8; // 8px ListView left padding
    if (offset > 0) {
      controller.animateTo(
        offset.clamp(0.0, controller.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void toggleMenuOpen() {
    state.isMenuOpen = !state.isMenuOpen;
    update([topMenuId, bottomMenuId, bottomRightInfoId]);
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
    scrollThumbnailToCurrent();
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

  Future<void> handleDeleteImage(int index) async {
    if (localMangaService.isZipFile(state.readInfo.mangaInfo.path)) {
      Fluttertoast.showToast(msg: '压缩包内的图片无法单独删除');
      return;
    }
    return Get.dialog(
      barrierDismissible: true,
      AlertDialog(
        title: Text('删除图片'),
        content: Text('确定要删除图片吗？'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('取消')),
          TextButton(
            onPressed: () async {
              await deleteImage(index);
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
    final booksController = Get.find<BooksPageController>();
    final mangaList = booksController.state.mangas;
    final indexOfReadingManga =
        mangaList.indexWhere((m) => m.id == readingManga.id);
    if (indexOfReadingManga == -1) return;

    final repo = Get.find<MangaRepository>();
    final result = await repo.deleteImage(image);
    if (result is Err) return;

    state.readInfo.images.removeAt(index);
    state.readInfo.pageCount--;
    state.imageContainerSizes.removeAt(index);
    update([imageListId]);

    final loadResult = await repo.tryLoadManga(Directory(readingManga.path));
    final afterManga = loadResult.okValue;
    if (afterManga != null) {
      mangaList[indexOfReadingManga] = afterManga;
      state.readInfo.mangaInfo = afterManga;
      booksController.update(
          ['${booksController.mangaIdPrefix}::$indexOfReadingManga']);
    }
  }
}
