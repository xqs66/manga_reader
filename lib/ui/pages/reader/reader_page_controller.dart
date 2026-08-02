import 'dart:async';
import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:manga_reader/core/repository/manga_repository.dart';
import 'package:manga_reader/models/result.dart';
import 'package:manga_reader/ui/pages/mangas/mangas_page_controller.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/core/mixin/scroll_handler.dart';
import 'package:manga_reader/core/utils/log_util.dart';
import 'package:manga_reader/ui/pages/reader/reader_page_state.dart';
import 'package:manga_reader/models/manga_id.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/ui/pages/more/settings/read/read_settings_page.dart';
import 'package:manga_reader/settings/read_setting.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:manga_reader/ui/widgets/manga_info_sheet.dart';

class ReaderPageController extends GetxController {
  final state = ReaderPageState();
  final String pageId = 'pageId';
  final String imageListId = 'imageListId';
  final String pageListId = 'pageListId';
  final String topMenuId = 'topMenuId';
  final String bottomRightInfoId = 'bottomRightInfoId';
  final String bottomMenuId = 'bottomMenuId';
  final String loadingImagesId = 'loadingImagesId';

  late Worker _immersiveModeListener;
  late Worker _readingModeListener;
  Timer? _saveTimer;
  Timer? _timeTimer;
  Timer? _pageTurnGuard;
  ScrollWrapperState? scrollState;
  late final FocusNode _focusNode;
  String _batteryLevel = '--';
  final _battery = Battery();

  String get currentTime {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String get batteryLevel => _batteryLevel;

  String get pageIndicator {
    if (!_isDoublePage) {
      return '${state.currentIndex + 1}/${state.readInfo.pageCount}';
    }
    final left = state.currentIndex;
    final right = rightOfSpread(currentSpread);
    if (right == null) return '${left + 1}/${state.readInfo.pageCount}';
    return '${left + 1}-${right + 1}/${state.readInfo.pageCount}';
  }

  Future<void> _updateBattery() async {
    try {
      _batteryLevel = '${await _battery.batteryLevel}';
    } catch (_) {
      _batteryLevel = '--';
    }
  }

  @override
  void onInit() {
    super.onInit();
    _focusNode = FocusNode();
  }

  @override
  void onReady() {
    super.onReady();
    LogUtil.i('Reader opened: ${state.readInfo.mangaInfo.title}', tag: 'READER');

    applyEnableImmersive();

    _focusNode.requestFocus();

    _updateBattery();
    _timeTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _updateBattery();
      update([bottomRightInfoId]);
    });

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollThumbnailToCurrent();
      _loadImagesIfNeeded();
    });
  }

  Future<void> _loadImagesIfNeeded() async {
    if (state.readInfo.images.isNotEmpty) return;
    try {
      final manga = state.readInfo.mangaInfo;
      final repo = state.readInfo.repo ?? Get.find<MangaRepository>();
      final images = await repo.getMangaImagesAsync(manga);
      state.readInfo.images = images;
    } catch (e) {
      LogUtil.e('Failed to load images for reader', error: e);
      Fluttertoast.showToast(msg: '图片加载失败，请返回重试');
    }
    update([loadingImagesId, imageListId, pageListId]);
  }

  bool get _isDoublePage => readSetting.readingMode.value.isDoublePage;

  int get itemCount => _isDoublePage ? spreadCount : state.readInfo.pageCount;

  int get spreadCount {
    final n = state.readInfo.pageCount;
    if (n <= 1) return 1;
    return 1 + ((n - 1) / 2).ceil();
  }

  /// Spread index → left page index.
  int leftOfSpread(int spread) {
    if (spread == 0) return 0;
    return 1 + (spread - 1) * 2;
  }

  /// Spread index → right page index, or null if single.
  int? rightOfSpread(int spread) {
    if (spread == 0) return null;
    final r = 1 + (spread - 1) * 2 + 1;
    return r < state.readInfo.pageCount ? r : null;
  }

  /// Current page index → current spread index.
  int get currentSpread {
    final idx = state.currentIndex;
    if (idx == 0) return 0;
    return 1 + (idx - 1) ~/ 2;
  }

  void goToNextPage() {
    if (_pageTurnGuard?.isActive ?? false) return;
    if (_isDoublePage) {
      final nextSpread = currentSpread + 1;
      if (nextSpread >= spreadCount) return;
      _pageTurnGuard = Timer(const Duration(milliseconds: 350), () {});
      _navigateToSpread(nextSpread);
    } else {
      final next = state.currentIndex + 1;
      if (next >= state.readInfo.pageCount) return;
      _pageTurnGuard = Timer(const Duration(milliseconds: 350), () {});
      _navigateTo(next);
    }
  }

  void goToPreviousPage() {
    if (_pageTurnGuard?.isActive ?? false) return;
    if (_isDoublePage) {
      final prevSpread = currentSpread - 1;
      if (prevSpread < 0) return;
      _pageTurnGuard = Timer(const Duration(milliseconds: 350), () {});
      _navigateToSpread(prevSpread);
    } else {
      final prev = state.currentIndex - 1;
      if (prev < 0) return;
      _pageTurnGuard = Timer(const Duration(milliseconds: 350), () {});
      _navigateTo(prev);
    }
  }

  void _navigateToSpread(int spread) {
    if (state.isMenuOpen) toggleMenuOpen();
    state.pageController.animateToPage(
      spread,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void handleTapLeft() {
    if ((scrollState?.isScrolling ?? false)) return;
    final isRTL = readSetting.readingMode.value.isRTL;
    isRTL ? goToNextPage() : goToPreviousPage();
  }

  void handleTapRight() {
    if ((scrollState?.isScrolling ?? false)) return;
    final isRTL = readSetting.readingMode.value.isRTL;
    isRTL ? goToPreviousPage() : goToNextPage();
  }

  void _navigateTo(int index) {
    if (state.isMenuOpen) toggleMenuOpen();
    if (readSetting.readingMode.value == ReadingMode.strip) {
      if (!state.itemScrollController.isAttached) return;
      state.itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
      );
      state.currentIndex = index;
      _updateCachesSync(index);
      scrollThumbnailToCurrent();
      update([bottomMenuId, bottomRightInfoId]);
      _debouncedSaveProgress();
    } else {
      if (!state.pageController.hasClients) return;
      state.pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  FocusNode get focusNode => _focusNode;

  KeyEventResult handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    try {
      final handled = switch (event.logicalKey) {
        LogicalKeyboardKey.arrowLeft => _act(goToPreviousPage),
        LogicalKeyboardKey.arrowRight => _act(goToNextPage),
        LogicalKeyboardKey.arrowUp => _act(goToPreviousPage),
        LogicalKeyboardKey.arrowDown => _act(goToNextPage),
        LogicalKeyboardKey.audioVolumeUp   => _actVol(goToPreviousPage),
        LogicalKeyboardKey.audioVolumeDown => _actVol(goToNextPage),
        _ => false,
      };
      return handled ? KeyEventResult.handled : KeyEventResult.ignored;
    } catch (e) {
      LogUtil.e('Key event error', error: e);
      return KeyEventResult.ignored;
    }
  }

  bool _act(VoidCallback action) {
    action();
    return true;
  }

  bool _actVol(VoidCallback action) {
    if (!readSetting.enableVolumeKeyNavigation.value) return false;
    action();
    return true;
  }

  void handleMouseWheel(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      event.scrollDelta.dy > 0 ? goToPreviousPage() : goToNextPage();
    }
  }

  @override
  void onClose() {
    LogUtil.i('Reader closed: ${state.readInfo.mangaInfo.title}', tag: 'READER');
    _saveTimer?.cancel();
    _timeTimer?.cancel();
    _pageTurnGuard?.cancel();
    _focusNode.dispose();
    persistToDb();
    _immersiveModeListener.dispose();
    _readingModeListener.dispose();
    super.onClose();
    SystemChrome.setEnabledSystemUIMode(.edgeToEdge);
  }

  void _updateCachesSync(int page) {
    final manga = state.readInfo.mangaInfo;
    final updated = manga.copyWith(
      lastReadPage: page,
      lastReadTime: DateTime.now(),
    );
    state.readInfo.mangaInfo = updated;

    // Skip local cache update for remote mangas
    if (state.readInfo.repo != null) return;

    final parentPath = Directory(updated.path).parent.path;
    final list = localMangaService.settingPath2Mangas[parentPath];
    if (list != null) {
      final i = list.indexWhere((m) => m.id == updated.id);
      if (i != -1) list[i] = updated;
    }
  }

  void persistToDb() {
    _updateCachesSync(state.currentIndex);
    final manga = state.readInfo.mangaInfo;
    Get.find<MangaRepository>().updateMangaReadProgress(
      manga.id,
      manga.lastReadPage,
    );
  }

  void _debouncedSaveProgress() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), persistToDb);
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
      _updateCachesSync(index);
      scrollThumbnailToCurrent();
      update([bottomMenuId, bottomRightInfoId]);
      _debouncedSaveProgress();
    }
  }

  void scrollThumbnailToCurrent() {
    final controller = state.thumbnailScrollController;
    if (!controller.hasClients) return;
    final itemWidth =
        UiConfig.thumbnailStripWidth + 6; // 3px margin on each side
    final targetCenter = state.currentIndex * itemWidth + itemWidth / 2;
    final offset =
        targetCenter - Get.width / 2 + 8; // 8px ListView left padding
    controller.animateTo(
      offset.clamp(0.0, controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void toggleMenuOpen() {
    if ((scrollState?.isScrolling ?? false)) return;
    state.isMenuOpen = !state.isMenuOpen;
    update([topMenuId, bottomMenuId, bottomRightInfoId]);
  }

  void handleJumpToPage(int index) {
    if (readSetting.readingMode.value == ReadingMode.strip) {
      handleSlideEnd((index + 1).toDouble());
    } else {
      final target = _isDoublePage ? currentSpreadByPage(index) : index;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.pageController.jumpToPage(target);
      });
    }
    update([bottomMenuId, bottomRightInfoId]);
  }

  /// Page index → spread index (for thumbnail jumps).
  int currentSpreadByPage(int pageIndex) {
    if (pageIndex == 0) return 0;
    return 1 + (pageIndex - 1) ~/ 2;
  }

  void handlePageChanged(int spreadIndex) {
    state.currentIndex = _isDoublePage ? leftOfSpread(spreadIndex) : spreadIndex;
    _updateCachesSync(state.currentIndex);
    scrollThumbnailToCurrent();
    update([bottomMenuId, bottomRightInfoId]);
    _debouncedSaveProgress();
  }

  void handleSliderChanged(double value) {
    state.currentIndex = value.toInt() - 1;
    update([bottomMenuId]);
  }

  void handleSliderChangeEnd(double value) {
    handleJumpToPage(value.toInt() - 1);
  }

  void handleOpenSettings() {
    Get.bottomSheet(
      const ClipRRect(
        borderRadius: .only(topLeft: .circular(16), topRight: .circular(16)),
        child: ReadSettingsPage(isBottomSheet: true),
      ),
    );
    toggleMenuOpen();
  }

  void handleOpenMangaInfo() {
    Get.bottomSheet(
      ClipRRect(
        borderRadius: const .only(
          topLeft: .circular(16),
          topRight: .circular(16),
        ),
        child: MangaInfoSheet(manga: state.readInfo.mangaInfo),
      ),
    );
    toggleMenuOpen();
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
      if (_isDoublePage) {
        update(['spread_${currentSpreadByPage(index)}']);
      }
    });
  }

  void handleSlide(double value) {
    state.currentIndex = value.toInt() - 1;
    update([bottomMenuId]);
  }

  void handleSlideEnd(double value) {
    final index = value.toInt() - 1;
    state.itemScrollController.jumpTo(index: index);
    state.currentIndex = index;
    _updateCachesSync(index);
    scrollThumbnailToCurrent();
    update([bottomMenuId, bottomRightInfoId]);
    _debouncedSaveProgress();
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
    return Get.dialog(
      barrierDismissible: true,
      AlertDialog(
        title: const Text('删除图片'),
        content: Text(localMangaService.isZipFile(state.readInfo.mangaInfo.path)
            ? '确定要从压缩包中删除该图片吗？'
            : '确定要删除该图片吗？'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              await deleteImage(index);
              Get.back();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteImage(int index) async {
    final image = state.readInfo.images[index];
    final readingManga = state.readInfo.mangaInfo;
    final booksController = Get.find<MangasPageController>();
    final mangaList = booksController.state.mangas;
    final indexOfReadingManga = mangaList.indexWhere(
      (m) => m.id == readingManga.id,
    );
    if (indexOfReadingManga == -1) return;

    if (localMangaService.isZipFile(readingManga.path)) {
      try {
        final cacheDir = p.join(
          Directory.systemTemp.path,
          'manga_reader',
          MangaId.fromPath(readingManga.path).value,
        );
        final entryName = p.relative(image.path!, from: cacheDir);
        await localMangaService.deleteImageFromZip(
          File(readingManga.path),
          entryName,
        );
      } catch (_) {
        return;
      }
    } else {
      final repo = Get.find<MangaRepository>();
      final result = await repo.deleteImage(image);
      if (result is Err) {
        Fluttertoast.showToast(msg: '删除失败');
        return;
      }
    }

    state.readInfo.images.removeAt(index);
    state.readInfo.pageCount--;
    state.imageContainerSizes.removeAt(index);
    update([imageListId]);

    // Re-scan the manga so cover/pageCount reflect the deletion. For ZIP/CBZ,
    // deleteImageFromZip clears the extracted temp cache, so a fresh scan
    // regenerates a valid cover at the new first-image path.
    final loadResult = await Get.find<MangaRepository>()
        .tryLoadManga(Directory(readingManga.path));
    final afterManga = loadResult.okValue;
    final updatedManga = afterManga ??
        readingManga.copyWith(
          pageCount: state.readInfo.pageCount,
          size: File(readingManga.path).lengthSync(),
        );
    mangaList[indexOfReadingManga] = updatedManga;
    state.readInfo.mangaInfo = updatedManga;
    // Notify by manga id (cards subscribe with 'Manga::<mangaId>') and by bodyId
    // so the grid/list rebuilds with the refreshed cover.
    booksController.update([
      '${booksController.mangaIdPrefix}::${updatedManga.id}',
      booksController.bodyId,
    ]);
  }
}
