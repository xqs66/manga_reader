import 'dart:ui';

import 'package:flutter/material.dart';

class ThemeConfig {
  static ThemeData light = _buildTheme(.light);

  static ThemeData dark = _buildTheme(.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5C6BC0),
        brightness: brightness,
      ),
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBarTheme: AppBarTheme(
        surfaceTintColor: Colors.transparent,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark
            ? const Color(0xFFE0E0E0)
            : const Color(0xFF1A1A1A),
        scrolledUnderElevation: 2,
        shadowColor: isDark ? Colors.black38 : Colors.black12,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
        ),
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        elevation: 4,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 4,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        indicatorColor: const Color(
          0xFF5C6BC0,
        ).withValues(alpha: isDark ? 0.2 : 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE0E0E0) : null,
            );
          }
          return TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFFBDBDBD) : null,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 1 : 2,
        shadowColor: isDark ? Colors.black38 : Colors.black26,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: .circular(12)),
        color: isDark ? const Color(0xFF2C2C2C) : null,
      ),
    );
  }
}
