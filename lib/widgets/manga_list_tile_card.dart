import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/core/extensions/widget_ext.dart';
import 'package:manga_reader/widgets/loading_widget.dart';

import '../models/local_image.dart';
import '../models/manga.dart';
import '../core/utils/file_util.dart';

class MangaListTileCard extends StatelessWidget {
  final Manga manga;
  final ActionPane? endActionPane;
  final bool buildCover;
  final void Function()? onTap;
  final void Function()? onLongPressed;

  const MangaListTileCard({
    super.key,
    required this.manga,
    this.endActionPane,
    this.onTap,
    this.buildCover = true,
    this.onLongPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPressed,
      child: Slidable(
        endActionPane: endActionPane,
        child: Card(
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: .circular(12),
          ),
          child: SizedBox(
            height: UiConfig.mangaListCardHeight,
            child: Row(
              children: [
                _buildCoverImage(manga.cover).paddingAll(5),
                Expanded(child: _buildMangaInfo().paddingAll(10)),
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
          borderRadius: .circular(8),
          child: buildCover
              ? ExtendedImage.file(
                  File(cover.path),
                  fit: .cover,
                  width: constraints.maxHeight * 0.72,
                  height: constraints.maxHeight,
                  clearMemoryCacheIfFailed: true,
                  loadStateChanged: (state) {
                    switch (state.extendedImageLoadState) {
                      case .loading:
                        return LoadingWidget(
                          width: constraints.maxHeight * 0.72,
                          height: constraints.maxHeight,
                        );
                      case .completed:
                        return ExtendedRawImage(
                          image: state.extendedImageInfo?.image,
                          fit: .cover,
                        ).fadeIn();
                      case .failed:
                        return const Icon(Icons.broken_image_rounded);
                    }
                  },
                )
              : const SizedBox(
                  width:
                      (UiConfig.mangaListCardHeight -
                          2 * UiConfig.mangaListCardPadding) *
                      0.72,
                ),
        );
      },
    );
  }

  Widget _buildMangaInfo() {
    return Column(
      crossAxisAlignment: .start,
      mainAxisAlignment: .spaceBetween,
      children: [
        _buildTitle(),
        _buildInfoFooter(),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      manga.title,
      maxLines: 2,
      overflow: .ellipsis,
      textAlign: .start,
      style: UiConfig.mangaCardTitleStyle,
    );
  }

  Widget _buildInfoFooter() {
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.image_rounded, size: 13, color: Colors.grey.shade500),
            const SizedBox(width: 3),
            Text('${manga.pageCount}P', style: UiConfig.listTileSubtitleStyle),
          ],
        ),
        Text(
          FileUtil.formatFileSize(manga.size),
          style: UiConfig.listTileSubtitleStyle,
        ),
      ],
    );
  }
}
