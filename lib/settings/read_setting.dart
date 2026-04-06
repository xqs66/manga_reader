import 'package:get/get.dart';
import 'package:manga_reader/service/base/config_bean.dart';
import 'package:manga_reader/service/base/service_lifecircle_bean.dart';
import 'package:manga_reader/service/storage_service.dart';
import 'package:manga_reader/shared/constants/constants.dart';

ReadSetting readSetting = ReadSetting();

class ReadSetting extends ConfigBean with ServiceBeanMixin {
  late final RxBool enableImmersiveMode;
  late final RxInt imageSpacing;
  late final RxBool enableGrayscaleMode;

  @override
  List<ServiceLifeCircleBean> get initDependencies => [storageService];

  @override
  Future<void> doInit() async {
    await applySavedConfigs();
  }

  @override
  Future<void> doAfterReady() async {}

  Future<void> applySavedConfigs() async {
    enableImmersiveMode =
        (storageService.read<bool>(ReadSettingKeys.enableImmersiveMode) ?? true)
            .obs;
    imageSpacing =
        (storageService.read<int>(ReadSettingKeys.imageSpacing) ??
                Constants.defaultImageSpacing)
            .obs;
    enableGrayscaleMode =
        (storageService.read<bool>(ReadSettingKeys.enableGrayscaleMode) ??
                false)
            .obs;
  }

  Future<void> saveEnableImmersiveMode(bool value) async {
    enableImmersiveMode.value = value;
    await saveConfig(ReadSettingKeys.enableImmersiveMode, value);
  }

  Future<void> saveImageSpacing(int value) async {
    imageSpacing.value = value;
    await saveConfig(ReadSettingKeys.imageSpacing, value);
  }

  Future<void> saveEnableGrayscaleMode(bool value) async {
    enableGrayscaleMode.value = value;
    await saveConfig(ReadSettingKeys.enableGrayscaleMode, value);
  }
}

class ReadSettingKeys {
  static const String enableImmersiveMode = 'enableImmersiveMode';
  static const String imageSpacing = 'imageSpacing';
  static const String enableGrayscaleMode = 'enableGrayScaleMode';
}
