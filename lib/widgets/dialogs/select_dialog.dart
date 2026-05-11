import 'package:flutter/material.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/widgets/dialogs/common_dialog.dart';

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
    return CommonDialog(
      onConfirm: () {
        if (selectedIndex == null) return;
        widget.onConfirm?.call(selectedIndex!);
      },
      title: widget.title,
      isConfirmable: selectedIndex != null,
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
        child: ListView.builder(
          shrinkWrap: true,
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
        ),
      ),
    );
  }
}
