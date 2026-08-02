import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'cache_manage_page_controller.dart';

class CacheManagePage extends StatelessWidget {
  const CacheManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CacheManagePageController());
    final state = controller.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('缓存管理'),
        centerTitle: false,
      ),
      body: GetBuilder<CacheManagePageController>(
        id: CacheManagePageController.bodyId,
        builder: (_) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCacheCard(
                icon: Icons.image_rounded,
                title: '图片缓存',
                subtitle: 'ZIP/EPUB 漫画解压缓存',
                sizeBytes: state.imageCacheSizeBytes,
                color: Colors.blue,
                onClear: controller.clearImageCache,
              ),
              const SizedBox(height: 12),
              _buildCacheCard(
                icon: Icons.article_rounded,
                title: '日志文件',
                subtitle: '应用运行日志',
                sizeBytes: state.logCacheSizeBytes,
                color: Colors.orange,
                onClear: controller.clearLogCache,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: state.imageCacheSizeBytes == 0 && state.logCacheSizeBytes == 0
                      ? null
                      : () => _showClearAllDialog(context, controller),
                  icon: const Icon(Icons.delete_sweep_rounded),
                  label: const Text('清除全部缓存'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCacheCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required int sizeBytes,
    required Color color,
    required VoidCallback onClear,
  }) {
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatSize(sizeBytes),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 30,
                  child: OutlinedButton(
                    onPressed: sizeBytes == 0 ? null : onClear,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('清除', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, CacheManagePageController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('将清除所有图片缓存和日志文件，确定继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              controller.clearImageCache();
              controller.clearLogCache();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  static String _formatSize(int bytes) {
    if (bytes == 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
