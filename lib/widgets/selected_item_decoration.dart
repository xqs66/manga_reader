import 'package:flutter/material.dart';
import 'package:manga_reader/config/ui_config.dart';

class SelectedItemDecoration extends StatelessWidget {
  final bool isSelected;
  final Widget child;

  const SelectedItemDecoration({
    super.key,
    required this.isSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: isSelected
          ? BoxDecoration(
              borderRadius: .circular(12),
              border: Border.all(
                color: UiConfig.primaryColor.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: UiConfig.primaryColor.withValues(alpha: 0.25),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            )
          : null,
      child: child,
    );
  }
}
