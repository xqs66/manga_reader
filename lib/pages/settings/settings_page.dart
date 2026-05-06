import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/settings/theme_setting.dart';
import 'package:manga_reader/widgets/styled_menu.dart';

import '../../routes/routes.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _themeLabels = {
    ThemeMode.system: '跟随系统',
    ThemeMode.light: '浅色模式',
    ThemeMode.dark: '深色模式',
  };

  static const _themeIcons = {
    ThemeMode.system: Icons.settings_brightness_rounded,
    ThemeMode.light: Icons.light_mode_rounded,
    ThemeMode.dark: Icons.dark_mode_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final currentMode = getThemeMode();

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildSectionHeader('显示'),
          const SizedBox(height: 8),
          _buildSettingsCard([
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: .circular(10),
                ),
                child: Icon(_themeIcons[currentMode]!, color: Colors.orange, size: 22),
              ),
              title: const Text('主题', style: TextStyle(fontSize: 15)),
              subtitle: const Text('切换应用配色方案', style: TextStyle(fontSize: 13)),
              trailing: StyledPopupMenu<ThemeMode>(
                items: ThemeMode.values.map((mode) {
                  final isCurrent = currentMode == mode;
                  return StyledPopupItem<ThemeMode>(
                    value: mode,
                    label: _themeLabels[mode]!,
                    icon: _themeIcons[mode],
                    isSelected: isCurrent,
                    onSelected: (m) {
                      setThemeMode(m);
                      Get.changeThemeMode(m);
                      setState(() {});
                    },
                  );
                }).toList(),
                child: Row(
                  mainAxisSize: .min,
                  children: [
                    Text(
                      _themeLabels[currentMode]!,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF616161)),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF616161)),
                  ],
                ),
              ),
              shape: RoundedRectangleBorder(borderRadius: .circular(12)),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('数据'),
          const SizedBox(height: 8),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.folder_rounded,
              title: '漫画源路径',
              subtitle: '管理本地漫画存储目录',
              color: Colors.blue,
              onTap: () => Get.toNamed(Routes.localSetting),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('阅读'),
          const SizedBox(height: 8),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.book_rounded,
              title: '阅读设置',
              subtitle: '阅读模式、沉浸模式、图片间距等',
              color: UiConfig.primaryColor,
              onTap: () => Get.toNamed(Routes.readSetting),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('关于'),
          const SizedBox(height: 8),
          _buildSettingsCard([
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.12),
                  borderRadius: .circular(10),
                ),
                child: const Icon(Icons.info_outline_rounded, color: Colors.teal, size: 22),
              ),
              title: const Text('Manga Reader', style: TextStyle(fontSize: 15)),
              subtitle: const Text('v1.0.0', style: TextStyle(fontSize: 13)),
              shape: RoundedRectangleBorder(borderRadius: .circular(12)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
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

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: .circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: .circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      shape: RoundedRectangleBorder(borderRadius: .circular(12)),
      onTap: onTap,
    );
  }
}
