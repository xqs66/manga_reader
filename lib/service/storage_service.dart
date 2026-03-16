import 'package:get_storage/get_storage.dart';
import 'package:manga_reader/service/base/service_lifecircle_bean.dart';
import 'package:manga_reader/service/path_service.dart';
import 'package:manga_reader/shared/constants/constants.dart';
import 'package:manga_reader/shared/utils/log_util.dart';

StorageService storageService = StorageService();

class StorageService with ServiceBeanMixin implements ServiceLifeCircleBean {
  @override
  List<ServiceLifeCircleBean> get initDependencies => [pathService];

  late final GetStorage _storage;

  @override
  Future<void> doAfterReady() async {
  }

  @override
  Future<void> doInit() async {
    _storage = GetStorage('get_storage');
    await _storage.initStorage;
  }

  Future<void> write(String key, dynamic value) {
    return _storage.write(key, value);
  }

  T? read<T>(String key) {
    return _storage.read(key);
  }

  T getKeys<T>() {
    return _storage.getKeys();
  }

  Future<void> remove(String key) async {
    _storage.remove(key);
  }
}
