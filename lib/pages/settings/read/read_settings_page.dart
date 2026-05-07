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
            _buildSectionHeader('书架'),
            _buildBookshelfCard(),
            const SizedBox(height: 24),
            _buildSectionHeader('显示'),
            _buildDisplayCard(),
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

  static const _layoutLabels = {
    BookshelfLayout.list: '列表',
    BookshelfLayout.grid: '网格',
  };

  Widget _buildBookshelfCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: .circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.grid_view_rounded),
            title: const Text('书架布局'),
            trailing: StyledPopupMenu<BookshelfLayout>(
              items: BookshelfLayout.values.map((layout) {
                final isCurrent = readSetting.bookshelfLayout.value == layout;
                return StyledPopupItem<BookshelfLayout>(
                  value: layout,
                  label: _layoutLabels[layout]!,
                  isSelected: isCurrent,
                  onSelected: (l) => readSetting.saveBookshelfLayout(l),
                );
              }).toList(),
              child: Row(
                mainAxisSize: .min,
                children: [
                  Text(
                    _layoutLabels[readSetting.bookshelfLayout.value]!,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF616161)),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF616161)),
                ],
              ),
            ),
            shape: RoundedRectangleBorder(borderRadius: .circular(12)),
          ),
        ],
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
          const Divider(height: 1, indent: 56),
          _buildGrayscleModeSetting(),
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
