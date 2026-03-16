import 'dart:io';

import 'package:manga_reader/service/base/service_lifecircle_bean.dart';
import 'package:path_provider/path_provider.dart';

import '../shared/constants/constants.dart';
import '../shared/utils/log_util.dart';

PathService pathService = PathService();

class PathService with ServiceBeanMixin implements ServiceLifeCircleBean {
  @override
  List<ServiceLifeCircleBean> get initDependencies => [];

  Directory? appExternalStorageDir;

  Directory? get appExternalStorageRootDir =>
      appExternalStorageDir?.parent.parent.parent.parent;

  @override
  Future<void> doAfterReady() async {}

  @override
  Future<void> doInit() async {
    await getExternalStorageDirectory()
        .then((value) => appExternalStorageDir = value)
        .onError((e, stack) {
          LogUtil.e(e.toString(), tag: Constants.tagBeanLifeCycle);
          return null;
        });
  }
}
