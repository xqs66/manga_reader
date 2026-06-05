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

  static final _borderColor = UiConfig.primaryColor.withValues(alpha: 0.5);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: .circular(12),
        border: Border.all(
          color: isSelected ? _borderColor : Colors.transparent,
          width: 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: UiConfig.primaryColor.withValues(alpha: 0.25),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
