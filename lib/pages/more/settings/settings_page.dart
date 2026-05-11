import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/routes/routes.dart';
import 'package:manga_reader/settings/read_setting.dart';
import 'package:manga_reader/settings/theme_setting.dart';
import 'package:manga_reader/widgets/list_page.dart';
import 'package:manga_reader/widgets/styled_menu.dart';

class SettingsPage extends ListPage {
  const SettingsPage({super.key});

  @override
  String get title => '设置';

  static const _themeLabels = {
    ThemeMode.system: '跟随系统', ThemeMode.light: '浅色模式', ThemeMode.dark: '深色模式',
  };
  static const _themeIcons = {
    ThemeMode.system: Icons.settings_brightness_rounded,
    ThemeMode.light: Icons.light_mode_rounded,
    ThemeMode.dark: Icons.dark_mode_rounded,
  };

  @override
  List<Widget> buildItems(BuildContext context) {
    return [
      section('显示', card([
        Obx(() => _themeTile()),
        Obx(() => _layoutTile()),
      ])),
      const SizedBox(height: 24),
      section('阅读', card([
        tile(
          icon: Icons.book_rounded, title: '阅读设置',
          subtitle: '阅读器相关设置',
          color: UiConfig.primaryColor,
          onTap: () => Get.toNamed(Routes.moreReadSetting),
        ),
      ])),
    ];
  }

  Widget _themeTile() {
    final currentMode = themeSetting.currentMode.value;
    return tile(
      icon: _themeIcons[currentMode]!, title: '主题',
      subtitle: '切换应用配色方案', color: Colors.orange,
      trailing: StyledPopupMenu<ThemeMode>(
        items: ThemeMode.values.map((mode) {
          final isCurrent = currentMode == mode;
          return StyledPopupItem<ThemeMode>(
            value: mode, label: _themeLabels[mode]!,
            icon: _themeIcons[mode], isSelected: isCurrent,
            onSelected: (m) => themeSetting.setMode(m),
          );
        }).toList(),
        child: Row(
          mainAxisSize: .min,
          children: [
            Text(_themeLabels[currentMode]!, style: const TextStyle(fontSize: 14, color: Color(0xFF616161))),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF616161)),
          ],
        ),
      ),
    );
  }

  Widget _layoutTile() {
    return tile(
      icon: Icons.grid_view_rounded, title: '书架布局',
      subtitle: '切换漫画列表和网格展示', color: Colors.indigo,
      trailing: StyledPopupMenu<BookshelfLayout>(
        items: BookshelfLayout.values.map((layout) {
          final isCurrent = readSetting.bookshelfLayout.value == layout;
          return StyledPopupItem<BookshelfLayout>(
            value: layout,
            label: layout == BookshelfLayout.list ? '列表' : '网格',
            isSelected: isCurrent,
            onSelected: (l) => readSetting.saveBookshelfLayout(l),
          );
        }).toList(),
        child: Row(
          mainAxisSize: .min,
          children: [
            Text(
              readSetting.bookshelfLayout.value == BookshelfLayout.list ? '列表' : '网格',
              style: const TextStyle(fontSize: 14, color: Color(0xFF616161)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF616161)),
          ],
        ),
      ),
    );
  }
}
