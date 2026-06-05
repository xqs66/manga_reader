import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/core/extensions/string_ext.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/core/utils/file_util.dart';

import 'package:manga_reader/settings/path_setting.dart';

class PathManagePage extends StatefulWidget {
  const PathManagePage({super.key});

  @override
  State<PathManagePage> createState() => _PathManagePageState();
}

class _PathManagePageState extends State<PathManagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('漫画源路径'), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddPath,
        child: const Icon(Icons.add_rounded),
      ),
      body: Obx(
        () => pathSetting.paths.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    Icon(
                      Icons.folder_off_rounded,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '尚未添加任何漫画源',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _handleAddPath,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('添加路径'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: pathSetting.paths.length,
                itemBuilder: (context, index) {
                  final path = pathSetting.paths[index];
                  final mangas =
                      localMangaService.settingPath2Mangas[path] ?? [];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: .circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12),
                          borderRadius: .circular(8),
                        ),
                        child: const Icon(
                          Icons.folder_rounded,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        path.displayPath(),
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        '${mangas.length} 部漫画',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: IconButton(
                        onPressed: () => pathSetting.removePath(path),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: Colors.red.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: .circular(12),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _handleAddPath() async {
    final dir = await FileUtil.selectDir();
    if (dir != null) {
      pathSetting.addPath(dir.path);
    }
  }
}
