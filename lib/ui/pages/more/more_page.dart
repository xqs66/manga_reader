import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/routes/routes.dart';
import 'package:manga_reader/ui/widgets/list_page.dart';

class MorePage extends ListPage {
  const MorePage({super.key});

  @override
  String get title => '更多';

  @override
  List<Widget> buildItems(BuildContext context) {
    return [
      section(
        '管理',
        card([
          tile(
            icon: Icons.folder_open_rounded,
            title: '源路径管理',
            subtitle: '管理本地漫画存储目录',
            color: Colors.blue,
            onTap: () => Get.toNamed(Routes.morePaths),
          ),
          tile(
            icon: Icons.folder_rounded,
            title: '分组管理',
            subtitle: '管理书架分组',
            color: Colors.orange,
            onTap: () => Get.toNamed(Routes.moreGroupManage),
          ),
        ]),
      ),
      const SizedBox(height: 24),
      section(
        '局域网',
        card([
          tile(
            icon: Icons.wifi_rounded,
            title: '局域网服务',
            subtitle: '启动服务器共享漫画给其他设备',
            color: Colors.green,
            onTap: () => Get.toNamed(Routes.lanServer),
          ),
        ]),
      ),
      const SizedBox(height: 24),
      section(
        '设置',
        card([
          tile(
            icon: Icons.settings_rounded,
            title: '设置',
            subtitle: '应用设置',
            color: Colors.indigo,
            onTap: () => Get.toNamed(Routes.moreSettings),
          ),
        ]),
      ),
      const SizedBox(height: 24),
      section(
        '关于',
        card([
          tile(
            icon: Icons.info_outline_rounded,
            title: '关于',
            subtitle: 'v1.0.0',
            color: Colors.teal,
            trailing: const SizedBox.shrink(),
          ),
        ]),
      ),
    ];
  }
}
