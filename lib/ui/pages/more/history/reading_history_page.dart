import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/ui/widgets/empty_state.dart';

import 'reading_history_page_controller.dart';

class ReadingHistoryPage extends StatelessWidget {
  const ReadingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReadingHistoryPageController());
    final state = controller.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('阅读历史'),
        centerTitle: false,
      ),
      body: GetBuilder<ReadingHistoryPageController>(
        id: ReadingHistoryPageController.bodyId,
        builder: (_) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.historyItems.isEmpty) {
            return const EmptyState(
              icon: Icons.history_rounded,
              title: '暂无阅读记录',
              subtitle: '开始阅读你的第一本漫画吧',
            );
          }
          return ListView.builder(
            itemCount: state.historyItems.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final manga = state.historyItems[index];
              return ListTile(
                onTap: () => controller.openManga(manga),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 52,
                    height: 72,
                    child: _buildCover(manga.cover.path),
                  ),
                ),
                title: Text(
                  manga.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _buildSubtitle(manga),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCover(String? coverPath) {
    if (coverPath != null && File(coverPath).existsSync()) {
      return Image.file(File(coverPath), fit: BoxFit.cover);
    }
    return Container(
      color: Colors.grey.shade200,
      child: Icon(Icons.book_rounded, color: Colors.grey.shade400, size: 28),
    );
  }

  String _buildSubtitle(Manga manga) {
    final timeStr = manga.lastReadTime != null
        ? '${manga.lastReadTime!.year}-${manga.lastReadTime!.month.toString().padLeft(2, '0')}-${manga.lastReadTime!.day.toString().padLeft(2, '0')} ${manga.lastReadTime!.hour.toString().padLeft(2, '0')}:${manga.lastReadTime!.minute.toString().padLeft(2, '0')}'
        : '';
    return '上次阅读: $timeStr  ·  进度: ${manga.lastReadPage}/${manga.pageCount} 页';
  }
}
