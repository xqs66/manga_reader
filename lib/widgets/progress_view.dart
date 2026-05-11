import 'package:flutter/material.dart';

class ProgressView extends StatelessWidget {
  final int current;
  final int total;
  final String? label;
  final EdgeInsetsGeometry padding;

  const ProgressView({
    super.key,
    required this.current,
    required this.total,
    this.label,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: .min,
        children: [
          if (label != null) ...[
            Text(label!, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
          ],
          ClipRRect(
            borderRadius: .circular(4),
            child: LinearProgressIndicator(value: progress, minHeight: 6),
          ),
          const SizedBox(height: 8),
          Text('$current / $total', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
