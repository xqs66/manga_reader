import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
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
        child: Wrap(
          children: [
            buildButton(
              label: '显示状态栏',
              onPressed: () => SystemChrome.setEnabledSystemUIMode(.edgeToEdge),
            ),
            buildButton(
              label: '沉浸式',
              onPressed: () =>
                  SystemChrome.setEnabledSystemUIMode(.immersiveSticky),
            ),
            buildButton(
              label: '将漫画合并为合集',
              onPressed: () => Get.toNamed(Routes.mergeMangas),
            ),
            buildButton(
              label: '测试',
              onPressed: () => Get.dialog(
                const Center(child: CircularProgressIndicator()),
                barrierDismissible: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildButton({required String label, VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        height: 100,
        width: 150,
        child: Card(
          shape: RoundedRectangleBorder(),
          child: Text(label).center(),
        ),
      ),
    );
  }

  void _test() async {
    final paths = localMangaService.mangasInLocalSettingPaths.keys;
    LogUtil.d(paths.toString(), tag: 'Mangas');
  }
}
