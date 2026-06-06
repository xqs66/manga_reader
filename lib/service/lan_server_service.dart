import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:manga_reader/core/utils/file_util.dart';
import 'package:manga_reader/core/utils/log_util.dart';
import 'package:manga_reader/core/utils/zip_reader.dart';
import 'package:manga_reader/models/local_image.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/service/base/service_lifecircle_bean.dart';
import 'package:manga_reader/service/foreground_task_handler.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/settings/path_setting.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

LanServerService lanServerService = LanServerService();

class LanServerService with ServiceBeanMixin implements ServiceLifeCircleBean {
  HttpServer? _server;
  final int port = 9090;
  String _token = '';
  String _address = '';
  bool _isRunning = false;

  /// Caches image paths per manga ID to avoid repeated disk scans.
  final Map<String, List<LocalImage>> _imageCache = {};

  /// Caches open [ZipReader] instances keyed by manga ID.
  final Map<String, ZipReader> _zipReaderCache = {};

  bool get isRunning => _isRunning;
  String get token => _token;
  String get address => _address;
  int get connectedClients => 0; // TODO: track via middleware

  @override
  List<ServiceLifeCircleBean> get initDependencies => [
        localMangaService,
        pathSetting,
      ];

  @override
  Future<void> doInit() async {}

  @override
  Future<void> doAfterReady() async {}

  String _generateToken() {
    final rng = Random();
    return rng.nextInt(999999).toString().padLeft(6, '0');
  }

  Future<String> start() async {
    if (_isRunning) return '${await _getLocalIp()}:$port';
    _token = _generateToken();

    final router = Router()
      ..get('/api/v1/health', _handleHealth)
      ..get('/api/v1/paths', _handleGetPaths)
      ..get('/api/v1/mangas', _handleGetMangas)
      ..get('/api/v1/mangas/<id>', _handleGetMangaDetail)
      ..get('/api/v1/mangas/<id>/cover', _handleGetCover)
      ..get('/api/v1/mangas/<id>/pages', _handleGetPageList)
      ..get('/api/v1/mangas/<id>/pages/<n>', _handleGetPage)
      ..put('/api/v1/mangas/<id>/progress', _handlePutProgress);

    final handler =
        const shelf.Pipeline().addMiddleware(_corsHeaders()).addMiddleware(
              _authMiddleware(),
            ).addHandler(router.call);

    _server = await io.serve(handler, InternetAddress.anyIPv4, port);
    _isRunning = true;
    _address = '${await _getLocalIp()}:$port';
    LogUtil.i('LAN server started at $_address');

    // Keep process alive on Android when app goes to background.
    startForegroundNotification(_address);

    return _address;
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    stopForegroundNotification();
    await _server?.close(force: true);
    _server = null;
    _isRunning = false;
    _address = '';
    _imageCache.clear();
    for (final reader in _zipReaderCache.values) {
      reader.close();
    }
    _zipReaderCache.clear();
    LogUtil.i('LAN server stopped');
  }

  // ── Middleware ──

  shelf.Middleware _corsHeaders() {
    return (handler) => (request) async {
          if (request.method == 'OPTIONS') {
            return shelf.Response.ok('', headers: _baseCorsHeaders());
          }
          final response = await handler(request);
          return response.change(headers: _baseCorsHeaders());
        };
  }

  Map<String, String> _baseCorsHeaders() => {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, PUT, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, X-Auth-Token',
      };

  shelf.Middleware _authMiddleware() {
    return (handler) => (request) async {
          // Health check and OPTIONS don't need auth
          if (request.url.path == 'api/v1/health' || request.method == 'OPTIONS') {
            return handler(request);
          }
          final clientToken = request.headers['X-Auth-Token'];
          // Only reject if client sends a non-empty token that doesn't match.
          // Clients without a token are allowed through (Phase 1 simplicity).
          if (clientToken != null &&
              clientToken.isNotEmpty &&
              _token.isNotEmpty &&
              clientToken != _token) {
            return shelf.Response.forbidden(
              jsonEncode({'error': '无效的访问令牌'}),
              headers: {'Content-Type': 'application/json'},
            );
          }
          return handler(request);
        };
  }

  // ── Handlers ──

  shelf.Response _handleHealth(shelf.Request request) {
    return shelf.Response.ok(
      jsonEncode({
        'version': '1.0.0',
        'uptime': 0,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  shelf.Response _handleGetPaths(shelf.Request request) {
    final paths = pathSetting.paths.map((p) {
      final mangas = localMangaService.settingPath2Mangas[p] ?? [];
      return {
        'path': p,
        'label': _displayPath(p),
        'count': mangas.length,
      };
    }).toList();

    return shelf.Response.ok(
      jsonEncode({'paths': paths}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  shelf.Response _handleGetMangas(shelf.Request request) {
    final path = request.url.queryParameters['path'];
    if (path == null) {
      return shelf.Response.badRequest();
    }

    final allMangas = localMangaService.settingPath2Mangas[path] ?? [];
    final offset = int.tryParse(request.url.queryParameters['offset'] ?? '0') ?? 0;
    final limit = int.tryParse(request.url.queryParameters['limit'] ?? '100000') ?? 100000;

    final page = allMangas.skip(offset).take(limit).toList();
    return shelf.Response.ok(
      jsonEncode({
        'mangas': page.map(_serializeManga).toList(),
        'total': allMangas.length,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  shelf.Response _handleGetMangaDetail(shelf.Request request, String id) {
    final manga = _findMangaById(id);
    if (manga == null) return shelf.Response.notFound('{}');
    return shelf.Response.ok(
      jsonEncode(_serializeManga(manga)),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<shelf.Response> _handleGetCover(shelf.Request request, String id) async {
    final manga = _findMangaById(id);
    if (manga == null) return shelf.Response.notFound('');

    try {
      final coverPath = manga.cover.path;
      if (coverPath == null || !File(coverPath).existsSync()) {
        return shelf.Response.notFound('');
      }
      final bytes = await File(coverPath).readAsBytes();
      return shelf.Response.ok(
        bytes,
        headers: {
          'Content-Type': _mimeFromPath(coverPath),
          'Cache-Control': 'public, max-age=3600',
        },
      );
    } catch (e) {
      LogUtil.e('Failed to serve cover for manga $id', error: e);
      return shelf.Response.internalServerError();
    }
  }

  Future<shelf.Response> _handleGetPageList(shelf.Request request, String id) async {
    final manga = _findMangaById(id);
    if (manga == null) return shelf.Response.notFound('{}');
    return shelf.Response.ok(
      jsonEncode({'pages': manga.pageCount}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<shelf.Response> _handleGetPage(shelf.Request request, String id, String n) async {
    final pageIndex = int.tryParse(n);
    if (pageIndex == null) return shelf.Response.badRequest();

    final manga = _findMangaById(id);
    if (manga == null) return shelf.Response.notFound('');

    try {
      if (_isZipType(manga.path)) {
        return _serveZipPage(manga, pageIndex);
      }

      return _serveFolderPage(manga, pageIndex);
    } catch (e) {
      LogUtil.e('Failed to serve page $n of manga $id', error: e);
      return shelf.Response.internalServerError();
    }
  }

  Future<shelf.Response> _serveFolderPage(Manga manga, int pageIndex) async {
    final images = _getCachedFolderImages(manga);
    if (pageIndex >= images.length) {
      return shelf.Response.notFound('');
    }

    final imagePath = images[pageIndex].path;
    if (imagePath == null) return shelf.Response.notFound('');
    final bytes = await File(imagePath).readAsBytes();

    return shelf.Response.ok(
      bytes,
      headers: _imageHeaders(imagePath, pageIndex, images.length),
    );
  }

  Future<shelf.Response> _serveZipPage(Manga manga, int pageIndex) async {
    try {
      final reader = await _getZipReader(manga);
      if (reader == null) return shelf.Response.internalServerError();

      final entries = reader.readEntries().where((e) => _isImageName(e.name)).toList()
        ..sort((a, b) => FileUtil.naturalCompare(a.name, b.name));
      if (pageIndex >= entries.length) return shelf.Response.notFound('');
      final bytes = reader.readEntryContent(entries[pageIndex]);
      return shelf.Response.ok(
        bytes,
        headers: _imageHeaders(entries[pageIndex].name, pageIndex, entries.length),
      );
    } catch (e) {
      LogUtil.e('Failed to serve ZIP page $pageIndex of ${manga.id}', error: e);
      return shelf.Response.internalServerError();
    }
  }

  Future<ZipReader?> _getZipReader(Manga manga) async {
    final cached = _zipReaderCache[manga.id.value];
    if (cached != null) return cached;
    try {
      final reader = await ZipReader.open(File(manga.path));
      _zipReaderCache[manga.id.value] = reader;
      return reader;
    } catch (e) {
      LogUtil.e('Failed to open ZIP reader for ${manga.path}', error: e);
      return null;
    }
  }

  /// Returns cached image list for folder-type [manga], populating the cache on first call.
  List<LocalImage> _getCachedFolderImages(Manga manga) {
    final cached = _imageCache[manga.id.value];
    if (cached != null) return cached;

    final images = localMangaService.getMangaImages(manga);
    _imageCache[manga.id.value] = images;
    return images;
  }

  Map<String, String> _imageHeaders(String path, int index, int total) => {
        'Content-Type': _mimeFromPath(path),
        'Cache-Control': 'public, max-age=3600',
        'X-Page-Index': '$index',
        'X-Total-Pages': '$total',
      };

  static bool _isImageName(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp');
  }

  Future<shelf.Response> _handlePutProgress(shelf.Request request, String id) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final lastReadPage = json['lastReadPage'] as int? ?? 0;

      final manga = _findMangaById(id);
      if (manga == null) return shelf.Response.notFound('{}');

      // Update in-memory cache
      final parentPath = Directory(manga.path).parent.path;
      final list = localMangaService.settingPath2Mangas[parentPath];
      if (list != null) {
        final i = list.indexWhere((m) => m.id.value == id);
        if (i != -1) {
          list[i] = manga.copyWith(lastReadPage: lastReadPage);
        }
      }

      return shelf.Response.ok(
        jsonEncode({'ok': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return shelf.Response.internalServerError();
    }
  }

  // ── Helpers ──

  Manga? _findMangaById(String id) {
    for (final mangas in localMangaService.settingPath2Mangas.values) {
      for (final m in mangas) {
        if (m.id.value == id) return m;
      }
    }
    return null;
  }

  Map<String, dynamic> _serializeManga(Manga m) => {
        'id': m.id.value,
        'path': m.path,
        'title': m.title,
        'pageCount': m.pageCount,
        'size': m.size,
        'lastReadPage': m.lastReadPage,
        'lastReadTime': m.lastReadTime?.toUtc().toIso8601String(),
        'groupName': m.groupName,
        'type': _isZipType(m.path) ? 2 : 1,
      };

  bool _isZipType(String path) =>
      path.endsWith('.zip') || path.endsWith('.cbz') || path.endsWith('.epub');

  String _mimeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }

  String _displayPath(String path) {
    // Show a user-friendly path label
    final parts = path.split(Platform.pathSeparator);
    return parts.last.isNotEmpty ? parts.last : path;
  }

  Future<String> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '0.0.0.0';
  }
}
