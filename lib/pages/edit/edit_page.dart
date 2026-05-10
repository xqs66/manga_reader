import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/routes/routes.dart';
import 'package:manga_reader/widgets/list_page.dart';

class EditPage extends ListPage {
  const EditPage({super.key});

  @override
  String get title => '编辑';

  @override
  List<Widget> buildItems(BuildContext context) {
    return [
      section('漫画操作', card([
        tile(
          icon: Icons.merge_rounded, title: '合并漫画为合集',
          subtitle: '将多部漫画按顺序合并为一个合集',
          color: UiConfig.primaryColor,
          onTap: () => Get.toNamed(Routes.editMerge),
        ),
        tile(
          icon: Icons.archive_rounded, title: '归档漫画',
          subtitle: '将漫画打包为 ZIP 压缩包',
          color: Colors.teal,
          onTap: () => Get.toNamed(Routes.editArchive),
        ),
      ])),
    ];
  }
}
