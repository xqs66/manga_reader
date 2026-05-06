import 'package:flutter/material.dart';

class SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedCount;
  final String itemLabel;
  final VoidCallback onClear;
  final VoidCallback? onSelectAll;
  final bool isAllSelected;

  const SelectionAppBar({
    super.key,
    required this.selectedCount,
    this.itemLabel = '项',
    required this.onClear,
    this.onSelectAll,
    this.isAllSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        onPressed: onClear,
        icon: const Icon(Icons.close_rounded),
      ),
      title: Text('已选 $selectedCount $itemLabel'),
      centerTitle: true,
      actions: [
        if (onSelectAll != null)
          IconButton(
            onPressed: onSelectAll,
            icon: Icon(
              isAllSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
            ),
            tooltip: isAllSelected ? '取消全选' : '全选',
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
