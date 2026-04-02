import 'package:flutter/material.dart';

class UiConfig {
  static const Color primaryColor = Colors.indigo;
  static const double bottomBarHeight = 65;
  static const double popUpMenuHeight = 50;

  ///group header
  static const double groupHeaderHeight = 50;
  static const double groupHeaderPadding = 15;
  static const double groupHeaderRadius = 20;
  static const Color groupHeaderColor = Color(0xB871B0F7);

  ///read page
  static const double topAreaMenuHeight = 50;
  static const double bottomAreaMenuHeight = 80;
  static const double defaultImageContainerRadio = 1.78;
  static final Color readMenuColor = const Color(0xDB000000);
  static const Color readPageForegroundColor = Color(0xFFE0E0E0);
  static const TextStyle readPageTitleStyle = TextStyle(
    color: readPageForegroundColor,
    fontSize: 16,
  );

  ///manga card list tile
  static const double mangaListCardHeight = 150;
  static const TextStyle listTileSubtitleStyle = TextStyle(
    color: Color(0xFF757575),
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle mangaCardTitleStyle = TextStyle(
    fontSize: 15,
    fontWeight: .w400,
    height: 1.4,
  );
}
