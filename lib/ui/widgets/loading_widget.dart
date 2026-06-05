import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:manga_reader/core/extensions/widget_ext.dart';

class LoadingWidget extends StatelessWidget {
  final double height;
  final double width;
  final double? size;

  const LoadingWidget({
    super.key,
    required this.height,
    required this.width,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: LoadingAnimationWidget.waveDots(
        color: Colors.grey,
        size: size ?? 24,
      ).center(),
    );
  }
}