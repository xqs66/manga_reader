import 'package:flutter/material.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/ui/layout/grid/components/grid_cover_image.dart';
import 'package:manga_reader/ui/layout/grid/grid_layout.dart';

class GroupGridCard extends StatelessWidget {
  final String groupName;
  final List<Manga> previewMangas;
  final int totalCount;
  final double width;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const GroupGridCard({
    super.key,
    required this.groupName,
    required this.previewMangas,
    required this.totalCount,
    required this.width,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final h = GridLayout.coverHeight(width);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: .circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            ClipRRect(
              borderRadius: .circular(10),
              child: SizedBox(
                width: width,
                height: h,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildPreviewGrid(width, h, Theme.of(context).colorScheme.surfaceContainerHighest),
                    _labelBar(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewGrid(double totalWidth, double totalHeight, Color bg) {
    if (previewMangas.isEmpty) {
      return Container(color: bg);
    }
    final halfW = (totalWidth - 2) / 2;
    final halfH = (totalHeight - 2) / 2;
    final cells = [
      (previewMangas.elementAtOrNull(0), const BorderRadius.only(topLeft: Radius.circular(10))),
      (previewMangas.elementAtOrNull(1), const BorderRadius.only(topRight: Radius.circular(10))),
      (previewMangas.elementAtOrNull(2), BorderRadius.zero),
      (previewMangas.elementAtOrNull(3), const BorderRadius.only(bottomRight: Radius.circular(10))),
    ];

    return Column(
      children: [
        Row(children: [
          _cell(cells[0].$1, halfW, halfH, cells[0].$2, bg),
          const SizedBox(width: 2),
          _cell(cells[1].$1, halfW, halfH, cells[1].$2, bg),
        ]),
        const SizedBox(height: 2),
        Row(children: [
          _cell(cells[2].$1, halfW, halfH, cells[2].$2, bg),
          const SizedBox(width: 2),
          _cell(cells[3].$1, halfW, halfH, cells[3].$2, bg),
        ]),
      ],
    );
  }

  Widget _cell(Manga? manga, double w, double h, BorderRadius br, Color bg) {
    return ClipRRect(
      borderRadius: br,
      child: SizedBox(
        width: w,
        height: h,
        child: manga != null
            ? GridCoverImage(
                path: manga.cover.path,
                url: manga.cover.url,
                headers: manga.cover.headers,
                width: w,
                height: h,
                placeholder: Container(color: bg),
              )
            : Container(color: bg),
      ),
    );
  }

  Widget _labelBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 42,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Color(0xCC000000)],
          ),
        ),
        alignment: .bottomLeft,
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
        child: Row(
          children: [
            Expanded(
              child: Text(groupName, maxLines: 1, overflow: .ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            Text('$totalCount', style: const TextStyle(fontSize: 11, color: Color(0xFFBDBDBD))),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
