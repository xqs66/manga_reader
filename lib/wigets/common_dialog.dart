import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/shared/extensions/text_ext.dart';

class CommonDialog extends StatelessWidget {
  final String title;
  final Widget? content;
  final bool isConfirmable;
  final void Function()? onConfirm;

  const CommonDialog({
    super.key,
    required this.title,
    this.isConfirmable = true,
    this.content,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 200),
        child: content,
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('取消')),
        TextButton(
          onPressed: isConfirmable ? onConfirm : null,
          child: Text(
            '确定',
          ).color(isConfirmable ? UiConfig.primaryColor : Colors.grey),
        ),
      ],
    );
  }
}
