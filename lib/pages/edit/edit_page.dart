import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/routes/routes.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/shared/extensions/widget_ext.dart';
import 'package:manga_reader/shared/utils/log_util.dart';

class EditPage extends StatefulWidget {
  const EditPage({super.key});

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisSize: .min,
          children: [
            ElevatedButton(
              onPressed: () => Get.toNamed(Routes.mergeMangas),
              // onPressed: () => _test(),
              child: Text('将漫画合并为合集'),
            ),
          ],
        ),
      ),
    );
  }

  void _test() async {
    final paths = localMangaService.mangasInLocalSettingPaths.keys;
    LogUtil.d(
      paths.toString(),
      tag: 'Mangas',
    );
  }
}
