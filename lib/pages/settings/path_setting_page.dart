import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/shared/utils/file_util.dart';

import '../../settings/path_setting.dart';

class PathSettingPage extends StatefulWidget {
  const PathSettingPage({super.key});

  @override
  State<PathSettingPage> createState() => _PathSettingPageState();
}

class _PathSettingPageState extends State<PathSettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Path Setting'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async =>
                pathSetting.addPath((await FileUtil.selectDir())?.path ?? ''),
          ),
        ],
      ),
      body: Obx(
        () => ListView(
          children: pathSetting.paths
              .map(
                (path) => ListTile(
                  title: Text(path),
                  trailing: IconButton(
                    onPressed: () => pathSetting.removePath(path),
                    icon: Icon(Icons.remove),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
