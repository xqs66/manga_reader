import 'package:flutter/material.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final void Function()? onConfirm;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消'),
        ),
        TextButton(onPressed: onConfirm, child: Text('确定')),
      ],
    );
  }
}
