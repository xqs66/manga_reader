import 'package:manga_reader/shared/utils/log_util.dart';

import '../../shared/constants/constants.dart';

abstract class ServiceLifeCircleBean {
  List<ServiceLifeCircleBean> get initDependencies;

  Future<void> initBean();

  Future<void> afterBeanReady();
}

mixin ServiceBeanMixin {
  Future<void> initBean() async {
    try {
      await doInit();
    } catch (e, stackTrace) {
      LogUtil.e('$runtimeType初始化错误', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> afterBeanReady() async {
    await doAfterReady();
    LogUtil.i('$runtimeType准备就绪', tag: Constants.tagBeanLifeCycle);
  }

  Future<void> doInit();

  Future<void> doAfterReady();
}