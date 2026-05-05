import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/pages/reader/reader_page_controller.dart';
import 'package:manga_reader/pages/settings/read/read_settings_page.dart';
import 'package:manga_reader/settings/read_setting.dart';
import 'package:manga_reader/shared/constants/constants.dart';
import 'package:manga_reader/widgets/manga_image.dart';
import 'package:manga_reader/widgets/manga_list_tile_card.dart';
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
                _buildReadMangaImages(),
                _buildPageInfoOverlay(),
                _buildTopMenu(),
                _buildBottomMenu(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReadMangaImages() {
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

  Widget _buildImageItem(int index) {
    return GetBuilder<ReaderPageController>(
      id: '{ReadPageImage::$index}',
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTap: _controller.toggleMenuOpen,
              child: Obx(
                () => readSetting.enableGrayscaleMode.value
                    ? ColorFiltered(
                        colorFilter: ColorFilter.matrix(
                          Constants.grayscaleMatrix,
                        ),
                        child: _buildImage(constraints, index),
                      )
                    : _buildImage(constraints, index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImage(BoxConstraints constraints, index) {
    return MangaImage(
      image: _state.readInfo.images[index],
      longPressActions: [
        SheetAction(
          label: '删除图片',
          labelColor: Colors.red,
          onPressed: () => _controller.handleDeleteImage(index),
        ),
      ],
      height:
          _state.imageContainerSizes[index]?.height ??
          constraints.maxWidth * UiConfig.defaultImageContainerRadio,
      width: _state.imageContainerSizes[index]?.width ?? constraints.maxWidth,
      fit: .fitWidth,
      loadCompleteCallBack: (state) => _controller.onLoadCompleteCallBack(
        index,
        state,
        Size(constraints.maxWidth, double.infinity),
      ),
    );
  }

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
          duration: const Duration(milliseconds: 250),
          child: AnimatedOpacity(
            opacity: _state.isMenuOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
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

  Widget _buildBottomMenu() {
    final bottomPadding = readSetting.enableImmersiveMode.value
        ? 0.0
        : context.mediaQuery.padding.bottom;

    return GetBuilder<ReaderPageController>(
      id: _controller.bottomMenuId,
      builder: (_) {
        final pageCount = _state.readInfo.pageCount;
        final currentPage = _state.currentIndex + 1;

        return AnimatedPositioned(
          bottom:
              _state.isMenuOpen ? 0 : -(UiConfig.bottomAreaMenuHeight + bottomPadding),
          height: UiConfig.bottomAreaMenuHeight + bottomPadding,
          width: Get.width,
          curve: Curves.easeOutCubic,
          duration: const Duration(milliseconds: 250),
          child: AnimatedOpacity(
            opacity: _state.isMenuOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: bottomPadding,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xE6000000),
                    Color(0x66000000),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: Row(
                children: [
                  _buildNavButton(
                    icon: Icons.skip_previous_rounded,
                    onTap: currentPage > 1
                        ? () => _controller.handleSlideEnd(1)
                        : null,
                  ),
                  const SizedBox(width: 4),
                  _buildNavButton(
                    icon: Icons.navigate_before_rounded,
                    onTap: currentPage > 1
                        ? () => _controller.handleSlideEnd(currentPage - 1)
                        : null,
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
                      child: Slider(
                        min: 1,
                        max: pageCount.toDouble(),
                        value: currentPage.toDouble(),
                        onChanged: _controller.handleSlide,
                        onChangeEnd: _controller.handleSlideEnd,
                      ),
                    ),
                  ),
                  _buildNavButton(
                    icon: Icons.navigate_next_rounded,
                    onTap: currentPage < pageCount
                        ? () => _controller.handleSlideEnd(currentPage + 1)
                        : null,
                  ),
                  const SizedBox(width: 4),
                  _buildNavButton(
                    icon: Icons.skip_next_rounded,
                    onTap: currentPage < pageCount
                        ? () => _controller.handleSlideEnd(pageCount.toDouble())
                        : null,
                  ),
                ],
              ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
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
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x99000000),
                  borderRadius: .circular(12),
                ),
                child: Text(
                  '${_state.currentIndex + 1} / ${_state.readInfo.pageCount}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFE0E0E0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
