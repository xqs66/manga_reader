import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/core/repository/manga_repository.dart';

import 'reading_stats_page_controller.dart';

class ReadingStatsPage extends StatelessWidget {
  const ReadingStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReadingStatsPageController());
    final state = controller.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('阅读统计'),
        centerTitle: false,
      ),
      body: GetBuilder<ReadingStatsPageController>(
        id: ReadingStatsPageController.bodyId,
        builder: (_) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = state.stats;
          if (stats == null) {
            return const Center(child: Text('加载失败'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Top row: today + week
              Row(
                children: [
                  Expanded(child: _buildStatCard(
                    icon: Icons.today_rounded,
                    label: '今日阅读',
                    value: '${stats.todayCount}',
                    unit: '部',
                    color: Colors.blue,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(
                    icon: Icons.calendar_view_week_rounded,
                    label: '本周阅读',
                    value: '${stats.weekCount}',
                    unit: '部',
                    color: Colors.green,
                  )),
                ],
              ),
              const SizedBox(height: 12),
              // Read / total progress
              _buildProgressCard(stats),
              const SizedBox(height: 12),
              // Most recent read time
              if (stats.mostRecentReadTime != null)
                _buildRecentCard(stats.mostRecentReadTime!),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(unit,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(ReadingStats stats) {
    final ratio = stats.totalMangaCount > 0
        ? stats.totalReadCount / stats.totalMangaCount
        : 0.0;
    final percent = (ratio * 100).toStringAsFixed(1);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('阅读覆盖率',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('${stats.totalReadCount}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(' / ${stats.totalMangaCount}',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                const Spacer(),
                Text('$percent%',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCard(DateTime time) {
    final diff = DateTime.now().difference(time);
    String ago;
    if (diff.inMinutes < 60) {
      ago = '${diff.inMinutes} 分钟前';
    } else if (diff.inHours < 24) {
      ago = '${diff.inHours} 小时前';
    } else {
      ago = '${diff.inDays} 天前';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded, color: Colors.orange, size: 22),
            const SizedBox(width: 10),
            const Text('最近阅读: ', style: TextStyle(fontSize: 14, color: Colors.grey)),
            Text(ago,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
