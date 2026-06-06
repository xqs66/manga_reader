import 'package:flutter/material.dart';
import 'package:manga_reader/core/utils/file_util.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/service/local_manga_service.dart';

class MangaInfoSheet extends StatelessWidget {
  final Manga manga;

  const MangaInfoSheet({super.key, required this.manga});

  @override
  Widget build(BuildContext context) {
    final typeName = manga.path.endsWith('.epub')
        ? 'EPUB 电子书'
        : localMangaService.isZipFile(manga.path)
            ? 'ZIP 压缩包'
            : '文件夹';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A);
    final subtitleColor = isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575);

    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      color: bgColor,
      child: SafeArea(
        child: Column(
          mainAxisSize: .min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: .circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('漫画信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildInfoRow('名称', manga.title, textColor, subtitleColor, maxLines: 0, trailing: GestureDetector(
                    onTap: () => FileUtil.copyMangaName(manga.title),
                    child: Icon(Icons.copy_rounded, size: 18, color: subtitleColor),
                  )),
                  _buildDivider(isDark),
                  _buildInfoRow('类型', typeName, textColor, subtitleColor),
                  _buildDivider(isDark),
                  _buildInfoRow('页数', '${manga.pageCount} 页', textColor, subtitleColor),
                  _buildDivider(isDark),
                  _buildInfoRow('大小', FileUtil.formatFileSize(manga.size), textColor, subtitleColor),
                  _buildDivider(isDark),
                  _buildInfoRow('阅读进度', '第 ${manga.lastReadPage + 1} 页 / 共 ${manga.pageCount} 页', textColor, subtitleColor),
                  _buildDivider(isDark),
                  _buildInfoRow('上次阅读', manga.lastReadTime != null ? _formatTime(manga.lastReadTime!) : '暂无记录', textColor, subtitleColor),
                  _buildDivider(isDark),
                  _buildInfoRow('分组', manga.groupName, textColor, subtitleColor),
                  _buildDivider(isDark),
                  _buildInfoRow('路径', manga.path, textColor, subtitleColor, maxLines: 3),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }

  Widget _buildDivider(bool isDark) {
    return Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12);
  }

  Widget _buildInfoRow(
    String label,
    String value,
    Color textColor,
    Color subtitleColor, {
    int maxLines = 1,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: maxLines != 1 ? .start : .center,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: TextStyle(fontSize: 14, color: subtitleColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: textColor),
              maxLines: maxLines == 0 ? null : maxLines,
              softWrap: maxLines != 1,
              overflow: maxLines == 1 ? .ellipsis : .clip,
            ),
          ),
          if (trailing != null) const SizedBox(width: 8),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
