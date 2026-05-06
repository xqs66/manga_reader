import 'package:flutter/material.dart';
import 'package:manga_reader/service/storage_service.dart';

const _key = 'app_theme_mode';

ThemeMode getThemeMode() {
  final index = storageService.read<int>(_key) ?? 0;
  return ThemeMode.values[index.clamp(0, 2)];
}

void setThemeMode(ThemeMode mode) {
  storageService.write(_key, mode.index);
}
