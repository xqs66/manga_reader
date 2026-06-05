import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:manga_reader/config/ui_config.dart';

class SelectionAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const SelectionAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });
}

class SelectionBottomBar extends StatelessWidget {
  final int selectedCount;
  final String itemLabel;
  final List<SelectionAction> actions;

  const SelectionBottomBar({
    super.key,
    required this.selectedCount,
    this.itemLabel = '项',
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedCount == 0) return const SizedBox.shrink();

    final view = PlatformDispatcher.instance.views.first;
    final bottomInset = view.padding.bottom / view.devicePixelRatio;

    return BottomAppBar(
      height: UiConfig.bottomBarHeight + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Row(
        mainAxisAlignment: .spaceEvenly,
        children: actions.map((action) {
          return TextButton.icon(
            onPressed: action.onPressed,
            icon: Icon(action.icon, color: action.color),
            label: Text(action.label, style: TextStyle(color: action.color)),
          );
        }).toList(),
      ),
    );
  }
}
