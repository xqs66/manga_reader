import 'package:logger/logger.dart';

class LogUtil {
  static final Logger _log = Logger(
    printer: HybridPrinter(
      SimplePrinter(),
      error: PrettyPrinter(),
      fatal: PrettyPrinter(),
    ),
  );

  static void i(
    String msg, {
    String? tag,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log.i(
      _getTaggedMsg(msg, tag: tag),
      time: time,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void d(
    String msg, {
    String? tag,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log.d(
      _getTaggedMsg(msg, tag: tag),
      time: time,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void w(
    String msg, {
    String? tag,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log.w(
      _getTaggedMsg(msg, tag: tag),
      time: time,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void e(
    String msg, {
    String? tag,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log.e(
      _getTaggedMsg(msg, tag: tag),
      time: time,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void f(
    String msg, {
    String? tag,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log.f(
      _getTaggedMsg(msg, tag: tag),
      time: time,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static String _getTaggedMsg(String msg, {String? tag}) {
    return tag?.isNotEmpty ?? false ? '[$tag]  $msg' : msg;
  }
}
