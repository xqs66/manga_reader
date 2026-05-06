import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/service/storage_service.dart';

const _key = 'app_theme_mode';

final themeSetting = ThemeSetting();

class ThemeSetting {
  late final Rx<ThemeMode> currentMode;

  ThemeSetting() {
    final index = storageService.read<int>(_key) ?? 0;
    currentMode = ThemeMode.values[index.clamp(0, 2)].obs;
  }

  void setMode(ThemeMode mode) {
    currentMode.value = mode;
    storageService.write(_key, mode.index);
    Get.changeThemeMode(mode);
  }

  ThemeMode get mode => currentMode.value;
}
