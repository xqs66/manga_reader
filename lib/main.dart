import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:manga_reader/service/base/service_lifecircle_bean.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/service/path_service.dart';
import 'package:manga_reader/service/storage_service.dart';
import 'package:manga_reader/shared/utils/log_util.dart';
import 'package:manga_reader/pages/home_page.dart';
import 'package:manga_reader/routes/routes.dart';
import 'package:manga_reader/settings/path_setting.dart';

List<ServiceLifeCircleBean> serviceBeans = [
  pathSetting,
  pathService,
  storageService,
  localMangaService,
];

void main() async {
  FlutterError.onError = (details) {
    LogUtil.e(
      'Flutter Error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    LogUtil.e('PlatformDispatcher E:', error: error, stackTrace: stackTrace);
    return true;
  };

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          statusBarColor: Colors.transparent,
        ),
      );
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
      );

      serviceBeans = topologicSort(serviceBeans);
      for (final bean in serviceBeans) {
        await bean.initBean();
      }

      runApp(const MyApp());
    },
    (Object error, StackTrace stack) {
      LogUtil.e('捕获到未处理的异常', error: error, stackTrace: stack);
    },
  );
}

List<ServiceLifeCircleBean> topologicSort(List<ServiceLifeCircleBean> beans) {
  final visited = <ServiceLifeCircleBean, bool>{};
  final visiting = <ServiceLifeCircleBean, bool>{};
  final result = <ServiceLifeCircleBean>[];

  void visit(ServiceLifeCircleBean node) {
    if (visited[node] == true) return;
    if (visiting[node] == true) throw Exception('Circular dependency detected');

    visiting[node] = true;
    for (final dependency in node.initDependencies) {
      visit(dependency);
    }
    visited[node] = true;
    visiting[node] = false;
    result.add(node);
  }

  for (final bean in beans) {
    visit(bean);
  }

  return result;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Manga Reader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF5C6BC0)),
      ),
      getPages: Routes.pages,
      home: HomePage(),
      onReady: () {
        for (final bean in serviceBeans) {
          bean.afterBeanReady();
        }
      },
    );
  }
}
