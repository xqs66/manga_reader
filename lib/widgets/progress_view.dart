import 'package:flutter/material.dart';

class ProgressView extends StatelessWidget {
  final int current;
  final int total;
  final String? label;

  const ProgressView({
    super.key,
    required this.current,
    required this.total,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: .min,
          children: [
            if (label != null) ...[
              Text(label!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
            ],
            ClipRRect(
              borderRadius: .circular(4),
              child: LinearProgressIndicator(value: progress, minHeight: 8),
            ),
            const SizedBox(height: 16),
            Text('$current / $total',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
