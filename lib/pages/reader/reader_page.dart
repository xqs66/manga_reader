import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/pages/reader/reader_page_controller.dart';
import 'package:manga_reader/pages/settings/read/read_settings_page.dart';
import 'package:manga_reader/settings/read_setting.dart';
import 'package:manga_reader/shared/constants/constants.dart';
import 'package:manga_reader/wigets/manga_image.dart';
import 'package:manga_reader/wigets/manga_list_tile_card.dart';
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
          child: SafeArea(
            child: Container(
              color: Colors.white,
              child: SizedBox(
                height: 50,
                width: 100,
                child: Stack(
                  children: [
                    _buildReadMangaImages(),
                    _buildBottomRightInfo(),
                    _buildTopMenu(),
                    _buildBottomMenu(),
                  ],
                ),
              ),
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
                // initialScrollIndex: _state.readInfo.pageCount - 1,
                initialAlignment: 0,
                minCacheExtent: Get.height * 5, // TODO 可配置项
                itemBuilder: (context, index) => _buildImageItem(index),
                separatorBuilder: (_, _) => Obx(
                  () => SizedBox(
                    height: readSetting.imageSpacing.value.toDouble(),
                  ),
                )
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
    return GetBuilder<ReaderPageController>(
      id: _controller.topMenuId,
      builder: (_) {
        return AnimatedPositioned(
          top: 0,
          height: _state.isMenuOpen ? UiConfig.topAreaMenuHeight : 0,
          width: Get.width,
          curve: Curves.ease,
          duration: Duration(milliseconds: 200),
          child: AppBar(
            title: Text(
              _state.readInfo.mangaInfo.title,
              style: UiConfig.readPageTitleStyle,
            ),
            centerTitle: true,
            backgroundColor: UiConfig.readMenuColor,
            foregroundColor: UiConfig.readPageForegroundColor,
            actions: [
              IconButton(
                onPressed: () {
                  Get.bottomSheet(
                    ClipRRect(
                      borderRadius: .only(
                        topLeft: .circular(16),
                        topRight: .circular(16),
                      ),
                      child: ReadSettingsPage(isBottomSheet: true),
                    ),
                  );
                  _controller.toggleMenuOpen();
                },
                icon: Icon(Icons.settings),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomMenu() {
    return GetBuilder<ReaderPageController>(
      id: _controller.bottomMenuId,
      builder: (_) {
        return AnimatedPositioned(
          bottom: _state.isMenuOpen ? 0 : -UiConfig.bottomAreaMenuHeight,
          height: _state.isMenuOpen ? UiConfig.bottomAreaMenuHeight : 0,
          width: Get.width,
          curve: Curves.ease,
          duration: Duration(milliseconds: 200),
          child: Material(
            color: Colors.transparent,
            child: Container(
              color: UiConfig.readMenuColor,
              child: Row(
                children: [
                  Text(
                    (_state.currentIndex + 1).toString(),
                    style: TextStyle(color: Colors.white),
                  ),
                  Expanded(
                    child: Slider(
                      min: 1,
                      max: _state.readInfo.pageCount.toDouble(),
                      value: (_state.currentIndex + 1).toDouble(),
                      onChanged: _controller.handleSlide,
                      onChangeEnd: _controller.handleSlideEnd,
                    ),
                  ),
                  Text(
                    _state.readInfo.pageCount.toString(),
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ).paddingSymmetric(horizontal: 20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomRightInfo() {
    return Positioned(
      right: 0,
      bottom: 0,
      child: GetBuilder<ReaderPageController>(
        id: _controller.bottomRightInfoId,
        builder: (context) {
          return Material(
            child: Container(
              color: const Color(0x8C000000),
              height: 15,
              child: Row(
                mainAxisSize: .min,
                children: [
                  Text(
                    '${_state.currentIndex + 1}/${_state.readInfo.pageCount}',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                ],
              ).paddingSymmetric(horizontal: 20),
            ),
          );
        },
      ),
    );
  }
}
