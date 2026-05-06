import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:manga_reader/routes/app_route_observer.dart';
import 'package:manga_reader/service/base/service_lifecircle_bean.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/service/path_service.dart';
import 'package:manga_reader/service/storage_service.dart';
import 'package:manga_reader/settings/read_setting.dart';
import 'package:manga_reader/shared/utils/log_util.dart';
import 'package:manga_reader/core/repository/manga_repository_impl.dart';
import 'package:manga_reader/pages/home_page.dart';
import 'package:manga_reader/routes/routes.dart';
import 'package:manga_reader/settings/path_setting.dart';
import 'package:manga_reader/settings/theme_setting.dart';

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF5C6BC0),
      brightness: brightness,
    ),
    scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
    appBarTheme: AppBarTheme(
      surfaceTintColor: Colors.transparent,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      foregroundColor: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
      scrolledUnderElevation: 2,
      shadowColor: isDark ? Colors.black38 : Colors.black12,
      elevation: 1,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
      ),
    ),
    bottomAppBarTheme: BottomAppBarThemeData(
      elevation: 4,
      shadowColor: Colors.black26,
      surfaceTintColor: Colors.transparent,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 4,
      shadowColor: Colors.black26,
      surfaceTintColor: Colors.transparent,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      indicatorColor: const Color(0xFF5C6BC0).withValues(alpha: isDark ? 0.2 : 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFE0E0E0) : null);
        }
        return TextStyle(fontSize: 12, color: isDark ? const Color(0xFFBDBDBD) : null);
      }),
    ),
    cardTheme: CardThemeData(
      elevation: isDark ? 1 : 2,
      shadowColor: isDark ? Colors.black38 : Colors.black26,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: .circular(12)),
      color: isDark ? const Color(0xFF2C2C2C) : null,
    ),
  );
}

final mangaRepo = MangaRepositoryImpl(localMangaService);

List<ServiceLifeCircleBean> serviceBeans = [
  pathSetting,
  pathService,
  storageService,
  localMangaService,
  readSetting,
  mangaRepo,
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
      SystemChrome.setEnabledSystemUIMode(.edgeToEdge);

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
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: getThemeMode(),
      getPages: Routes.pages,
      navigatorObservers: [routeObserver],
      home: HomePage(),
      onReady: () {
        for (final bean in serviceBeans) {
          bean.afterBeanReady();
        }
      },
    );
  }
}
