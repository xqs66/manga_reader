import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/ui/pages/lan/server_paths/server_paths_page_controller.dart';
import 'package:manga_reader/ui/pages/lan/server_paths/server_paths_page_state.dart';

class ServerPathsPage extends StatelessWidget {
  const ServerPathsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ServerPathsPageController(server: Get.arguments as dynamic),
    );
    final state = controller.state;

    return GetBuilder<ServerPathsPageController>(
      id: ServerPathsPageController.bodyId,
      builder: (_) {
        return Scaffold(
          appBar: AppBar(
            title: Text(state.server.displayName),
            centerTitle: false,
          ),
          body: _buildBody(controller, state),
        );
      },
    );
  }

  Widget _buildBody(ServerPathsPageController controller, ServerPathsPageState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              '连接失败',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              state.error!,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                state.isLoading = true;
                state.error = null;
                controller.update([ServerPathsPageController.bodyId]);
                controller.onReady();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (state.paths.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              '该服务器没有配置漫画路径',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Server info bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                '${state.server.host}:${state.server.port}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        // Path list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: state.paths.length,
            itemBuilder: (context, index) {
              return _buildPathCard(controller, state.paths[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPathCard(
    ServerPathsPageController controller,
    Map<String, dynamic> pathInfo,
  ) {
    final path = pathInfo['path'] as String;
    final label = pathInfo['label'] as String? ?? path;
    final count = pathInfo['count'] as int? ?? 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: UiConfig.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.folder_rounded,
            color: UiConfig.primaryColor,
            size: 22,
          ),
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          '$count 部漫画',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () => Get.back(result: path),
      ),
    );
  }
}
