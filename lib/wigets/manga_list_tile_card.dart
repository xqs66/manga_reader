import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/shared/extensions/text_ext.dart';
import 'package:manga_reader/shared/extensions/widget_ext.dart';
import 'package:manga_reader/wigets/loading_widget.dart';

import '../models/local_image.dart';
import '../models/manga.dart';
import '../shared/utils/file_util.dart';

class MangaListTileCard extends StatelessWidget {
  final Manga manga;
  final ActionPane? endActionPane;
  final void Function()? onTap;
  final void Function()? onLongPressed;

  const MangaListTileCard({
    super.key,
    required this.manga,
    this.endActionPane,
    this.onTap,
    this.onLongPressed,
  });

  // @override
  // Widget build(BuildContext context) {
  //   return Card(
  //     child: ListTile(
  //       leading: _buildCoverImage(manga.cover),
  //       minTileHeight: 100,
  //       title: Text(manga.title, maxLines: 2, overflow: .ellipsis),
  //       subtitle: Align(
  //         alignment: .centerRight,
  //         child: Text('${FileUtil.formatFileSize(manga.size)}'),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPressed,
      child: Slidable(
        endActionPane: endActionPane,
        child: Card(
          child: SizedBox(
            height: UiConfig.mangaListCardHeight,
            child: Row(
              children: [
                _buildCoverImage(manga.cover).paddingAll(5.0),
                Expanded(child: _buildMangaInfo().paddingAll(10.0)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage(LocalImage cover) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: .all(.circular(5.0)),
          child: ExtendedImage.file(
            File(cover.path),
            fit: .cover,
            width: constraints.maxHeight * 0.75,
            height: constraints.maxHeight,
            clearMemoryCacheIfFailed: true,
            loadStateChanged: (state) {
              switch (state.extendedImageLoadState) {
                case .loading:
                  return LoadingWidget(
                    width: constraints.maxHeight * 0.75,
                    height: constraints.maxHeight,
                  );
                case .completed:
                  ExtendedRawImage(
                    image: state.extendedImageInfo?.image,
                    fit: .cover,
                  );
                case .failed:
                  return Icon(Icons.broken_image);
              }
              return null;
            },
          ),
        );
      },
    );
  }

  Widget _buildMangaInfo() {
    return Column(
      mainAxisAlignment: .spaceBetween,
      children: [_buildTitle(), _buildInfoFooter()],
    );
  }

  Widget _buildTitle() {
    return Text(
      manga.title,
      maxLines: 2,
      overflow: .ellipsis,
      textAlign: .start,
      style: UiConfig.mangaCardTitleStyle,
    ).alignLeft();
  }

  Widget _buildInfoFooter() {
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Text(
          FileUtil.formatFileSize(manga.size),
          style: UiConfig.listTileSubtitleStyle,
        ),
        Text('${manga.pageCount}P', style: UiConfig.listTileSubtitleStyle),
      ],
    );
  }
}

class LongPressActionSheet {
  static void show({
    required BuildContext context,
    List<SheetAction>? actions,
  }) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          actions: [
            ...(actions ?? []).map(
              (action) => CupertinoActionSheetAction(
                onPressed: () async {
                  await action.onPressed();
                  Get.back();
                },
                child: Text(action.label).color(action.labelColor),
              ),
            ),
            CupertinoActionSheetAction(onPressed: Get.back, child: Text('取消')),
          ],
        );
      },
    );
  }
}

class SheetAction {
  final String label;
  final Future<void> Function() onPressed;
  final Color? labelColor;

  const SheetAction({
    required this.label,
    required this.onPressed,
    this.labelColor,
  });
}
