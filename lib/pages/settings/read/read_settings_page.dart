import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/settings/read_setting.dart';

class ReadSettingsPage extends StatelessWidget {
  final bool isBottomSheet;

  const ReadSettingsPage({super.key, this.isBottomSheet = false});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: AppBar(
          title: const Text('阅读设置'),
          centerTitle: true,
          automaticallyImplyLeading: !isBottomSheet,
          leading: isBottomSheet
              ? null
              : IconButton(
                  onPressed: Get.back,
                  icon: const Icon(Icons.arrow_back),
                ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            _buildSectionHeader('显示'),
            _buildDisplaySettings(),
            const SizedBox(height: 24),
            _buildSectionHeader('阅读'),
            _buildReadingSettings(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF757575),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDisplaySettings() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildImageSpacingSetting(),
          const Divider(height: 1, indent: 56),
          _buildGrayscleModeSetting(),
        ],
      ),
    );
  }

  Widget _buildReadingSettings() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: _buildImmersiveModeSetting(),
    );
  }

  Widget _buildImmersiveModeSetting() {
    return SwitchListTile(
      secondary: const Icon(Icons.fullscreen_rounded),
      title: const Text('沉浸模式'),
      subtitle: const Text(
        '隐藏系统状态栏和导航栏，提供全屏阅读体验',
        style: TextStyle(fontSize: 13),
      ),
      value: readSetting.enableImmersiveMode.value,
      onChanged: (value) => readSetting.saveEnableImmersiveMode(value),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildImageSpacingSetting() {
    return ListTile(
      leading: const Icon(Icons.space_bar_rounded),
      title: const Text('图片间距'),
      subtitle: SliderTheme(
        data: SliderThemeData(
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        ),
        child: Slider(
          min: 0,
          max: 50,
          divisions: 50,
          value: readSetting.imageSpacing.value.toDouble(),
          onChanged: (value) =>
              readSetting.imageSpacing.value = value.toInt(),
          onChangeEnd: (value) =>
              readSetting.saveImageSpacing(value.toInt()),
        ),
      ),
      trailing: SizedBox(
        width: 36,
        child: Text(
          '${readSetting.imageSpacing.value}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF616161),
          ),
        ),
      ),
    );
  }

  Widget _buildGrayscleModeSetting() {
    return SwitchListTile(
      secondary: const Icon(Icons.palette_rounded),
      title: const Text('黑白模式'),
      subtitle: const Text(
        '将彩色图片转换为黑白显示，模拟纸质漫画效果',
        style: TextStyle(fontSize: 13),
      ),
      value: readSetting.enableGrayscaleMode.value,
      onChanged: (value) => readSetting.saveEnableGrayscaleMode(value),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
    );
  }
}
