import 'package:manga_reader/core/utils/log_util.dart';

import '../../core/constants/constants.dart';

abstract interface class ServiceLifeCircleBean {
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
    try {
      await doAfterReady();
      LogUtil.i('$runtimeType准备就绪', tag: Constants.tagBeanLifeCycle);
    } catch (e, stackTrace) {
      LogUtil.e('$runtimeType afterReady错误', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> doInit();

  Future<void> doAfterReady();
}