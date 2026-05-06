import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/core/extensions/widget_ext.dart';

import '../config/ui_config.dart';

class GroupHeader extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GroupHeader({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Card(
          elevation: 0,
          color: UiConfig.groupHeaderColor,
          shape: RoundedRectangleBorder(
            borderRadius: .circular(UiConfig.groupHeaderRadius),
            side: BorderSide(
              color: UiConfig.groupHeaderColor.withValues(alpha: 0.8),
            ),
          ),
          child: SizedBox(
            height: UiConfig.groupHeaderHeight,
            width: Get.width * 0.5,
            child: child.center().paddingSymmetric(
              horizontal: UiConfig.groupHeaderPadding,
            ),
          ),
        ),
      ),
    );
  }
}
