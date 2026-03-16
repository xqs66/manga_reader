import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/shared/extensions/widget_ext.dart';

import '../config/ui_config.dart';

class GroupHeader extends StatelessWidget {
  final Widget child;

  const GroupHeader({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: UiConfig.groupHeaderColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiConfig.groupHeaderRadius),
      ),
      child: SizedBox(
        height: UiConfig.groupHeaderHeight,
        child: child.center().paddingSymmetric(
          horizontal: UiConfig.groupHeaderPadding,
        ),
      ),
    );
  }
}
