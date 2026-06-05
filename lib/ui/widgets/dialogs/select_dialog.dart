import 'dart:math';

import 'package:flutter/material.dart';
import 'package:manga_reader/config/ui_config.dart';

/// A generic single-selection dialog. Shows [items] in a scrollable list
/// with a radio-style check. Confirming calls [onConfirm] with the index.
class SelectDialog extends StatefulWidget {
  final List<String> items;
  final String title;
  final void Function(int)? onConfirm;

  const SelectDialog({
    super.key,
    required this.items,
    required this.title,
    this.onConfirm,
  });

  @override
  State<SelectDialog> createState() => _SelectDialogState();
}

class _SelectDialogState extends State<SelectDialog> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final maxH = min(MediaQuery.of(context).size.height * 0.4, 350.0);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: .circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 17)),
            const SizedBox(height: 12),
            SizedBox(height: maxH, child: _buildList()),
            const SizedBox(height: 8),
            Align(
              alignment: .centerRight,
              child: Row(
                mainAxisSize: .min,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: selectedIndex == null
                        ? null
                        : () {
                            widget.onConfirm?.call(selectedIndex!);
                            Navigator.pop(context);
                          },
                    child: Text('确定', style: TextStyle(color: selectedIndex == null ? Colors.grey : UiConfig.primaryColor)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final isSelected = selectedIndex == index;
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 4),
          shape: RoundedRectangleBorder(
            borderRadius: .circular(12),
            side: BorderSide(
              color: isSelected ? UiConfig.primaryColor.withValues(alpha: 0.4) : Colors.transparent,
            ),
          ),
          color: isSelected ? UiConfig.primaryColor.withValues(alpha: 0.08) : Colors.transparent,
          child: ListTile(
            leading: Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? UiConfig.primaryColor : Colors.grey.shade400,
              size: 22,
            ),
            title: Text(
              widget.items[index],
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            shape: RoundedRectangleBorder(borderRadius: .circular(12)),
            onTap: () => setState(() => selectedIndex = index),
          ),
        );
      },
    );
  }
}
