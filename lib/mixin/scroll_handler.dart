import 'dart:async';

import 'package:flutter/material.dart';

mixin ScrollState {
  final scrollController = ScrollController();

  bool isScrolling = false;

  bool isAtEnd = false;

  DateTime? lastScrollEndTime;
}

mixin ScrollHandler {
  ScrollState get scrollState;

  Timer? debounceTimer;

  bool handleScrollEvent(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      handleScrollStart(notification);
    }

    if (notification is ScrollUpdateNotification) {
      handleScrollUpdate(notification);
    }

    if (notification is ScrollEndNotification) {
      handleScrollFinish(notification);

      final metrics = notification.metrics;
      if (metrics.pixels >= metrics.maxScrollExtent - 10) {
        handleScroll2End();
      }
      if (metrics.pixels <= 10) {
        handleScroll2Head();
      }
    }
    return false;
  }

  void delayedHandleScrollStart(ScrollStartNotification notification) {
    final duration = DateTime.now().difference(
      scrollState.lastScrollEndTime ?? DateTime.now(),
    );
    if (duration.inMilliseconds < 100) {
      debounceTimer?.cancel();
      debounceTimer = Timer(Duration(milliseconds: 100), () {
        scrollState.isScrolling = true;
      });
      return;
    }
    scrollState.isScrolling = true;
  }

  void handleEndWithDelayedStart(ScrollEndNotification notification) {
    debounceTimer?.cancel();
    scrollState.lastScrollEndTime = DateTime.now();
    scrollState.isScrolling = false;
  }

  void handleScrollStart(ScrollStartNotification notification) {
    scrollState.isScrolling = true;
  }

  void handleScrollUpdate(ScrollUpdateNotification notification) {
    final metrics = notification.metrics;
    if (metrics.pixels >= metrics.maxScrollExtent - 10) {
      scrollState.isAtEnd = true;
    } else {
      scrollState.isAtEnd = false;
    }
  }

  void handleScrollFinish(ScrollEndNotification notification) {
    scrollState.isScrolling = false;
  }

  void handleScroll2Head() {}

  void handleScroll2End() {}
}
