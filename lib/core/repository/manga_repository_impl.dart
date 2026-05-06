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
import 'package:manga_reader/core/constants/constants.dart';
import 'package:manga_reader/core/utils/log_util.dart';

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

  Future<Result<T>> _guard<T>(Future<T> Function() fn, String errorMsg) async {
    try {
      final value = await fn();
      return Ok(value);
    } catch (e) {
      LogUtil.e(errorMsg, error: e);
      return Err(errorMsg, e);
    }
  }

  @override
  Future<Result<List<Manga>>> loadMangasInDir(Directory dir) =>
      _guard(() => _service.loadMangasInDir(dir), '加载漫画失败');

  @override
  Future<Result<Manga>> loadManga(Directory dirOfManga) =>
      _guard(() async {
        final manga = await _service.loadManga(dirOfManga);
        if (manga == null) throw Exception('该目录下未发现漫画');
        return manga;
      }, '加载漫画失败');

  @override
  Future<Result<Manga?>> tryLoadManga(Directory dirOfManga) =>
      _guard(() => _service.loadManga(dirOfManga), '加载漫画失败');

  @override
  List<LocalImage> getMangaImages(Manga manga) => _service.getMangaImages(manga);

  @override
  Future<List<LocalImage>> getMangaImagesAsync(Manga manga) =>
      _service.getMangaImagesAsync(manga);

  @override
  Future<Result<List<Manga>>> getMangasForPath(String path) =>
      _guard(() => Future.value(_service.settingPath2Mangas[path] ?? []), '获取漫画列表失败');

  @override
  Future<Result<void>> refreshMangasInDir(Directory dir) =>
      _guard(() => _service.refreshMangasInDir(dir), '刷新失败');

  @override
  Future<Result<Manga>> mergeMangas(
    List<Manga> mangas,
    Directory output, {
    int imageNameStartFrom = 0,
    void Function(int current, int total)? onProgress,
  }) =>
      _guard(() async {
        final result = await _service.mergeMangas(
          mangas, output,
          imageNameStartFrom: imageNameStartFrom,
          onProgress: onProgress,
        );
        if (result == null) throw Exception('合并失败：输出目录为空');
        return result;
      }, '合并失败');

  @override
  Future<Result<void>> deleteManga(Manga manga) =>
      _guard(() => _service.deleteManga(manga), '删除漫画失败');

  @override
  Future<Result<void>> deleteMangas(List<Manga> mangas) =>
      _guard(() => _service.deleteMangas(mangas), '批量删除漫画失败');

  @override
  Future<Result<void>> deleteImage(LocalImage image) =>
      _guard(() => _service.deleteImage(image), '删除图片失败');

  @override
  Future<Result<List<GroupInfo>>> fetchGroups(String parentPath) =>
      _guard(() async {
        final groups = await GroupDao.selectAllGroups(parentPath);
        return groups
            .map((g) => GroupInfo(name: g.groupName, isExpanded: g.isExpanded))
            .toList();
      }, '加载分组失败');

  @override
  Future<Result<void>> updateGroupExpand(String name, String parentPath, bool isExpanded) =>
      _guard(() => GroupDao.updateGroup(
          name, parentPath, GroupCompanion(isExpanded: Value(isExpanded))), '更新分组状态失败');

  @override
  Future<Result<void>> addGroup(String name, String parentPath) =>
      _guard(() => GroupDao.insertGroup(name, parentPath), '添加分组失败');

  @override
  Future<Result<void>> removeGroup(String name, String parentPath) =>
      _guard(() => GroupDao.deleteGroup(name, parentPath), '删除分组失败');

  @override
  Future<Result<void>> moveMangasToGroup(Set<MangaId> mangaIds, String groupName) =>
      _guard(() => MangaDao.updateMangas(
          mangaIds
              .map((id) => MangaCompanion(id: Value(id.value), groupName: Value(groupName)))
              .toList()), '移动分组失败');

  @override
  Future<Result<void>> resetMangasToDefaultGroup(String groupName, String? path) =>
      _guard(() {
        final mangas = path != null ? _service.settingPath2Mangas[path] ?? [] : [];
        return MangaDao.updateMangas(
          mangas
              .where((m) => m.groupName == groupName)
              .map((m) => MangaCompanion(id: Value(m.id.value), groupName: Value(Constants.defaultGroupName)))
              .toList(),
        );
      }, '重置分组失败');
}
