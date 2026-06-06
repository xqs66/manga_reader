import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/core/extensions/widget_ext.dart';
import 'package:manga_reader/models/local_image.dart';
import 'package:manga_reader/ui/widgets/loading_widget.dart';
import 'package:manga_reader/ui/widgets/styled_menu.dart';

typedef LoadingWidgetBuilder = Widget Function(ExtendedImageState state);
typedef LoadFailedWidgetBuilder = Widget Function(ExtendedImageState state);
typedef LoadCompleteCallBack = void Function(ExtendedImageState state);

class MangaImage extends StatelessWidget {
  final LocalImage image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? maxBytes;
  final Color backgroundColor;
  final void Function()? onLongPress;
  final List<StyledAction>? longPressActions;
  final LoadingWidgetBuilder? loadingWidgetBuilder;
  final LoadFailedWidgetBuilder? loadFailedWidgetBuilder;
  final LoadCompleteCallBack? loadCompleteCallBack;

  const MangaImage({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit = .fitWidth,
    this.maxBytes,
    this.backgroundColor = Colors.black,
    this.onLongPress,
    this.longPressActions,
    this.loadingWidgetBuilder,
    this.loadFailedWidgetBuilder,
    this.loadCompleteCallBack,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress:
          onLongPress ??
          () => StyledActionSheet.show(
            context: context,
            actions: longPressActions ?? [],
          ),
      child: Container(
        height: height,
        width: width,
        color: backgroundColor,
        child: image.isRemote
            ? ExtendedImage.network(
                image.url!,
                headers: image.headers,
                cache: true,
                timeLimit: const Duration(seconds: 60),
                width: width,
                height: height,
                fit: fit,
                maxBytes: maxBytes,
                loadStateChanged: _loadStateChanged,
              )
            : ExtendedImage.file(
                File(image.path!),
                width: width,
                height: height,
                fit: fit,
                maxBytes: maxBytes,
                loadStateChanged: _loadStateChanged,
              ),
      ),
    );
  }

  Widget? _loadStateChanged(ExtendedImageState state) {
    switch (state.extendedImageLoadState) {
      case .loading:
        return LoadingWidget(
          height: height ?? Get.width * 1.78,
          width: width ?? Get.width,
          size: 28,
        );
      case .completed:
        loadCompleteCallBack?.call(state);
        return _buildExtendedRawImage(state).fadeIn();
      case .failed:
        return const Icon(Icons.broken_image);
    }
  }

  Widget _buildExtendedRawImage(ExtendedImageState state) {
    FittedSizes fittedSizes = applyBoxFit(
      fit,
      Size(
        state.extendedImageInfo!.image.width.toDouble(),
        state.extendedImageInfo!.image.height.toDouble(),
      ),
      Size(width ?? double.infinity, height ?? double.infinity),
    );

    return ExtendedRawImage(
      image: state.extendedImageInfo?.image,
      width: fittedSizes.destination.width == 0
          ? null
          : fittedSizes.destination.width,
      height: fittedSizes.destination.height == 0
          ? null
          : fittedSizes.destination.height,
      scale: state.extendedImageInfo?.scale ?? 1.0,
      fit: fit,
    ).fadeIn();
  }
}
