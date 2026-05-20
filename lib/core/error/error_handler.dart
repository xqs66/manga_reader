import 'package:flutter/foundation.dart';
import 'package:manga_reader/core/error/app_exception.dart';
import 'package:manga_reader/core/utils/log_util.dart';

/// One-time setup of all global error handlers. Call before runApp().
void setupGlobalErrorHandlers() {
  FlutterError.onError = _onFlutterError;
  PlatformDispatcher.instance.onError = _onPlatformError;
}

void _onFlutterError(FlutterErrorDetails details) {
  // In debug, let Flutter's default red screen show so we can inspect the
  // widget tree. In release, log and present a controlled fallback.
  FlutterError.presentError(details);

  final msg = details.exceptionAsString();
  LogUtil.e('Flutter error: $msg',
      error: details.exception, stackTrace: details.stack);
}

bool _onPlatformError(Object error, StackTrace stackTrace) {
  LogUtil.e('Unhandled error', error: error, stackTrace: stackTrace);
  return true; // don't terminate
}

/// Log + optionally show toast for domain-layer failures caught in controllers.
void handleAppError(Object e, StackTrace s) {
  if (e is AppException) {
    LogUtil.w(e.userMessage, error: e, stackTrace: s);
    return;
  }
  LogUtil.e('Unexpected error', error: e, stackTrace: s);
}
