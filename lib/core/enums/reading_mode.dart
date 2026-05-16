enum ReadingMode {
  strip,
  singleVertical,
  singleLTR,
  singleRTL,
  singleVerticalDouble,
  singleLTRDouble,
  singleRTLDouble,
}

extension ReadingModeExt on ReadingMode {
  bool get isDoublePage =>
      this == ReadingMode.singleVerticalDouble ||
      this == ReadingMode.singleLTRDouble ||
      this == ReadingMode.singleRTLDouble;

  bool get isRTL => this == ReadingMode.singleRTL || this == ReadingMode.singleRTLDouble;

  bool get isHorizontal =>
      this == ReadingMode.singleLTR ||
      this == ReadingMode.singleRTL ||
      this == ReadingMode.singleLTRDouble ||
      this == ReadingMode.singleRTLDouble;
}
