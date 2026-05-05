import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:get/get.dart' hide Value;
import 'package:manga_reader/core/result.dart';
import 'package:manga_reader/core/repository/manga_repository.dart';
import 'package:manga_reader/database/dao/group_dao.dart';
import 'package:manga_reader/database/dao/manga_dao.dart';
import 'package:manga_reader/database/database.dart';
import 'package:manga_reader/models/local_image.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/models/manga_id.dart';
import 'package:manga_reader/service/base/service_lifecircle_bean.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/shared/constants/constants.dart';
import 'package:manga_reader/shared/utils/log_util.dart';

class MangaRepositoryImpl with ServiceBeanMixin implements MangaRepository, ServiceLifeCircleBean {
  final LocalMangaService _service;

  MangaRepositoryImpl(this._service);

  @override
  List<ServiceLifeCircleBean> get initDependencies => [localMangaService];

  @override
  Future<void> doInit() async {
    Get.put<MangaRepository>(this);
  }

  @override
  Future<void> doAfterReady() async {}

  @override
  Future<Result<List<Manga>>> loadMangasInDir(Directory dir) async {
    try {
      final mangas = await _service.loadMangasInDir(dir);
      return Ok(mangas);
    } catch (e) {
      return Err('加载漫画失败', e);
    }
  }

  @override
  Future<Result<Manga>> loadManga(Directory dirOfManga) async {
    try {
      final manga = await _service.loadManga(dirOfManga);
      if (manga == null) return Err('该目录下未发现漫画');
      return Ok(manga);
    } catch (e) {
      return Err('加载漫画失败', e);
    }
  }

  @override
  Future<Result<Manga?>> tryLoadManga(Directory dirOfManga) async {
    try {
      return Ok(await _service.loadManga(dirOfManga));
    } catch (e) {
      return Err('加载漫画失败', e);
    }
  }

  @override
  List<LocalImage> getMangaImages(Manga manga) => _service.getMangaImages(manga);

  @override
  Future<List<LocalImage>> getMangaImagesAsync(Manga manga) =>
      _service.getMangaImagesAsync(manga);

  @override
  Future<Result<List<Manga>>> getMangasForPath(String path) async {
    try {
      return Ok(_service.settingPath2Mangas[path] ?? []);
    } catch (e) {
      return Err('获取漫画列表失败', e);
    }
  }

  @override
  Future<Result<void>> refreshMangasInDir(Directory dir) async {
    try {
      await _service.refreshMangasInDir(dir);
      return const Ok(null);
    } catch (e) {
      return Err('刷新失败', e);
    }
  }

  @override
  Future<Result<Manga>> mergeMangas(
    List<Manga> mangas,
    Directory output, {
    int imageNameStartFrom = 0,
    void Function(int current, int total)? onProgress,
  }) async {
    try {
      final result = await _service.mergeMangas(
        mangas,
        output,
        imageNameStartFrom: imageNameStartFrom,
        onProgress: onProgress,
      );
      if (result == null) return Err('合并失败：输出目录为空');
      return Ok(result);
    } catch (e) {
      LogUtil.e('合并失败', error: e);
      return Err('合并失败', e);
    }
  }

  @override
  Future<Result<void>> deleteManga(Manga manga) async {
    try {
      await _service.deleteManga(manga);
      return const Ok(null);
    } catch (e) {
      LogUtil.e('删除漫画失败', error: e);
      return Err('删除漫画失败', e);
    }
  }

  @override
  Future<Result<void>> deleteMangas(List<Manga> mangas) async {
    try {
      await _service.deleteMangas(mangas);
      return const Ok(null);
    } catch (e) {
      LogUtil.e('批量删除漫画失败', error: e);
      return Err('批量删除漫画失败', e);
    }
  }

  @override
  Future<Result<void>> deleteImage(LocalImage image) async {
    try {
      await _service.deleteImage(image);
      return const Ok(null);
    } catch (e) {
      LogUtil.e('删除图片失败', error: e);
      return Err('删除图片失败', e);
    }
  }

  @override
  Future<Result<List<String>>> fetchGroups(String? path) async {
    try {
      final groups = await GroupDao.selectAllGroups();
      return Ok(groups.map((g) => g.groupName).toList());
    } catch (e) {
      return Err('加载分组失败', e);
    }
  }

  @override
  Future<Result<void>> addGroup(String name) async {
    try {
      await GroupDao.insertGroup(name);
      return const Ok(null);
    } catch (e) {
      return Err('添加分组失败', e);
    }
  }

  @override
  Future<Result<void>> removeGroup(String name) async {
    try {
      await GroupDao.deleteGroup(name);
      return const Ok(null);
    } catch (e) {
      return Err('删除分组失败', e);
    }
  }

  @override
  Future<Result<void>> moveMangasToGroup(
      Set<MangaId> mangaIds, String groupName) async {
    try {
      await MangaDao.updateMangas(
        mangaIds
            .map((id) => MangaCompanion(
                id: Value(id.value), groupName: Value(groupName)))
            .toList(),
      );
      return const Ok(null);
    } catch (e) {
      return Err('移动分组失败', e);
    }
  }

  @override
  Future<Result<void>> resetMangasToDefaultGroup(
      String groupName, String? path) async {
    try {
      final mangas =
          path != null ? _service.settingPath2Mangas[path] ?? [] : [];
      await MangaDao.updateMangas(
        mangas
            .where((m) => m.groupName == groupName)
            .map((m) => MangaCompanion(
                id: Value(m.id.value),
                groupName: Value(Constants.defaultGroupName)))
            .toList(),
      );
      return const Ok(null);
    } catch (e) {
      return Err('重置分组失败', e);
    }
  }
}
