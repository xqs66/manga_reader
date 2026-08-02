import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:manga_reader/routes/routes.dart';
import 'package:manga_reader/service/log_service.dart';
import 'package:share_plus/share_plus.dart';
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
          tile(
            icon: Icons.cleaning_services_rounded,
            title: '缓存管理',
            subtitle: '管理应用缓存文件',
            color: Colors.cyan,
            onTap: () => Get.toNamed(Routes.moreCache),
          ),
        ]),
      ),
      const SizedBox(height: 24),
      section(
        '数据',
        card([
          tile(
            icon: Icons.history_rounded,
            title: '阅读历史',
            subtitle: '查看最近阅读的漫画',
            color: Colors.purple,
            onTap: () => Get.toNamed(Routes.moreHistory),
          ),
          tile(
            icon: Icons.bar_chart_rounded,
            title: '阅读统计',
            subtitle: '查看阅读数据统计',
            color: Colors.deepOrange,
            onTap: () => Get.toNamed(Routes.moreStats),
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
      const SizedBox(height: 24),
      section(
        '日志',
        card([
          tile(
            icon: Icons.share_rounded,
            title: '导出日志',
            subtitle: '分享应用日志文件',
            color: Colors.brown,
            onTap: () async {
              final dirPath = logService.logDirectoryPath;
              if (dirPath == null) {
                Fluttertoast.showToast(msg: '日志目录不可用');
                return;
              }
              final dir = Directory(dirPath);
              if (!dir.existsSync()) {
                Fluttertoast.showToast(msg: '没有日志文件可导出');
                return;
              }
              final files = dir
                  .listSync()
                  .whereType<File>()
                  .where((f) => f.path.endsWith('.log'))
                  .toList();
              if (files.isEmpty) {
                Fluttertoast.showToast(msg: '没有日志文件可导出');
                return;
              }
              try {
                final xFiles = files.map((f) => XFile(f.path)).toList();
                await SharePlus.instance.share(ShareParams(files: xFiles));
              } catch (_) {
                Fluttertoast.showToast(msg: '导出失败');
              }
            },
          ),
        ]),
      ),
    ];
  }
}
