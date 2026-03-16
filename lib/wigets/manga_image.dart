import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../models/local_image.dart';
import '../shared/extensions/widget_ext.dart';

typedef LoadingWidgetBuilder = Widget Function(ExtendedImageState state);
typedef LoadFailedWidgetBuilder = Widget Function(ExtendedImageState state);
typedef LoadCompleteCallBack = void Function(ExtendedImageState state);

class MangaImage extends StatelessWidget {
  final LocalImage image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color backgroundColor;
  final LoadingWidgetBuilder? loadingWidgetBuilder;
  final LoadFailedWidgetBuilder? loadFailedWidgetBuilder;
  final LoadCompleteCallBack? loadCompleteCallBack;

  const MangaImage({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit = .fitWidth,
    this.backgroundColor = Colors.black,
    this.loadingWidgetBuilder,
    this.loadFailedWidgetBuilder,
    this.loadCompleteCallBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      color: backgroundColor,
      child: ExtendedImage.file(
        File(image.path),
        width: width,
        height: height,
        fit: fit,
        clearMemoryCacheWhenDispose: true,
        loadStateChanged: (state) {
          switch (state.extendedImageLoadState) {
            case .loading:
              return _buildDefaultLoadingWidget();
            case .completed:
              loadCompleteCallBack?.call(state);
              return _buildExtendedRawImage(state);
            case .failed:
              return Icon(Icons.broken_image);
          }
        },
      ),
    );
  }

  Widget _buildDefaultLoadingWidget() {
    return SizedBox(
      height: height ?? Get.width * 1.78,
      width: width ?? Get.width,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return LoadingAnimationWidget.waveDots(
            color: Colors.grey,
            size: constraints.maxWidth * 0.1,
          ).center();
        },
      ),
    );
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
      height: fittedSizes.destination.height == 0
          ? null
          : fittedSizes.destination.height,
      width: fittedSizes.destination.width == 0
          ? null
          : fittedSizes.destination.width,
      scale: state.extendedImageInfo?.scale ?? 1.0,
      fit: fit,
    );
  }
}
