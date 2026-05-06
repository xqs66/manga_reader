import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StyledActionSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required List<StyledAction> actions,
    String? title,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActionSheetContent(title: title, actions: actions),
    );
  }
}

class _ActionSheetContent extends StatelessWidget {
  final String? title;
  final List<StyledAction> actions;

  const _ActionSheetContent({this.title, required this.actions});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final dividerColor = isDark ? Colors.white12 : Colors.black12;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: .min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: .circular(14),
              ),
              child: Column(
                mainAxisSize: .min,
                children: [
                  if (title != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 18, bottom: 8),
                      child: Text(
                        title!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ),
                    Divider(height: 1, color: dividerColor),
                  ],
                  ...actions.asMap().entries.map((entry) {
                    final isFirst = entry.key == 0 && title == null;
                    final isLast = entry.key == actions.length - 1;
                    return Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.vertical(
                            top: isFirst ? const Radius.circular(14) : Radius.zero,
                            bottom: isLast ? const Radius.circular(14) : Radius.zero,
                          ),
                          onTap: () {
                            Get.back();
                            entry.value.onPressed.call();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              entry.value.label,
                              textAlign: .center,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                color: entry.value.isDestructive
                                    ? Colors.red.shade400
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                          ),
                        ),
                        if (!isLast) Divider(height: 1, color: dividerColor),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: bg, borderRadius: .circular(14)),
              child: InkWell(
                borderRadius: .circular(14),
                onTap: () => Get.back(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    '取消',
                    textAlign: .center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StyledAction {
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  const StyledAction({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });
}

/// Replacement for default [PopupMenuButton] with consistent styling.
class StyledPopupMenu<T> extends StatelessWidget {
  final List<StyledPopupItem<T>> items;
  final Widget child;

  const StyledPopupMenu({
    super.key,
    required this.items,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuButton<T>(
      offset: const Offset(0, 8),
      elevation: 8,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(borderRadius: .circular(14)),
      color: isDark ? const Color(0xFF3A3A3A) : Colors.white,
      surfaceTintColor: Colors.transparent,
      onSelected: (value) {
        final item = items.firstWhere((i) => i.value == value);
        item.onSelected.call(value);
      },
      itemBuilder: (_) => items.map((item) {
        return PopupMenuItem<T>(
          value: item.value,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 20, color: item.isSelected ? Theme.of(context).colorScheme.primary : null),
                const SizedBox(width: 12),
              ],
              Text(
                item.label,
                style: TextStyle(
                  fontWeight: item.isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: child,
    );
  }
}

class StyledPopupItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final bool isSelected;
  final void Function(T) onSelected;

  const StyledPopupItem({
    required this.value,
    required this.label,
    this.icon,
    this.isSelected = false,
    required this.onSelected,
  });
}
