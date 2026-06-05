import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/core/repository/manga_repository.dart';
import 'package:manga_reader/core/repository/remote_manga_repository.dart';
import 'package:manga_reader/models/local_image.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/models/manga_id.dart';
import 'package:manga_reader/models/result.dart';
import 'package:manga_reader/service/lan_client_service.dart';

/// A test double for [LanClientService] that returns controlled data
/// without making real HTTP calls.
class _FakeLanClientService extends LanClientService {
  _FakeLanClientService()
      : super(host: 'test.local', port: 9090, token: 'test-token');

  final _mangas = <String, List<Manga>>{};
  final _mangaDetails = <String, Manga>{};
  int _pageCount = 42;
  String? lastUpdatedProgressId;
  int? lastUpdatedProgressPage;

  // Configurable behavior
  bool failHealthCheck = false;
  bool failFetch = false;
  String failMessage = 'Connection refused';

  void addTestMangas(String path, List<Manga> mangas) {
    _mangas[path] = mangas;
    for (final m in mangas) {
      _mangaDetails[m.id.value] = m;
    }
  }

  @override
  Future<bool> healthCheck() async => !failHealthCheck;

  @override
  Future<({List<Manga> mangas, int total})> fetchMangas(
    String path, {
    int offset = 0,
    int limit = 50,
  }) async {
    if (failFetch) throw Exception(failMessage);
    final list = _mangas[path] ?? [];
    final page = list.skip(offset).take(limit).toList();
    return (mangas: page, total: list.length);
  }

  @override
  Future<Manga> fetchMangaDetail(String mangaId) async {
    if (failFetch) throw Exception(failMessage);
    return _mangaDetails[mangaId] ??
        (throw Exception('Manga not found: $mangaId'));
  }

  @override
  Future<int> fetchPageCount(String mangaId) async {
    if (failFetch) throw Exception(failMessage);
    return _pageCount;
  }

  @override
  Future<void> updateProgress(String mangaId, int lastReadPage) async {
    lastUpdatedProgressId = mangaId;
    lastUpdatedProgressPage = lastReadPage;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPaths() async {
    if (failFetch) throw Exception(failMessage);
    return _mangas.keys
        .map((p) => {'path': p, 'label': p, 'count': _mangas[p]?.length ?? 0})
        .toList();
  }

  @override
  Future<List<int>> fetchCover(String mangaId, {int? width}) async {
    if (failFetch) throw Exception(failMessage);
    return [0xFF, 0xD8, 0xFF]; // fake JPEG header
  }

  @override
  Future<List<int>> fetchPage(String mangaId, int pageIndex) async {
    if (failFetch) throw Exception(failMessage);
    return [0xFF, 0xD8, 0xFF];
  }

  @override
  void dispose() {}
}

Manga _createTestManga(String id, {String title = 'Test Manga', int pageCount = 42}) {
  return Manga(
    id: MangaId(id),
    path: '/test/$id',
    title: title,
    pageCount: pageCount,
    size: 1024 * 1024,
    lastReadPage: 0,
    groupName: '默认分组',
    cover: LocalImage(path: '/test/$id/cover.jpg'),
  );
}

void main() {
  late _FakeLanClientService client;
  late RemoteMangaRepository repo;

  setUp(() {
    client = _FakeLanClientService();
    repo = RemoteMangaRepository(client);
  });

  group('RemoteMangaRepository', () {
    group('isReadOnly', () {
      test('returns true', () {
        expect(repo.isReadOnly, isTrue);
      });
    });

    group('loadMangasInDir', () {
      test('returns mangas from client service', () async {
        final manga = _createTestManga('m1');
        client.addTestMangas('/remote/path', [manga]);

        final result = await repo.loadMangasInDir(Directory('/remote/path'));

        expect(result, isA<Ok<List<Manga>>>());
        final mangas = (result as Ok).value;
        expect(mangas.length, 1);
        expect(mangas.first.id.value, 'm1');
      });

      test('handles HTTP errors gracefully', () async {
        client.failFetch = true;
        client.failMessage = 'Connection timeout';

        final result = await repo.loadMangasInDir(Directory('/remote/path'));

        expect(result, isA<Err<List<Manga>>>());
        final err = result as Err;
        expect(err.message, contains('加载远程漫画失败'));
      });

      test('returns empty list for unknown path', () async {
        final result = await repo.loadMangasInDir(Directory('/unknown/path'));

        expect(result, isA<Ok<List<Manga>>>());
        final mangas = (result as Ok).value;
        expect(mangas, isEmpty);
      });
    });

    group('loadManga', () {
      test('returns single manga from client', () async {
        final mangaPath = '/remote/manga/detail-1';
        final expectedId = MangaId.fromPath(mangaPath).value;
        final manga = Manga(
          id: MangaId(expectedId),
          path: mangaPath,
          title: 'Detail Manga',
          pageCount: 42,
          size: 1024 * 1024,
          lastReadPage: 0,
          groupName: '默认分组',
          cover: LocalImage(path: '/test/cover.jpg'),
        );
        client.addTestMangas('/remote/path', [manga]);

        final result = await repo.loadManga(Directory(mangaPath));

        expect(result, isA<Ok<Manga>>());
        final loaded = (result as Ok).value;
        expect(loaded.title, 'Detail Manga');
        expect(loaded.id.value, expectedId);
      });

      test('throws when manga not found', () async {
        final result = await repo.loadManga(Directory('/unknown/manga'));

        expect(result, isA<Err<Manga>>());
      });
    });

    group('tryLoadManga', () {
      test('returns Ok(null) when fetch fails', () async {
        client.failFetch = true;

        final result = await repo.tryLoadManga(Directory('/any'));

        expect(result, isA<Ok<Manga?>>());
        expect((result as Ok).value, isNull);
      });
    });

    group('getMangaImages', () {
      test('returns remote URL-based LocalImages', () {
        final manga = _createTestManga('img-test', pageCount: 5);

        final images = repo.getMangaImages(manga);

        expect(images.length, 5);
        for (var i = 0; i < 5; i++) {
          final img = images[i];
          expect(img.isRemote, isTrue);
          expect(img.isLocal, isFalse);
          expect(img.url, contains('/api/v1/mangas/img-test/pages/$i'));
          expect(img.headers?['X-Auth-Token'], client.authHeaders['X-Auth-Token']);
        }
      });

      test('returns empty list for zero-page manga', () {
        final manga = _createTestManga('empty', pageCount: 0);
        final images = repo.getMangaImages(manga);
        expect(images, isEmpty);
      });
    });

    group('updateMangaReadProgress', () {
      test('delegates to client service', () async {
        await repo.updateMangaReadProgress(MangaId('prog-1'), 15);

        expect(client.lastUpdatedProgressId, 'prog-1');
        expect(client.lastUpdatedProgressPage, 15);
      });
    });

    group('fetchGroups', () {
      test('extracts group names from manga data', () async {
        final mangas = [
          Manga(
            id: MangaId('g1'),
            path: '/p/g1',
            title: 'M1',
            pageCount: 10,
            size: 100,
            lastReadPage: 0,
            groupName: 'A组',
            cover: LocalImage(path: '/cover.jpg'),
          ),
          Manga(
            id: MangaId('g2'),
            path: '/p/g2',
            title: 'M2',
            pageCount: 20,
            size: 200,
            lastReadPage: 0,
            groupName: 'B组',
            cover: LocalImage(path: '/cover.jpg'),
          ),
          Manga(
            id: MangaId('g3'),
            path: '/p/g3',
            title: 'M3',
            pageCount: 30,
            size: 300,
            lastReadPage: 0,
            groupName: 'A组',
            cover: LocalImage(path: '/cover.jpg'),
          ),
        ];
        client.addTestMangas('/test', mangas);

        final result = await repo.fetchGroups('/test');

        expect(result, isA<Ok<List<GroupInfo>>>());
        final groups = (result as Ok).value;
        expect(groups.map((g) => g.name).toSet(), {'A组', 'B组'});
        expect(groups.length, 2);
        // All groups should be expanded by default in remote repo
        for (final g in groups) {
          expect(g.isExpanded, isTrue);
        }
      });
    });

    group('write operations return errors', () {
      test('deleteManga returns Err', () async {
        final manga = _createTestManga('del');
        final result = await repo.deleteManga(manga);
        expect(result, isA<Err<void>>());
      });

      test('deleteImage returns Err', () async {
        const image = LocalImage(path: '/test.jpg');
        final result = await repo.deleteImage(image);
        expect(result, isA<Err<void>>());
      });

      test('addGroup returns Err', () async {
        final result = await repo.addGroup('test', '/path');
        expect(result, isA<Err<void>>());
      });

      test('removeGroup returns Err', () async {
        final result = await repo.removeGroup('test', '/path');
        expect(result, isA<Err<void>>());
      });

      test('moveMangasToGroup returns Err', () async {
        final result = await repo.moveMangasToGroup({MangaId('a')}, 'group');
        expect(result, isA<Err<void>>());
      });

      test('mergeMangas returns Err', () async {
        final result = await repo.mergeMangas([], Directory('/tmp'));
        expect(result, isA<Err<Manga>>());
      });

      test('deleteMangas returns Err', () async {
        final result = await repo.deleteMangas([]);
        expect(result, isA<Err<void>>());
      });

      test('resetMangasToDefaultGroup returns Err', () async {
        final result = await repo.resetMangasToDefaultGroup('g', '/p');
        expect(result, isA<Err<void>>());
      });

      test('updateGroupExpand returns Err', () async {
        final result = await repo.updateGroupExpand('g', '/p', true);
        expect(result, isA<Err<void>>());
      });
    });

    group('getMangasForPath', () {
      test('returns mangas via client', () async {
        final manga = _createTestManga('path-test');
        client.addTestMangas('/my/path', [manga]);

        final result = await repo.getMangasForPath('/my/path');

        expect(result, isA<Ok<List<Manga>>>());
        expect((result as Ok).value.length, 1);
      });
    });

    group('refreshMangasInDir', () {
      test('completes successfully', () async {
        client.addTestMangas('/refresh', [_createTestManga('r1')]);

        final result = await repo.refreshMangasInDir(Directory('/refresh'));

        expect(result, isA<Ok<void>>());
      });
    });
  });
}
