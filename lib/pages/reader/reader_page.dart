import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/models/local_image.dart';
import 'package:manga_reader/pages/reader/reader_page_controller.dart';
import 'package:manga_reader/pages/settings/read/read_settings_page.dart';
import 'package:manga_reader/settings/read_setting.dart';
import 'package:manga_reader/core/constants/constants.dart';
import 'package:manga_reader/widgets/manga_image.dart';
import 'package:manga_reader/widgets/styled_menu.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final _controller = Get.put(ReaderPageController());
  final _state = Get.find<ReaderPageController>().state;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReaderPageController>(
      id: _controller.pageId,
      builder: (_) {
        return LayoutBuilder(
          builder: (_, constraints) {
            _state.onLayoutWidthChanged(constraints.maxWidth);
            final isStrip = readSetting.readingMode.value == ReadingMode.strip;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: const SystemUiOverlayStyle(
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarDividerColor: Colors.transparent,
                statusBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: Brightness.light,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.light,
              ),
              child: Container(
                color: Colors.black,
                child: Stack(
                  children: [
                    KeyedSubtree(
                      key: ValueKey(isStrip ? 'strip' : 'page'),
                      child: isStrip ? _buildStripMode() : _buildPageMode(),
                    ),
                    _buildPageInfoOverlay(),
                    _buildTopMenu(),
                    _buildBottomMenu(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Strip mode ──

  Widget _buildStripMode() {
    return GetBuilder<ReaderPageController>(
      id: _controller.imageListId,
      builder: (context) {
        return PhotoViewGallery.builder(
          itemCount: 1,
          scrollDirection: Axis.vertical,
          builder: (_, _) {
            return PhotoViewGalleryPageOptions.customChild(
              controller: _state.photoViewController,
              initialScale: 1.0,
              minScale: 1.0,
              maxScale: 2.5,
              child: ScrollablePositionedList.separated(
                addAutomaticKeepAlives: true,
                itemCount: _state.readInfo.pageCount,
                itemScrollController: _state.itemScrollController,
                itemPositionsListener: _state.itemPositionsListener,
                initialAlignment: 0,
                minCacheExtent: Get.height * 5,
                itemBuilder: (context, index) => _buildImageItem(index),
                separatorBuilder: (_, _) => Obx(
                  () => SizedBox(height: readSetting.imageSpacing.value.toDouble()),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImageItem(int index) {
    return GetBuilder<ReaderPageController>(
      id: '{ReadPageImage::$index}',
      builder: (_) {
        return LayoutBuilder(
          builder: (_, constraints) {
            return GestureDetector(
              onTap: _controller.toggleMenuOpen,
              behavior: .opaque,
              child: Obx(
                () => readSetting.enableGrayscaleMode.value
                    ? ColorFiltered(
                        colorFilter: ColorFilter.matrix(Constants.grayscaleMatrix),
                        child: _buildStripImage(constraints, index),
                      )
                    : _buildStripImage(constraints, index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStripImage(BoxConstraints constraints, int index) {
    return MangaImage(
      image: _state.readInfo.images[index],
      longPressActions: [
        StyledAction(
          label: '删除图片',
          isDestructive: true,
          onPressed: () => _controller.handleDeleteImage(index),
        ),
      ],
      height: _state.imageContainerSizes[index]?.height ??
          constraints.maxWidth * UiConfig.defaultImageContainerRadio,
      width: _state.imageContainerSizes[index]?.width ?? constraints.maxWidth,
      fit: .fitWidth,
      loadCompleteCallBack: (state) => _controller.onLoadCompleteCallBack(
          index, state, Size(constraints.maxWidth, double.infinity)),
    );
  }

  // ── Single page mode ──

  Widget _buildPageMode() {
    final mode = readSetting.readingMode.value;
    final isHorizontal = mode == ReadingMode.singleLTR || mode == ReadingMode.singleRTL;
    final isRTL = mode == ReadingMode.singleRTL;

    return GetBuilder<ReaderPageController>(
      id: _controller.pageListId,
      builder: (_) {
        return PhotoViewGallery.builder(
          scrollDirection: isHorizontal ? .horizontal : .vertical,
          reverse: isRTL,
          itemCount: _state.readInfo.pageCount,
          pageController: _state.pageController,
          onPageChanged: (index) {
            _state.currentIndex = index;
            _controller.scrollThumbnailToCurrent();
            _controller.update([_controller.bottomMenuId, _controller.bottomRightInfoId]);
          },
          builder: (context, index) {
            return PhotoViewGalleryPageOptions.customChild(
              controller: _state.photoViewController,
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained,
              maxScale: 3.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MangaImage(
                    image: _state.readInfo.images[index],
                    fit: .contain,
                    backgroundColor: Colors.black,
                    longPressActions: [
                      StyledAction(
                        label: '删除图片',
                        isDestructive: true,
                        onPressed: () => _controller.handleDeleteImage(index),
                      ),
                    ],
                    loadCompleteCallBack: (_) {},
                  ),
                  GestureDetector(
                    onTap: _controller.toggleMenuOpen,
                    behavior: .translucent,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Top menu ──

  Widget _buildTopMenu() {
    final topPadding = readSetting.enableImmersiveMode.value
        ? 0.0
        : context.mediaQuery.padding.top;

    return GetBuilder<ReaderPageController>(
      id: _controller.topMenuId,
      builder: (_) {
        return AnimatedPositioned(
          top: _state.isMenuOpen ? 0 : -(UiConfig.topAreaMenuHeight + topPadding),
          height: UiConfig.topAreaMenuHeight + topPadding,
          width: Get.width,
          curve: Curves.easeOutCubic,
          duration: const Duration(milliseconds: 150),
          child: AnimatedOpacity(
            opacity: _state.isMenuOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              padding: EdgeInsets.only(top: topPadding),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xE6000000), Color(0x66000000), Colors.transparent],
                ),
              ),
              child: AppBar(
                title: Text(
                  _state.readInfo.mangaInfo.title,
                  style: UiConfig.readPageTitleStyle,
                  overflow: TextOverflow.ellipsis,
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                foregroundColor: UiConfig.readPageForegroundColor,
                elevation: 0,
                actions: [
                  IconButton(
                    onPressed: () {
                      Get.bottomSheet(
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: const ReadSettingsPage(isBottomSheet: true),
                        ),
                      );
                      _controller.toggleMenuOpen();
                    },
                    icon: const Icon(Icons.tune_rounded),
                    tooltip: '阅读设置',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Bottom menu ──

  Widget _buildBottomMenu() {
    final bottomPadding = readSetting.enableImmersiveMode.value
        ? 0.0
        : context.mediaQuery.padding.bottom;

    return GetBuilder<ReaderPageController>(
      id: _controller.bottomMenuId,
      builder: (_) {
        final pageCount = _state.readInfo.pageCount;
        final currentPage = _state.currentIndex;
        final isRTL = readSetting.readingMode.value == ReadingMode.singleRTL;
        const double sliderThumbnailSpacing = 8;
        const double topShadowHeight = 16;

        final totalHeight =
            UiConfig.bottomAreaMenuHeight +
            UiConfig.thumbnailStripHeight +
            topShadowHeight +
            sliderThumbnailSpacing +
            bottomPadding;

        return AnimatedPositioned(
          bottom: _state.isMenuOpen ? 0 : -totalHeight,
          height: totalHeight,
          width: Get.width,
          curve: Curves.easeOutCubic,
          duration: const Duration(milliseconds: 150),
          child: AnimatedOpacity(
            opacity: _state.isMenuOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              padding: EdgeInsets.only(bottom: bottomPadding),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [0.0, 0.35, 0.7, 1.0],
                  colors: [
                    Color(0xE6000000),
                    Color(0xE6000000),
                    Color(0x99000000),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: .min,
                children: [
                  const SizedBox(height: topShadowHeight),
                  _buildThumbnailStrip(currentPage, pageCount, isRTL),
                  const SizedBox(height: sliderThumbnailSpacing),
                  _buildSliderRow(currentPage, pageCount, isRTL),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThumbnailStrip(int currentPage, int pageCount, bool isRTL) {
    const selectedColor = Color(0xFF90CAF9);

    return SizedBox(
      height: UiConfig.thumbnailStripHeight,
      child: ListView.builder(
        controller: _state.thumbnailScrollController,
        reverse: isRTL,
        scrollDirection: .horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: pageCount,
        itemBuilder: (context, index) {
          final isCurrent = index == currentPage;
          return GestureDetector(
            onTap: () => _jumpToPage(index),
            child: Container(
              width: UiConfig.thumbnailStripWidth,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        borderRadius: .circular(6),
                        border: .all(
                          color: isCurrent ? selectedColor : Colors.white24,
                          width: isCurrent ? 2.5 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: .circular(6),
                        child: MangaImage(
                          image: LocalImage(path: _state.readInfo.images[index].path),
                          fit: .fitWidth,
                          maxBytes: 1024 * 50,
                          width: UiConfig.thumbnailStripWidth,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Material(
                    color: Colors.transparent,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                      ),
                      textAlign: .center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliderRow(int currentPage, int pageCount, bool isRTL) {
    final displayPage = currentPage + 1;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildNavButton(
              icon: Icons.skip_previous_rounded,
              onTap: isRTL
                  ? (currentPage < pageCount - 1 ? () => _jumpToPage(pageCount - 1) : null)
                  : (currentPage > 0 ? () => _jumpToPage(0) : null),
            ),
            const SizedBox(width: 4),
            _buildNavButton(
              icon: Icons.navigate_before_rounded,
              onTap: isRTL
                  ? (currentPage < pageCount - 1 ? () => _jumpToPage(currentPage + 1) : null)
                  : (currentPage > 0 ? () => _jumpToPage(currentPage - 1) : null),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withValues(alpha: 0.15),
                ),
                child: Directionality(
                  textDirection: isRTL ? .rtl : .ltr,
                  child: Slider(
                    min: 1,
                    max: pageCount.toDouble(),
                    value: displayPage.toDouble(),
                    onChanged: (v) {
                      _state.currentIndex = v.toInt() - 1;
                      _controller.update([_controller.bottomMenuId]);
                    },
                    onChangeEnd: (v) => _jumpToPage(v.toInt() - 1),
                  ),
                ),
              ),
            ),
            _buildNavButton(
              icon: Icons.navigate_next_rounded,
              onTap: isRTL
                  ? (currentPage > 0 ? () => _jumpToPage(currentPage - 1) : null)
                  : (currentPage < pageCount - 1 ? () => _jumpToPage(currentPage + 1) : null),
            ),
            const SizedBox(width: 4),
            _buildNavButton(
              icon: Icons.skip_next_rounded,
              onTap: isRTL
                  ? (currentPage > 0 ? () => _jumpToPage(0) : null)
                  : (currentPage < pageCount - 1 ? () => _jumpToPage(pageCount - 1) : null),
            ),
          ],
        ),
      ),
    );
  }

  void _jumpToPage(int index) {
    _state.currentIndex = index;
    if (readSetting.readingMode.value == ReadingMode.strip) {
      _controller.handleSlideEnd((index + 1).toDouble());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _state.pageController.jumpToPage(index);
      });
    }
    _controller.update([_controller.bottomMenuId, _controller.bottomRightInfoId]);
  }

  Widget _buildNavButton({required IconData icon, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: .circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: onTap != null ? Colors.white : Colors.white24, size: 22),
        ),
      ),
    );
  }

  Widget _buildPageInfoOverlay() {
    return Positioned(
      right: 0,
      bottom: 0,
      child: GetBuilder<ReaderPageController>(
        id: _controller.bottomRightInfoId,
        builder: (context) {
          return IgnorePointer(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x99000000),
                borderRadius: .circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: Text(
                  '${_state.currentIndex + 1} / ${_state.readInfo.pageCount}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFFE0E0E0), fontWeight: FontWeight.w500),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
