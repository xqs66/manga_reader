import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:manga_reader/core/extensions/widget_ext.dart';
import 'package:manga_reader/ui/widgets/loading_widget.dart';

/// Shared cover-image widget used by both [MangaGridCard] and
/// [GroupGridCard] preview cells.
class GridCoverImage extends StatelessWidget {
  final String path;
  final double width;
  final double height;
  final Widget? placeholder;

  const GridCoverImage({
    super.key,
    required this.path,
    required this.width,
    required this.height,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return placeholder ?? Container(color: Colors.grey.shade800);
    }
    return ExtendedImage.file(
      File(path),
      fit: BoxFit.cover,
      width: width,
      height: height,
      cacheWidth: (width * 1.6).ceil(),
      clearMemoryCacheIfFailed: true,
      loadStateChanged: (state) {
        return switch (state.extendedImageLoadState) {
          LoadState.loading =>
            LoadingWidget(width: width, height: height, size: 20),
          LoadState.completed =>
            ExtendedRawImage(image: state.extendedImageInfo?.image, fit: BoxFit.cover).fadeIn(),
          LoadState.failed =>
            const Icon(Icons.broken_image_rounded, color: Colors.grey),
        };
      },
    );
  }
}
