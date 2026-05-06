import 'package:flutter/material.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/core/extensions/string_ext.dart';

class PathSelectorTile extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String? path;
  final String hint;
  final bool isSelected;
  final VoidCallback onTap;

  const PathSelectorTile({
    super.key,
    required this.icon,
    this.label,
    this.path,
    required this.hint,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: .circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: .circular(10),
            border: .all(
              color: isSelected
                  ? UiConfig.primaryColor.withValues(alpha: 0.4)
                  : Colors.grey.shade300,
            ),
            color: isSelected
                ? UiConfig.primaryColor.withValues(alpha: 0.04)
                : Colors.grey.shade50,
          ),
          child: Row(
            children: [
              if (label != null) ...[
                Text(label!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
              ],
              Icon(icon,
                  size: 20,
                  color: isSelected ? UiConfig.primaryColor : Colors.grey.shade500),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isSelected ? path!.displayPath() : hint,
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? Colors.black87 : Colors.grey.shade500,
                  ),
                ),
              ),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
                size: 20,
                color: isSelected ? UiConfig.primaryColor : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
