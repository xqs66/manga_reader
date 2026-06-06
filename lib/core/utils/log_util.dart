import 'package:manga_reader/service/log_service.dart';

/// Convenience static wrapper around [LogService].
/// Prefer injecting [logService] where possible; use this for quick access.
class LogUtil {
  static void i(
    String msg, {
    String? tag,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      logService.i(msg, tag: tag, time: time, error: error, stackTrace: stackTrace);

  static void d(
    String msg, {
    String? tag,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      logService.d(msg, tag: tag, time: time, error: error, stackTrace: stackTrace);

  static void w(
    String msg, {
    String? tag,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      logService.w(msg, tag: tag, time: time, error: error, stackTrace: stackTrace);

  static void e(
    String msg, {
    String? tag,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      logService.e(msg, tag: tag, time: time, error: error, stackTrace: stackTrace);

  static void f(
    String msg, {
    String? tag,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      logService.f(msg, tag: tag, time: time, error: error, stackTrace: stackTrace);
}
