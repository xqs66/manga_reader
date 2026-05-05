import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/settings/read_setting.dart';
import 'package:manga_reader/shared/constants/constants.dart';
import 'package:manga_reader/shared/extensions/text_ext.dart';
import 'package:path/path.dart';

class ReadSettingsPage extends StatelessWidget {
  final bool isBottomSheet;

  const ReadSettingsPage({super.key, this.isBottomSheet = false});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: AppBar(
          title: Text('阅读设置'),
          centerTitle: true,
          automaticallyImplyLeading: !isBottomSheet,
          leading: isBottomSheet
              ? null
              : IconButton(onPressed: Get.back, icon: Icon(Icons.arrow_back)),
        ),
        body: Center(child: ListView(children: buildSettingItems())),
      ),
    );
  }

  List<Widget> buildSettingItems() {
    return [
      buildImmersiveModeSetting(),
      buildImageSpacingSetting(),
      buildGrayscleModeSetting()
    ];
  }

  Widget buildImmersiveModeSetting() {
    return SwitchListTile(
      title: Text('开启沉浸模式'),
      subtitle: Text('开启后，将隐藏系统状态栏和导航栏').size(13),
      value: readSetting.enableImmersiveMode.value,
      onChanged: (value) => readSetting.saveEnableImmersiveMode(value),
    );
  }

  Widget buildImageSpacingSetting() {
    return ListTile(
      title: Text('图片间距'),
      trailing: SizedBox(
        width: 200,
        child: Row(
          children: [
            Expanded(
              child: Slider(
                min: 0,
                max: 50,
                showValueIndicator: .alwaysVisible,
                value: readSetting.imageSpacing.value.toDouble(),
                onChanged: (value) =>
                    readSetting.imageSpacing.value = value.toInt(),
                onChangeEnd: (value) =>
                    readSetting.saveImageSpacing(value.toInt()),
              ),
            ),
            Text(readSetting.imageSpacing.value.toString()).size(16),
          ],
        ),
      ),
    );
  }

  Widget buildGrayscleModeSetting() {
    return SwitchListTile(
      title: Text('开启黑白漫画模式'),
      value: readSetting.enableGrayscaleMode.value,
      onChanged: (value) => readSetting.saveEnableGrayscaleMode(value),
    );
  }
}
