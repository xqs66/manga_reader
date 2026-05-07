import 'package:flutter/material.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/widgets/dialogs/common_dialog.dart';

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
      content: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: isSelected
                ? BoxDecoration(
                    borderRadius: .circular(12),
                    color: UiConfig.primaryColor.withValues(alpha: 0.1),
                  )
                : null,
            child: ListTile(
              leading: isSelected
                  ? const Icon(Icons.check_rounded, color: UiConfig.primaryColor)
                  : null,
              title: Text(
                widget.items[index],
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              shape: RoundedRectangleBorder(borderRadius: .circular(12)),
              selected: isSelected,
              selectedTileColor: UiConfig.primaryColor.withValues(alpha: 0.05),
              onTap: () {
                setState(() {
                  selectedIndex = index;
                });
              },
            ),
          );
        },
      ),
    );
  }
}
