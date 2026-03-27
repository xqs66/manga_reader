import 'dart:async';

import 'package:flutter/material.dart';

mixin ScrollState {
  final scrollController = ScrollController();

  bool isScrolling = false;

  bool isScrollingByProgramming = false;

  bool isAtEnd = false;
}

mixin ScrollHandler {
  ScrollState get scrollState;

  Timer? debounceTimer;

  bool handleScrollEvent(ScrollNotification notification) {
    if (scrollState.isScrollingByProgramming) return false;

    if (notification is ScrollStartNotification) {
      debounceTimer?.cancel();
      handleScrollStart();
      scrollState.isScrolling = true;
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
      debounceTimer = Timer(const Duration(milliseconds: 150), () {
        scrollState.isScrolling = false;

        final metrics = notification.metrics;
        if (metrics.pixels >= metrics.maxScrollExtent - 10) {
          handleScroll2End();
          return;
        }
        if (metrics.pixels <= 10) {
          handleScroll2Head();
          return;
        }

        handleScrollFinish();
      });
    }
    return false;
  }

  void handleScrollStart() {}

  void handleScrollFinish() {}

  void handleScroll2Head() {}

  void handleScroll2End() {}
}
