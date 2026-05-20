import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:manga_reader/config/theme_config.dart';
import 'package:manga_reader/core/error/error_handler.dart';
import 'package:manga_reader/routes/app_route_observer.dart';
import 'package:manga_reader/service/base/service_lifecircle_bean.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/service/path_service.dart';
import 'package:manga_reader/service/storage_service.dart';
import 'package:manga_reader/settings/read_setting.dart';
import 'package:manga_reader/core/utils/log_util.dart';
import 'package:manga_reader/core/repository/manga_repository_impl.dart';
import 'package:manga_reader/pages/home_page.dart';
import 'package:manga_reader/routes/routes.dart';
import 'package:manga_reader/settings/path_setting.dart';
import 'package:manga_reader/settings/theme_setting.dart';

List<ServiceLifeCircleBean> serviceBeans = [
  pathSetting,
  pathService,
  storageService,
  localMangaService,
  readSetting,
  mangaRepo,
];

void main() {
  setupGlobalErrorHandlers();

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
      SystemChrome.setEnabledSystemUIMode(.edgeToEdge);

      serviceBeans = topologicSort(serviceBeans);
      for (final bean in serviceBeans) {
        await bean.initBean();
      }

      runApp(const MyApp());
    },
    (Object error, StackTrace stack) {
      LogUtil.e('Unhandled zone error', error: error, stackTrace: stack);
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
      theme: ThemeConfig.light,
      darkTheme: ThemeConfig.dark,
      themeMode: themeSetting.mode,
      getPages: Routes.pages,
      defaultTransition: .cupertino,
      navigatorObservers: [routeObserver],
      home: HomePage(),
      builder: (context, child) {
        ErrorWidget.builder = (details) => _buildErrorWidget(details);
        return child!;
      },
      onReady: () {
        for (final bean in serviceBeans) {
          bean.afterBeanReady();
        }
      },
    );
  }

  static Widget _buildErrorWidget(FlutterErrorDetails details) {
    final isDark = themeSetting.mode == ThemeMode.dark;
    return Material(
      child: Container(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: .min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: isDark ? Colors.red.shade300 : Colors.red.shade400),
              const SizedBox(height: 16),
              Text('页面加载异常',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87)),
              const SizedBox(height: 8),
              Text('请尝试返回上一页或重启应用',
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : Colors.black45)),
              if (kDebugMode) ...[
                const SizedBox(height: 16),
                SelectableText(
                  details.exceptionAsString(),
                  style: TextStyle(fontSize: 11, color: Colors.red.shade300),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
