import 'dart:async';

import 'package:flutter/material.dart';

mixin ScrollState {
  final scrollController = ScrollController();

  bool isScrolling = false;

  bool isAtEnd = false;
}

mixin ScrollHandler {
  ScrollState get scrollState;

  Timer? debounceTimer;

  bool handleScrollEvent(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      debounceTimer?.cancel();
      handleScrollStart();
      Future.delayed(const Duration(milliseconds: 200)).then((_) {
        scrollState.isScrolling = true;
      });
    }

    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      if (metrics.pixels >= metrics.maxScrollExtent - 10) {
        scrollState.isAtEnd = true;
      } else {
        scrollState.isAtEnd = false;
      }
    }

    if (notification is ScrollEndNotification) {
      scrollState.isScrolling = false;

      final metrics = notification.metrics;
      if (metrics.pixels >= metrics.maxScrollExtent - 10) {
        handleScroll2End();
      }
      if (metrics.pixels <= 10) {
        handleScroll2Head();
      }
      handleScrollFinish();
    }
    return false;
  }

  void handleScrollStart() {}

  void handleScrollFinish() {}

  void handleScroll2Head() {}

  void handleScroll2End() {}
}
