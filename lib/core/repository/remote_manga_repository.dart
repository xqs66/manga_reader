import 'dart:io';

import 'package:manga_reader/models/local_image.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/models/manga_id.dart';
import 'package:manga_reader/models/result.dart';
import 'package:manga_reader/core/repository/manga_repository.dart';
import 'package:manga_reader/core/utils/log_util.dart';
import 'package:manga_reader/service/lan_client_service.dart';

/// Repository implementation that fetches manga data from a remote LAN server.
///
/// Implements [MangaRepository] so existing Controllers and Pages work
/// unchanged after switching the repository instance.
class RemoteMangaRepository implements MangaRepository {
  final LanClientService _client;

  RemoteMangaRepository(this._client);

  @override
  bool get isReadOnly => true;

  // ── Helpers ──

  Future<Result<T>> _guard<T>(Future<T> Function() fn, String errorMsg) async {
    try {
      final value = await fn();
      return Ok(value);
    } catch (e) {
      LogUtil.e(errorMsg, error: e);
      return Err(errorMsg, e);
    }
  }

  Result<T> _unsupported<T>(String operation) =>
      Err('远程漫画不支持$operation');

  // ── Read operations ──

  @override
  Future<Result<List<Manga>>> loadMangasInDir(Directory dir) async =>
      _guard(() async {
        final result = await _client.fetchMangas(dir.path);
        return result.mangas;
      }, '加载远程漫画失败');

  @override
  Future<Result<Manga>> loadManga(Directory dirOfManga) async =>
      _guard(() => _client.fetchMangaDetail(
          MangaId.fromPath(dirOfManga.path).value), '加载远程漫画失败');

  @override
  Future<Result<Manga?>> tryLoadManga(Directory dirOfManga) async {
    try {
      final manga = await _client.fetchMangaDetail(
          MangaId.fromPath(dirOfManga.path).value);
      return Ok(manga);
    } catch (e) {
      return const Ok(null);
    }
  }

  @override
  List<LocalImage> getMangaImages(Manga manga) {
    return List.generate(manga.pageCount, (i) => LocalImage(
          url: '${_client.baseUrl}/api/v1/mangas/${manga.id.value}/pages/$i',
          headers: _client.authHeaders,
        ));
  }

  @override
  Future<List<LocalImage>> getMangaImagesAsync(Manga manga) async {
    // Try to fetch actual page count from server, fall back to manga.pageCount
    try {
      await _client.fetchPageCount(manga.id.value);
    } catch (_) {
      // Use manga.pageCount from metadata
    }
    return getMangaImages(manga);
  }

  @override
  Future<Result<List<Manga>>> getMangasForPath(String path) async =>
      _guard(() async {
        final result = await _client.fetchMangas(path);
        return result.mangas;
      }, '获取远程漫画列表失败');

  @override
  Future<Result<void>> refreshMangasInDir(Directory dir) async =>
      _guard(() async {
        await _client.fetchMangas(dir.path);
        // Data is fresh from server — nothing to persist locally in Phase 1
      }, '刷新远程漫画失败');

  @override
  Future<void> updateMangaReadProgress(MangaId id, int lastReadPage) async {
    try {
      await _client.updateProgress(id.value, lastReadPage);
    } catch (e) {
      LogUtil.e('同步阅读进度到远程服务器失败', error: e);
    }
  }

  @override
  Future<Result<List<Manga>>> getReadingHistory({int limit = 100}) async =>
      _guard(() async => <Manga>[], '获取阅读历史失败');

  @override
  Future<Result<ReadingStats>> getReadingStats() async =>
      _guard(() async => const ReadingStats(
            todayCount: 0, weekCount: 0,
            totalReadCount: 0, totalMangaCount: 0,
          ), '获取阅读统计失败');

  @override
  Future<Result<List<GroupInfo>>> fetchGroups(String parentPath) async =>
      _guard(() async {
        final result = await _client.fetchMangas(parentPath);
        // Extract unique groups from manga list
        final groupNames = result.mangas
            .map((m) => m.groupName)
            .toSet()
            .toList();
        return groupNames
            .map((name) => GroupInfo(name: name, isExpanded: true))
            .toList();
      }, '获取远程分组失败');

  // ── Unsupported write operations ──

  @override
  Future<Result<Manga>> mergeMangas(
    List<Manga> mangas,
    Directory output, {
    int imageNameStartFrom = 0,
    void Function(int current, int total)? onProgress,
  }) async =>
      _unsupported('合并漫画');

  @override
  Future<Result<void>> deleteManga(Manga manga) async =>
      _unsupported('删除漫画');

  @override
  Future<Result<void>> deleteMangas(List<Manga> mangas) async =>
      _unsupported('批量删除漫画');

  @override
  Future<Result<void>> deleteImage(LocalImage image) async =>
      _unsupported('删除图片');

  @override
  Future<Result<void>> addGroup(String name, String parentPath) async =>
      _unsupported('新建分组');

  @override
  Future<Result<void>> removeGroup(String name, String parentPath) async =>
      _unsupported('删除分组');

  @override
  Future<Result<void>> updateGroupExpand(
    String name,
    String parentPath,
    bool isExpanded,
  ) async =>
      _unsupported('更新分组状态');

  @override
  Future<Result<void>> moveMangasToGroup(
    Set<MangaId> mangaIds,
    String groupName,
  ) async =>
      _unsupported('移动分组');

  @override
  Future<Result<void>> resetMangasToDefaultGroup(
    String groupName,
    String? path,
  ) async =>
      _unsupported('重置分组');
}
