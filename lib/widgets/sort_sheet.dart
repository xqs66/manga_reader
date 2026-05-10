import 'package:flutter/material.dart';
import 'package:manga_reader/core/enums/sort_mode.dart';
import 'package:manga_reader/pages/mangas/mangas_page_controller.dart';

class SortSheet extends StatelessWidget {
  final MangasPageController controller;

  const SortSheet({super.key, required this.controller});

  static const _options = [
    (SortMode.title, '标题', Icons.sort_by_alpha_rounded),
    (SortMode.lastRead, '上次阅读时间', Icons.access_time_rounded),
    (SortMode.pageCount, '页数', Icons.filter_list_rounded),
    (SortMode.random, '随机', Icons.shuffle_rounded),
  ];

  static void show(BuildContext context, MangasPageController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SortSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? const Color(0xFF2C2C2C)
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    return StatefulBuilder(
      builder: (ctx, setState) {
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
                      _buildHeader(isDark),
                      const Divider(height: 1),
                      ..._options.map(
                        (opt) => _buildOption(context, opt, isDark, setState),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        '排序',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    (SortMode, String, IconData) opt,
    bool isDark,
    StateSetter setState,
  ) {
    final mode = opt.$1;
    final isCurrent = controller.state.sortMode == mode;
    final primary = Theme.of(context).colorScheme.primary;
    final textColor = isDark ? const Color(0xFFE0E0E0) : Colors.black87;

    return InkWell(
      onTap: () {
        controller.handleSort(mode);
        setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              opt.$3,
              size: 20,
              color: isCurrent
                  ? primary
                  : (isDark ? Colors.white54 : Colors.black54),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                opt.$2,
                style: TextStyle(
                  fontSize: 16,
                  color: isCurrent ? primary : textColor,
                ),
              ),
            ),
            if (isCurrent) _buildIndicator(mode, primary),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(SortMode mode, Color primary) {
    return Row(
      mainAxisSize: .min,
      children: [
        if (mode != SortMode.random)
          Icon(
            controller.state.sortAscending
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 18,
            color: primary,
          ),
        if (mode == SortMode.random)
          Icon(Icons.refresh_rounded, size: 18, color: primary),
        const SizedBox(width: 8),
        Icon(Icons.check_rounded, size: 20, color: primary),
      ],
    );
  }
}
