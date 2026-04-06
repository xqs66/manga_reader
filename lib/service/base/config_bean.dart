import 'package:manga_reader/service/base/service_lifecircle_bean.dart';
import 'package:manga_reader/service/storage_service.dart';

abstract class ConfigBean implements ServiceLifeCircleBean {
  Future<void> saveConfig(String key, dynamic value) {
    return storageService.write(key, value);
  }
}
