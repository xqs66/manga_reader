import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:manga_reader/models/local_image.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/models/manga_id.dart';

class LanClientService {
  final String host;
  final int port;
  final String token;
  final HttpClient _httpClient = HttpClient();

  LanClientService({
    required this.host,
    required this.port,
    required this.token,
  });

  String get baseUrl => 'http://$host:$port';

  Map<String, String> get authHeaders => {
        if (token.isNotEmpty) 'X-Auth-Token': token,
      };

  // ── Health ──

  Future<bool> healthCheck() async {
    try {
      final (status, _) = await _get('/api/v1/health');
      return status == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Paths ──

  Future<List<Map<String, dynamic>>> fetchPaths() async {
    final (status, body) = await _get('/api/v1/paths');
    if (status != 200) throw Exception('获取路径列表失败: $status');
    final json = jsonDecode(body) as Map<String, dynamic>;
    return (json['paths'] as List).cast<Map<String, dynamic>>();
  }

  // ── Mangas ──

  Future<({List<Manga> mangas, int total})> fetchMangas(
    String path, {
    int offset = 0,
    int limit = 50,
  }) async {
    final encoded = Uri.encodeComponent(path);
    final (status, body) = await _get(
      '/api/v1/mangas?path=$encoded&offset=$offset&limit=$limit',
    );
    if (status != 200) throw Exception('获取漫画列表失败: $status');
    final json = jsonDecode(body) as Map<String, dynamic>;
    final list = (json['mangas'] as List)
        .cast<Map<String, dynamic>>()
        .map((m) => _deserializeManga(m))
        .toList();
    return (mangas: list, total: json['total'] as int);
  }

  Future<Manga> fetchMangaDetail(String mangaId) async {
    final (status, body) = await _get('/api/v1/mangas/$mangaId');
    if (status != 200) throw Exception('获取漫画详情失败: $status');
    final json = jsonDecode(body) as Map<String, dynamic>;
    return _deserializeManga(json);
  }

  // ── Cover ──

  Future<List<int>> fetchCover(String mangaId, {int? width}) async {
    var url = '/api/v1/mangas/$mangaId/cover';
    if (width != null) url += '?width=$width';
    final (status, body) = await _getBytes(url);
    if (status != 200) throw Exception('获取封面失败: $status');
    return body;
  }

  // ── Pages ──

  Future<int> fetchPageCount(String mangaId) async {
    final (status, body) = await _get('/api/v1/mangas/$mangaId/pages');
    if (status != 200) throw Exception('获取页面列表失败: $status');
    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['pages'] as int;
  }

  Future<List<int>> fetchPage(String mangaId, int pageIndex) async {
    final (status, body) = await _getBytes(
      '/api/v1/mangas/$mangaId/pages/$pageIndex',
    );
    if (status != 200) throw Exception('获取页面失败: $status');
    return body;
  }

  // ── Progress ──

  Future<void> updateProgress(String mangaId, int lastReadPage) async {
    final body = jsonEncode({
      'lastReadPage': lastReadPage,
      'lastReadTime': DateTime.now().toUtc().toIso8601String(),
    });
    final (status, _) = await _put(
      '/api/v1/mangas/$mangaId/progress',
      body: body,
    );
    if (status != 200) throw Exception('更新阅读进度失败: $status');
  }

  // ── Internal ──

  Future<(int, String)> _get(String path) async {
    final request = await _httpClient.getUrl(_uri(path));
    _addHeaders(request);
    final response = await request.close().timeout(
          const Duration(seconds: 30),
        );
    final body = await response.transform(utf8.decoder).join();
    return (response.statusCode, body);
  }

  Future<(int, List<int>)> _getBytes(String path) async {
    final request = await _httpClient.getUrl(_uri(path));
    _addHeaders(request);
    final response = await request.close().timeout(
          const Duration(seconds: 60),
        );
    final bytes = await response.fold<List<int>>(
      <int>[],
      (prev, chunk) => prev..addAll(chunk),
    );
    return (response.statusCode, bytes);
  }

  Future<(int, String)> _put(String path, {required String body}) async {
    final request = await _httpClient.putUrl(_uri(path));
    _addHeaders(request);
    request.headers.contentType = ContentType.json;
    request.write(body);
    final response = await request.close().timeout(
          const Duration(seconds: 10),
        );
    final responseBody = await response.transform(utf8.decoder).join();
    return (response.statusCode, responseBody);
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  void _addHeaders(HttpClientRequest request) {
    request.headers.add('Accept', 'application/json');
    if (token.isNotEmpty) {
      request.headers.add('X-Auth-Token', token);
    }
  }

  Manga _deserializeManga(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final baseUrl = this.baseUrl;
    return Manga(
      id: MangaId(id),
      path: json['path'] as String? ?? '',
      title: json['title'] as String? ?? '',
      pageCount: json['pageCount'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
      lastReadPage: json['lastReadPage'] as int? ?? 0,
      lastReadTime: json['lastReadTime'] != null
          ? DateTime.tryParse(json['lastReadTime'] as String)
          : null,
      groupName: json['groupName'] as String? ?? '默认分组',
      cover: LocalImage(
        url: '$baseUrl/api/v1/mangas/$id/cover?width=400',
        headers: authHeaders,
      ),
    );
  }

  void dispose() {
    _httpClient.close();
  }
}
