import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/models/local_image.dart';
import 'package:manga_reader/core/mixin/scroll_handler.dart';
import 'package:manga_reader/ui/pages/reader/reader_page_controller.dart';
import 'package:manga_reader/settings/read_setting.dart';
import 'package:manga_reader/core/constants/constants.dart';
import 'package:manga_reader/ui/widgets/adjusted_image.dart';
import 'package:manga_reader/ui/widgets/manga_image.dart';
import 'package:manga_reader/ui/widgets/loading_widget.dart';
import 'package:manga_reader/ui/widgets/hit_accumulate_stack.dart';
import 'package:manga_reader/ui/widgets/styled_menu.dart';
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

  static const _overlayStyle = SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    statusBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.light,
  );

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReaderPageController>(
      id: _controller.pageId,
      builder: (_) => LayoutBuilder(
        builder: (_, constraints) {
          _state.onLayoutWidthChanged(constraints.maxWidth);
          final isStrip = readSetting.readingMode.value == ReadingMode.strip;
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) {
                _controller.persistToDb();
                Get.back();
              }
            },
            child: _buildPageBody(isStrip),
          );
        },
      ),
    );
  }

  Widget _buildPageBody(bool isStrip) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: Focus(
        focusNode: _controller.focusNode,
        autofocus: true,
        onKeyEvent: _controller.handleKeyEvent,
        child: Listener(
          onPointerSignal: _controller.handleMouseWheel,
          child: Container(
            color: Colors.black,
            child: Stack(
            children: [
              HitAccumulateStack(
                children: [
                  ScrollWrapper(
                    scrollEndDelay: 250,
                    builder: (_, handler) {
                      _controller.scrollState = handler;
                      return KeyedSubtree(
                        key: ValueKey(isStrip ? 'strip' : 'page'),
                        child: isStrip ? _buildStripMode() : _buildPageMode(),
                      );
                    },
                  ),
                  Positioned.fill(child: _buildTapZones()),
                ],
              ),
                _buildPageInfoOverlay(),
                _buildTopMenu(),
                _buildBottomMenu(),
                _buildLoadingIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return GetBuilder<ReaderPageController>(
      id: _controller.loadingImagesId,
      builder: (_) {
        if (_state.readInfo.images.isNotEmpty) return const SizedBox.shrink();
        return const SizedBox.expand(
          child: Center(child: LoadingWidget(height: 48, width: 48)),
        );
      },
    );
  }

  // ── Tap zones ──

  Widget _buildTapZones() {
    final sideFlex = ((1.0 - UiConfig.readerTapZoneCenterRatio) / 2 * 100)
        .round();
    final centerFlex = (UiConfig.readerTapZoneCenterRatio * 100).round();
    return Row(
      children: [
        Expanded(
          flex: sideFlex,
          child: GestureDetector(
            onTap: _controller.handleTapLeft,
            behavior: HitTestBehavior.opaque,
          ),
        ),
        Expanded(
          flex: centerFlex,
          child: GestureDetector(
            onTap: _controller.toggleMenuOpen,
            behavior: HitTestBehavior.opaque,
          ),
        ),
        Expanded(
          flex: sideFlex,
          child: GestureDetector(
            onTap: _controller.handleTapRight,
            behavior: HitTestBehavior.opaque,
          ),
        ),
      ],
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
                initialScrollIndex: _state.readInfo.lastReadIndex,
                initialAlignment: 0,
                minCacheExtent: Get.height * 5,
                itemBuilder: (context, index) => _buildImageItem(index),
                separatorBuilder: (_, _) => Obx(
                  () => SizedBox(
                    height: readSetting.imageSpacing.value.toDouble(),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImageItem(int index, {BoxFit fit = BoxFit.fitWidth}) {
    if (index >= _state.readInfo.images.length) return const SizedBox.shrink();
    return GetBuilder<ReaderPageController>(
      id: '{ReadPageImage::$index}',
      builder: (_) {
        return LayoutBuilder(
          builder: (_, constraints) {
            return Obx(() {
              final image = _buildStripImage(constraints, index, fit: fit);
              final child = readSetting.enableGrayscaleMode.value
                  ? ColorFiltered(
                      colorFilter: ColorFilter.matrix(
                        Constants.grayscaleMatrix,
                      ),
                      child: image,
                    )
                  : image;
              return AdjustedImage(
                contrast: readSetting.contrast.value,
                saturation: readSetting.saturation.value,
                child: child,
              );
            });
          },
        );
      },
    );
  }

  Widget _buildStripImage(
    BoxConstraints constraints,
    int index, {
    BoxFit fit = BoxFit.fitWidth,
  }) {
    if (index >= _state.readInfo.images.length) return const SizedBox.shrink();
    final stored = _state.imageContainerSizes[index];
    final useStored =
        stored != null && (stored.width - constraints.maxWidth).abs() < 1.0;
    return MangaImage(
      image: _state.readInfo.images[index],
      longPressActions: [
        StyledAction(
          label: '删除图片',
          isDestructive: true,
          onPressed: () => _controller.handleDeleteImage(index),
        ),
      ],
      height: useStored
          ? stored.height
          : constraints.maxWidth * UiConfig.defaultImageContainerRadio,
      width: useStored ? stored.width : constraints.maxWidth,
      fit: fit,
      loadCompleteCallBack: (state) => _controller.onLoadCompleteCallBack(
        index,
        state,
        Size(constraints.maxWidth, double.infinity),
      ),
    );
  }

  // ── Page mode ──

  Widget _buildPageMode() {
    final mode = readSetting.readingMode.value;
    final isHorizontal = mode.isHorizontal;
    final isRTL = mode.isRTL;

    return GetBuilder<ReaderPageController>(
      id: _controller.pageListId,
      builder: (_) {
        return PhotoViewGallery.builder(
          scrollDirection: isHorizontal ? .horizontal : .vertical,
          reverse: isRTL,
          itemCount: _controller.itemCount,
          pageController: _state.pageController,
          onPageChanged: _controller.handlePageChanged,
          builder: (context, index) => _buildGalleryItem(index, isRTL),
        );
      },
    );
  }

  PhotoViewGalleryPageOptions _buildGalleryItem(int index, bool isRTL) {
    final isDouble = readSetting.readingMode.value.isDoublePage;
    return PhotoViewGalleryPageOptions.customChild(
      controller: _state.photoViewController,
      initialScale: isDouble
          ? PhotoViewComputedScale.covered
          : PhotoViewComputedScale.contained,
      minScale: isDouble
          ? PhotoViewComputedScale.contained
          : PhotoViewComputedScale.contained,
      maxScale: 3.0,
      child: isDouble
          ? _buildDoublePageItem(index, isRTL)
          : _buildImageItem(index),
    );
  }

  Widget _buildDoublePageItem(int spreadIndex, bool isRTL) {
    final leftIdx = _controller.leftOfSpread(spreadIndex);
    final rightIdx = _controller.rightOfSpread(spreadIndex);
    return GetBuilder<ReaderPageController>(
      id: 'spread_$spreadIndex',
      builder: (_) {
        return Obx(() {
          final sp = readSetting.doublePageSpacing.value.toDouble();
          return LayoutBuilder(
            builder: (_, constraints) {
              final vpW = constraints.maxWidth;
              final vpH = constraints.maxHeight;
              double pageAspect(int idx) {
                final s = _state.imageContainerSizes[idx];
                // Use loaded size; fallback to safe minimum to avoid overflow
                if (s != null) return s.width / s.height;
                return 0.65;
              }

              final aLeft = pageAspect(leftIdx);
              final maxHeightAspect = rightIdx != null
                  ? (aLeft < pageAspect(rightIdx)
                        ? aLeft
                        : pageAspect(rightIdx))
                  : aLeft;
              final naturalW = vpH * maxHeightAspect;
              var imgW = naturalW;
              if (rightIdx != null && 2 * imgW + sp > vpW) {
                imgW = (vpW - sp) / 2;
              } else if (rightIdx == null && imgW > vpW) {
                imgW = vpW;
              }
              Widget image(int idx) =>
                  SizedBox(width: imgW, child: _buildImageItem(idx));
              if (rightIdx == null) return Center(child: image(leftIdx));
              return Row(
                mainAxisSize: .min,
                mainAxisAlignment: .center,
                children: isRTL
                    ? [image(rightIdx), SizedBox(width: sp), image(leftIdx)]
                    : [image(leftIdx), SizedBox(width: sp), image(rightIdx)],
              );
            },
          );
        });
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
          top: _state.isMenuOpen
              ? 0
              : -(UiConfig.topAreaMenuHeight + topPadding),
          height: UiConfig.topAreaMenuHeight + topPadding,
          width: Get.width,
          curve: Curves.easeOutCubic,
          duration: const Duration(milliseconds: 200),
          child: AnimatedOpacity(
            opacity: _state.isMenuOpen ? 1.0 : 0.0,
            curve: Curves.ease,
            duration: const Duration(milliseconds: 120),
            child: Container(
              padding: EdgeInsets.only(top: topPadding),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xE6000000),
                    Color(0x66000000),
                    Colors.transparent,
                  ],
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
                    onPressed: _controller.handleOpenMangaInfo,
                    icon: const Icon(Icons.info_outline_rounded),
                    tooltip: '漫画信息',
                  ),
                  IconButton(
                    onPressed: _controller.handleOpenSettings,
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
        final isRTL = readSetting.readingMode.value.isRTL;
        final isDouble = readSetting.readingMode.value.isDoublePage;
        final pageCount = _state.readInfo.pageCount;
        final currentPage = _state.currentIndex;
        final atFirst = isDouble
            ? _controller.currentSpread == 0
            : currentPage == 0;
        final atLast = isDouble
            ? _controller.currentSpread >= _controller.spreadCount - 1
            : currentPage >= pageCount - 1;
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
          duration: const Duration(milliseconds: 200),
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
                  _buildSliderRow(
                    currentPage,
                    pageCount,
                    isRTL,
                    atFirst: atFirst,
                    atLast: atLast,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThumbnailStrip(int currentPage, int pageCount, bool isRTL) {
    return SizedBox(
      height: UiConfig.thumbnailStripHeight,
      child: ListView.builder(
        controller: _state.thumbnailScrollController,
        reverse: isRTL,
        scrollDirection: .horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _state.readInfo.pageCount,
        itemBuilder: (_, index) => _buildThumbnailItem(index, currentPage),
      ),
    );
  }

  Widget _buildThumbnailItem(int index, int currentPage) {
    final isDouble = readSetting.readingMode.value.isDoublePage;
    final isCurrent = isDouble
        ? index == _controller.leftOfSpread(_controller.currentSpread) ||
              index == _controller.rightOfSpread(_controller.currentSpread)
        : index == currentPage;
    return GestureDetector(
      onTap: () => _controller.handleJumpToPage(index),
      child: Container(
        width: UiConfig.thumbnailStripWidth,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          children: [
            _buildThumbnailImage(index, isCurrent),
            const SizedBox(height: 4),
            _buildPageNumber(index, isCurrent),
          ],
        ),
      ),
    );
  }

  static const _selectedColor = Color(0xFF9990F9);

  Widget _buildThumbnailImage(int index, bool isCurrent) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: .circular(6),
          border: .all(
            color: isCurrent ? _selectedColor : Colors.white24,
            width: isCurrent ? 2.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: .circular(6),
          child: index < _state.readInfo.images.length
              ? MangaImage(
                  image: LocalImage(path: _state.readInfo.images[index].path),
                  fit: .fitWidth,
                  maxBytes: 1024 * 50,
                  width: UiConfig.thumbnailStripWidth,
                  height: double.infinity,
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildPageNumber(int index, bool isCurrent) {
    return Material(
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
    );
  }

  Widget _buildSliderRow(
    int currentPage,
    int pageCount,
    bool isRTL, {
    bool atFirst = false,
    bool atLast = false,
  }) {
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
                  ? (!atLast
                        ? () => _controller.handleJumpToPage(pageCount - 1)
                        : null)
                  : (!atFirst ? () => _controller.handleJumpToPage(0) : null),
            ),
            const SizedBox(width: 4),
            _buildNavButton(
              icon: Icons.navigate_before_rounded,
              onTap: isRTL
                  ? (!atLast
                        ? () => _controller.handleJumpToPage(currentPage + 1)
                        : null)
                  : (!atFirst
                        ? () => _controller.handleJumpToPage(currentPage - 1)
                        : null),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
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
                    onChanged: _controller.handleSliderChanged,
                    onChangeEnd: _controller.handleSliderChangeEnd,
                  ),
                ),
              ),
            ),
            _buildNavButton(
              icon: Icons.navigate_next_rounded,
              onTap: isRTL
                  ? (!atFirst
                        ? () => _controller.handleJumpToPage(currentPage - 1)
                        : null)
                  : (!atLast
                        ? () => _controller.handleJumpToPage(currentPage + 1)
                        : null),
            ),
            const SizedBox(width: 4),
            _buildNavButton(
              icon: Icons.skip_next_rounded,
              onTap: isRTL
                  ? (!atFirst ? () => _controller.handleJumpToPage(0) : null)
                  : (!atLast
                        ? () => _controller.handleJumpToPage(pageCount - 1)
                        : null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({required IconData icon, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: .circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            color: onTap != null ? Colors.white : Colors.white24,
            size: 22,
          ),
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
              margin: const EdgeInsets.only(right: 10, bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0x99000000),
                borderRadius: .circular(10),
              ),
              child: Material(
                color: Colors.transparent,
                child: Row(
                  mainAxisSize: .min,
                  children: [
                    Text(
                      _controller.currentTime,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFFE0E0E0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_controller.batteryLevel}%',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFFE0E0E0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _controller.pageIndicator,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFE0E0E0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
