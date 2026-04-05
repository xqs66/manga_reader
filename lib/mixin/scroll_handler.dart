import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/shared/utils/log_util.dart';

mixin ScrollState {
  final scrollController = ScrollController();

  bool isScrolling = false;

  bool isAtEnd = false;

  DateTime? lastScrollEndTime;

  ///单位： 屏幕高度%
  double currentVelocity = 0.0;

  double? _lastPosition;

  DateTime? _lastTimestamp;
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

  void _calculateScrollVelocity(double currentPosition) {
    final now = DateTime.now();

    if (scrollState._lastPosition != null &&
        scrollState._lastTimestamp != null) {
      final positionDelta =
          (currentPosition - scrollState._lastPosition!) / Get.height * 100;
      final timeDelta =
          now.difference(scrollState._lastTimestamp!).inMicroseconds /
          1000000.0; // 转换为秒

      if (timeDelta > 0) {
        scrollState.currentVelocity = positionDelta / timeDelta;
      }
    }
    scrollState._lastPosition = currentPosition;
    scrollState._lastTimestamp = now;
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
    scrollState._lastPosition = null;
    scrollState._lastTimestamp = null;
    scrollState.currentVelocity = 0.0;
  }

  void handleScrollUpdate(ScrollUpdateNotification notification) {
    final metrics = notification.metrics;
    if (metrics.pixels >= metrics.maxScrollExtent - 10) {
      scrollState.isAtEnd = true;
    } else {
      scrollState.isAtEnd = false;
    }
    _calculateScrollVelocity(metrics.pixels);
  }

  void handleScrollFinish(ScrollEndNotification notification) {
    scrollState.isScrolling = false;
    scrollState._lastPosition = null;
    scrollState._lastTimestamp = null;
    scrollState.currentVelocity = 0.0;
  }

  void handleScroll2Head() {}

  void handleScroll2End() {}
}
