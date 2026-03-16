import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/pages/reader/reader_page_controller.dart';
import 'package:manga_reader/wigets/manga_image.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:manga_reader/pages/reader/reader_page_state.dart';
import 'package:manga_reader/shared/extensions/widget_ext.dart';
import 'package:photo_view/photo_view.dart';

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
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          _buildReadMangaImages(),
          _buildBottomRightInfo(),
          _buildTopMenu(),
        ],
      ),
    );
  }

  Widget _buildReadMangaImages() {
    return PhotoViewGallery.builder(
      itemCount: 1,
      scrollDirection: Axis.vertical,
      builder: (_, _) {
        return PhotoViewGalleryPageOptions.customChild(
          controller: _state.photoViewController,
          initialScale: 1.0,
          minScale: 1.0,
          maxScale: 2.5,
          child: ScrollablePositionedList.builder(
            addAutomaticKeepAlives: true,
            itemCount: _state.readInfo.pageCount,
            itemScrollController: _state.itemScrollController,
            // initialScrollIndex: _state.readInfo.pageCount - 1,
            initialAlignment: 0,
            minCacheExtent: Get.height * 5, // TODO 可配置项
            itemBuilder: (context, index) {
              return GetBuilder<ReaderPageController>(
                id: '{ReadPageImage::$index}',
                builder: (context) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onTap: _controller.toggleMenuOpen,
                        child: MangaImage(
                          image: _state.readInfo.images[index],
                          height:
                              _state.imageContainerSizes[index]?.height ??
                              constraints.maxWidth *
                                  UiConfig.defaultImageContainerRadio,
                          width:
                              _state.imageContainerSizes[index]?.width ??
                              constraints.maxWidth,
                          fit: .fitWidth,
                          loadCompleteCallBack: (state) =>
                              _controller.onLoadCompleteCallBack(
                                index,
                                state,
                                Size(
                                  constraints.maxWidth,
                                  constraints.maxWidth * 2,
                                ),
                              ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
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
              _state.readInfo.title,
              style: UiConfig.readPageTitleStyle,
            ),
            centerTitle: true,
            backgroundColor: UiConfig.readMenuColor,
            foregroundColor: UiConfig.readPageForegroundColor,
            actions: [
              IconButton(onPressed: () => '', icon: Icon(Icons.settings)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomRightInfo() {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Material(
        child: Container(
          color: UiConfig.readMenuColor,
          height: 20,
          child: Row(
            mainAxisSize: .min,
            children: [
              Text(
                '${_state.currentIndex + 1}/${_state.readInfo.pageCount}',
                style: TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// return ColorFiltered(
//   colorFilter: ColorFilter.matrix(<double>[
//     0.2126,0.7152,0.0722,0,0,
//     0.2126,0.7152,0.0722,0,0,
//     0.2126,0.7152,0.0722,0,0,
//     0,0,0,1,0,
//   ]),
//   child: ExtendedImage.file(
//     state.images[index],
//     width: constraints.maxWidth,
//     fit: .fitWidth,
//   ),
// );
