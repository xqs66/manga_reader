import 'package:flutter/material.dart';
import 'package:manga_reader/wigets/common_dialog.dart';

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
        physics: const BouncingScrollPhysics(),
        itemCount: widget.items.length,
        itemBuilder: (context, index) => Container(
          decoration: selectedIndex == index
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  color: Color(0x3B000000),
                )
              : null,
          child: ListTile(
            title: Text(widget.items[index]),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            textColor: const Color(0xFF323232),
            selected: selectedIndex == index,
            selectedColor: Colors.black,
            onTap: () {
              setState(() {
                selectedIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
