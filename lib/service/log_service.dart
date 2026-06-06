import 'dart:async';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:manga_reader/service/base/service_lifecircle_bean.dart';

/// Writes log entries to a local file with daily rotation.
/// Keeps logs for up to 7 days.
class _FileLogOutput extends LogOutput {
  final String _dir;
  DateTime _currentDay = DateTime.now();
  IOSink? _sink;

  _FileLogOutput(this._dir);

  Future<void> _init() async {
    await Directory(_dir).create(recursive: true);
    await _openLogForDay(_currentDay);
    await _cleanOldLogs();
  }

  String _logPath(DateTime day) {
    final name =
        'app_${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}.log';
    return p.join(_dir, name);
  }

  Future<void> _openLogForDay(DateTime day) async {
    await _sink?.flush();
    await _sink?.close();
    _sink = File(_logPath(day)).openWrite(mode: FileMode.append);
  }

  Future<void> _cleanOldLogs() async {
    try {
      final dir = Directory(_dir);
      if (!dir.existsSync()) return;
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      await for (final entry in dir.list()) {
        if (entry is File && entry.path.endsWith('.log')) {
          final stat = await entry.stat();
          if (stat.modified.isBefore(cutoff)) {
            await entry.delete();
          }
        }
      }
    } catch (_) {}
  }

  @override
  void output(OutputEvent event) {
    final now = DateTime.now();
    if (now.day != _currentDay.day) {
      _currentDay = now;
      _openLogForDay(now);
    }
    for (final line in event.lines) {
      _sink?.write('$line\n');
    }
    _sink?.write('\n');
  }

  void dispose() {
    _sink?.flush();
    _sink?.close();
    _sink = null;
  }
}

LogService logService = LogService();

class LogService with ServiceBeanMixin implements ServiceLifeCircleBean {
  /// Eagerly initialized so that [LogUtil] is safe to call even before
  /// [doInit] completes (e.g. from error handlers during startup).
  final Logger _consoleLog = Logger(
    output: ConsoleOutput(),
    printer: HybridPrinter(
      SimplePrinter(),
      error: PrettyPrinter(),
      fatal: PrettyPrinter(),
    ),
  );
  Logger? _fileLog;
  _FileLogOutput? _fileOutput;

  @override
  List<ServiceLifeCircleBean> get initDependencies => [];

  @override
  Future<void> doInit() async {
    try {
      final dir = await _logDirectory();
      _fileOutput = _FileLogOutput(dir);
      await _fileOutput!._init();
      _fileLog = Logger(
        output: _fileOutput!,
        printer: SimplePrinter(printTime: true, colors: false),
      );
    } catch (_) {}
  }

  Future<String> _logDirectory() async {
    if (Platform.isAndroid) {
      try {
        final ext = await getExternalStorageDirectory();
        if (ext != null) return p.join(ext.path, 'logs');
      } catch (_) {}
    }
    if (Platform.isWindows) {
      return p.join(Platform.environment['USERPROFILE'] ?? '.', 'manga_reader', 'logs');
    }
    if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'] ?? '.';
      return p.join(home, 'manga_reader', 'logs');
    }
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, 'logs');
  }

  @override
  Future<void> doAfterReady() async {}

  void i(
    String msg, {
    String? tag,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final m = _tag(tag, msg);
    _consoleLog.i(m, time: time, error: error, stackTrace: stackTrace);
    _fileLog?.i(m, time: time, error: error, stackTrace: stackTrace);
  }

  void d(
    String msg, {
    String? tag,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final m = _tag(tag, msg);
    _consoleLog.d(m, time: time, error: error, stackTrace: stackTrace);
    _fileLog?.d(m, time: time, error: error, stackTrace: stackTrace);
  }

  void w(
    String msg, {
    String? tag,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final m = _tag(tag, msg);
    _consoleLog.w(m, time: time, error: error, stackTrace: stackTrace);
    _fileLog?.w(m, time: time, error: error, stackTrace: stackTrace);
  }

  void e(
    String msg, {
    String? tag,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final m = _tag(tag, msg);
    _consoleLog.e(m, time: time, error: error, stackTrace: stackTrace);
    _fileLog?.e(m, time: time, error: error, stackTrace: stackTrace);
  }

  void f(
    String msg, {
    String? tag,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final m = _tag(tag, msg);
    _consoleLog.f(m, time: time, error: error, stackTrace: stackTrace);
    _fileLog?.f(m, time: time, error: error, stackTrace: stackTrace);
  }

  Future<void> dispose() async {
    _fileLog?.close();
    _fileOutput?.dispose();
  }

  static String _tag(String? tag, String msg) {
    return tag != null && tag.isNotEmpty ? '[$tag] $msg' : msg;
  }
}
