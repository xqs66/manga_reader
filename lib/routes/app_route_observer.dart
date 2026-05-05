import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/router_report.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class AppRouteObserver extends RouteObserver<PageRoute> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    RouterReportManager.reportCurrentRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) async {
    RouterReportManager.reportRouteWillDispose(route);
  }
}
