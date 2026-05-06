import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/core/extensions/text_ext.dart';

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
      shape: RoundedRectangleBorder(borderRadius: .circular(16)),
      title: Text(title, style: const TextStyle(fontSize: 17)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 250),
        child: content,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.only(bottom: 4, right: 8),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('取消'),
        ),
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
