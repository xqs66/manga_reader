import 'package:flutter/material.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/widgets/grid/grid_cover_image.dart';
import 'package:manga_reader/pages/mangas/layout/grid_layout.dart';

class MangaGridCard extends StatelessWidget {
  final Manga manga;
  final double width;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;

  const MangaGridCard({
    super.key,
    required this.manga,
    required this.width,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final h = GridLayout.coverHeight(width);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        width: width,
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
                    GridCoverImage(path: manga.cover.path, width: width, height: h),
                    _pageBadge(),
                    _titleOverlay(h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageBadge() {
    return Positioned(
      top: 6,
      left: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.black54, borderRadius: .circular(4)),
        child: Text(
          '${manga.pageCount}P',
          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _titleOverlay(double height) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: height * 0.26,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Color(0xCC000000)],
          ),
        ),
        alignment: .bottomLeft,
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
        child: Text(
          manga.title,
          maxLines: 2,
          overflow: .ellipsis,
          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500, height: 1.3),
        ),
      ),
    );
  }
}
