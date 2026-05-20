import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

const _kScrollEdgeThreshold = 10.0;
const _kDebounceMs = 100;

mixin ScrollState {
  bool isScrolling = false;
  bool isAtEnd = false;
  DateTime? lastScrollEndTime;
  double currentVelocity = 0.0;
  double? _lastPosition;
  DateTime? _lastTimestamp;
}

mixin ScrollHandler {
  ScrollState get scrollState;

  Timer? _debounceTimer;

  bool handleScrollNotification(ScrollNotification notification) {
    switch (notification) {
      case ScrollStartNotification():
        handleScrollStart(notification);
      case ScrollUpdateNotification():
        handleScrollUpdate(notification);
      case ScrollEndNotification():
        handleScrollFinish(notification);
        final metrics = notification.metrics;
        if (metrics.pixels >= metrics.maxScrollExtent - _kScrollEdgeThreshold) {
          handleScroll2End();
        }
        if (metrics.pixels <= _kScrollEdgeThreshold) {
          handleScroll2Head();
        }
    }
    return false;
  }

  void _calculateVelocity(double currentPosition) {
    final now = DateTime.now();
    if (scrollState._lastPosition != null && scrollState._lastTimestamp != null) {
      final positionDelta = (currentPosition - scrollState._lastPosition!) / Get.height * 100;
      final timeDelta = now.difference(scrollState._lastTimestamp!).inMicroseconds / 1000000.0;
      if (timeDelta > 0) {
        scrollState.currentVelocity = positionDelta / timeDelta;
      }
    }
    scrollState._lastPosition = currentPosition;
    scrollState._lastTimestamp = now;
  }

  void handleScrollStart(ScrollStartNotification notification) {
    scrollState.isScrolling = true;
    scrollState._lastPosition = null;
    scrollState._lastTimestamp = null;
    scrollState.currentVelocity = 0.0;
  }

  void handleScrollUpdate(ScrollUpdateNotification notification) {
    final metrics = notification.metrics;
    scrollState.isAtEnd = metrics.pixels >= metrics.maxScrollExtent - _kScrollEdgeThreshold;
    _calculateVelocity(metrics.pixels);
  }

  void handleScrollFinish(ScrollEndNotification notification) {
    scrollState.isScrolling = false;
    scrollState._lastPosition = null;
    scrollState._lastTimestamp = null;
    scrollState.currentVelocity = 0.0;
  }

  void delayedHandleScrollStart(ScrollStartNotification notification) {
    final now = DateTime.now();
    final lastEnd = scrollState.lastScrollEndTime ?? now;
    if (now.difference(lastEnd).inMilliseconds < _kDebounceMs) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: _kDebounceMs), () {
        scrollState.isScrolling = true;
      });
      return;
    }
    scrollState.isScrolling = true;
  }

  void handleEndWithDelayedStart(ScrollEndNotification notification) {
    _debounceTimer?.cancel();
    scrollState.lastScrollEndTime = DateTime.now();
    scrollState.isScrolling = false;
  }

  void handleScroll2Head() {}

  void handleScroll2End() {}
}

class ScrollWrapper extends StatefulWidget {
  final Widget Function(BuildContext context, ScrollWrapperState state) builder;
  final VoidCallback? onScrollToEnd;
  final VoidCallback? onScrollToHead;
  final VoidCallback? onStateChanged;
  final bool useDelayedStart;
  final int scrollEndDelay;
  final ScrollController? _scrollController;

  const ScrollWrapper({
    super.key,
    required this.builder,
    this.onScrollToEnd,
    this.onScrollToHead,
    this.onStateChanged,
    this.useDelayedStart = false,
    this.scrollEndDelay = 0,
  }) : _scrollController = null;

  const ScrollWrapper.scrollbar({
    super.key,
    required this.builder,
    required ScrollController scrollController,
    this.onScrollToEnd,
    this.onScrollToHead,
    this.onStateChanged,
    this.useDelayedStart = false,
    this.scrollEndDelay = 0,
  }) : _scrollController = scrollController;

  @override
  ScrollWrapperState createState() => ScrollWrapperState();
}

class ScrollWrapperState extends State<ScrollWrapper> with ScrollHandler, ScrollState {
  Timer? _endDelayTimer;

  @override
  ScrollState get scrollState => this;

  @override
  void dispose() {
    _endDelayTimer?.cancel();
    super.dispose();
  }

  @override
  void handleScrollStart(ScrollStartNotification notification) {
    _endDelayTimer?.cancel();
    if (widget.useDelayedStart) {
      delayedHandleScrollStart(notification);
    } else {
      super.handleScrollStart(notification);
    }
  }

  @override
  void handleScrollFinish(ScrollEndNotification notification) {
    _endDelayTimer?.cancel();
    if (widget.useDelayedStart) {
      handleEndWithDelayedStart(notification);
    } else if (widget.scrollEndDelay > 0) {
      // keep isScrolling true during the delay window
    } else {
      super.handleScrollFinish(notification);
    }
    _endDelayTimer = Timer(Duration(milliseconds: widget.scrollEndDelay), () {
      if (!widget.useDelayedStart) super.handleScrollFinish(notification);
    });
    widget.onStateChanged?.call();
  }

  @override
  void handleScroll2Head() => widget.onScrollToHead?.call();

  @override
  void handleScroll2End() => widget.onScrollToEnd?.call();

  @override
  Widget build(BuildContext context) {
    final child = NotificationListener<ScrollNotification>(
      onNotification: handleScrollNotification,
      child: Builder(builder: (context) => widget.builder(context, this)),
    );
    if (widget._scrollController == null) return child;
    return CupertinoScrollbar(controller: widget._scrollController!, child: child);
  }
}
