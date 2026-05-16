import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/settings/read_setting.dart';
import 'package:manga_reader/widgets/styled_menu.dart';

class ReadSettingsPage extends StatelessWidget {
  final bool isBottomSheet;

  const ReadSettingsPage({super.key, this.isBottomSheet = false});

  static const _modeLabels = {
    ReadingMode.strip: '条漫模式',
    ReadingMode.singleVertical: '从上到下',
    ReadingMode.singleLTR: '从左到右',
    ReadingMode.singleRTL: '从右到左',
  };

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
            _buildSectionHeader('阅读模式'),
            _buildReadingModeCard(),
            const SizedBox(height: 24),
            _buildSectionHeader('显示'),
            _buildDisplayCard(),
            const SizedBox(height: 24),
            _buildSectionHeader('图像'),
            _buildImageAdjustmentsCard(),
            const SizedBox(height: 24),
            _buildSectionHeader('阅读'),
            _buildReadingCard(),
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

  Widget _buildReadingModeCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: .circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: const Icon(Icons.view_carousel_rounded),
        title: const Text('阅读模式'),
        trailing: StyledPopupMenu<ReadingMode>(
          items: ReadingMode.values.map((mode) {
            final isCurrent = readSetting.readingMode.value == mode;
            return StyledPopupItem<ReadingMode>(
              value: mode,
              label: _modeLabels[mode]!,
              isSelected: isCurrent,
              onSelected: (m) => readSetting.saveReadingMode(m),
            );
          }).toList(),
          child: Row(
            mainAxisSize: .min,
            children: [
              Text(
                _modeLabels[readSetting.readingMode.value]!,
                style: const TextStyle(fontSize: 14, color: Color(0xFF616161)),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF616161)),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: .circular(12)),
      ),
    );
  }

  Widget _buildDisplayCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: .circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildImageSpacingSetting(),
        ],
      ),
    );
  }

  Widget _buildImageAdjustmentsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: .circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildGrayscleModeSetting(),
          const Divider(height: 1, indent: 56),
          _buildSliderSetting(
            icon: Icons.contrast_rounded,
            label: '对比度',
            value: readSetting.contrast.value,
            min: 0.5,
            max: 1.5,
            onChanged: (v) => readSetting.contrast.value = v,
            onChangeEnd: (v) => readSetting.saveContrast(v),
            displayValue: readSetting.contrast.value.toStringAsFixed(2),
            onReset: () => readSetting.saveContrast(1.0),
          ),
          const Divider(height: 1, indent: 56),
          _buildSliderSetting(
            icon: Icons.colorize_rounded,
            label: '饱和度',
            value: readSetting.saturation.value,
            min: 0,
            max: 2.0,
            onChanged: (v) => readSetting.saturation.value = v,
            onChangeEnd: (v) => readSetting.saveSaturation(v),
            displayValue: readSetting.saturation.value.toStringAsFixed(1),
            onReset: () => readSetting.saveSaturation(1.0),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
    required String displayValue,
    VoidCallback? onReset,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 15)),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                min: min,
                max: max,
                value: value,
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              displayValue,
              textAlign: .center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF616161)),
            ),
          ),
          if (onReset != null)
            IconButton(
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              padding: .zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: '重置为默认值',
              onPressed: onReset,
            ),
        ],
      ),
    );
  }

  Widget _buildReadingCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: .circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildContinueFromLastReadSetting(),
          const Divider(height: 1, indent: 56),
          _buildVolumeKeyNavigation(),
          const Divider(height: 1, indent: 56),
          _buildImmersiveModeSetting(),
        ],
      ),
    );
  }

  Widget _buildContinueFromLastReadSetting() {
    return ListTile(
      leading: const Icon(Icons.history_rounded),
      title: const Text('继续阅读'),
      // subtitle: const Text('选择是否从上次阅读位置开始', style: TextStyle(fontSize: 13)),
      trailing: StyledPopupMenu<bool>(
        items: [
          StyledPopupItem<bool>(
            value: true,
            label: '继续上次阅读位置',
            isSelected: readSetting.continueFromLastRead.value,
            onSelected: (_) => readSetting.saveContinueFromLastRead(true),
          ),
          StyledPopupItem<bool>(
            value: false,
            label: '从头开始',
            isSelected: !readSetting.continueFromLastRead.value,
            onSelected: (_) => readSetting.saveContinueFromLastRead(false),
          ),
        ],
        child: Row(
          mainAxisSize: .min,
          children: [
            Text(
              readSetting.continueFromLastRead.value ? '继续上次阅读位置' : '从头开始',
              style: const TextStyle(fontSize: 14, color: Color(0xFF616161)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF616161)),
          ],
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: .circular(12)),
    );
  }

  Widget _buildVolumeKeyNavigation() {
    return SwitchListTile(
      secondary: const Icon(Icons.volume_up_rounded),
      title: const Text('音量键翻页'),
      subtitle: const Text('使用音量键进行翻页操作', style: TextStyle(fontSize: 13)),
      value: readSetting.enableVolumeKeyNavigation.value,
      onChanged: (v) => readSetting.saveEnableVolumeKeyNavigation(v),
      shape: RoundedRectangleBorder(borderRadius: .zero),
    );
  }

  Widget _buildImmersiveModeSetting() {
    return SwitchListTile(
      secondary: const Icon(Icons.fullscreen_rounded),
      title: const Text('沉浸模式'),
      subtitle: const Text(
        '隐藏系统状态栏和导航栏',
        style: TextStyle(fontSize: 13),
      ),
      value: readSetting.enableImmersiveMode.value,
      onChanged: (value) => readSetting.saveEnableImmersiveMode(value),
      shape: RoundedRectangleBorder(borderRadius: .circular(12)),
    );
  }

  Widget _buildImageSpacingSetting() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.space_bar_rounded, size: 22),
          const SizedBox(width: 16),
          const Text('图片间距', style: TextStyle(fontSize: 15)),
          Expanded(
            child: SliderTheme(
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
                onChanged: (value) => readSetting.imageSpacing.value = value.toInt(),
                onChangeEnd: (value) => readSetting.saveImageSpacing(value.toInt()),
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '${readSetting.imageSpacing.value}',
              textAlign: .center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF616161)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrayscleModeSetting() {
    return SwitchListTile(
      secondary: const Icon(Icons.palette_rounded),
      title: const Text('黑白模式'),
      subtitle: const Text(
        '将彩色图片转换为黑白显示',
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
