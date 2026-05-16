import 'package:get/get.dart';
import 'package:manga_reader/service/base/config_bean.dart';
import 'package:manga_reader/service/base/service_lifecircle_bean.dart';
import 'package:manga_reader/service/storage_service.dart';
import 'package:manga_reader/core/constants/constants.dart';
export 'package:manga_reader/core/enums/bookshelf_layout.dart';
export 'package:manga_reader/core/enums/reading_mode.dart';
import 'package:manga_reader/core/enums/bookshelf_layout.dart';
import 'package:manga_reader/core/enums/reading_mode.dart';

ReadSetting readSetting = ReadSetting();

class ReadSetting extends ConfigBean with ServiceBeanMixin {
  late final RxBool enableImmersiveMode;
  late final RxInt imageSpacing;
  late final RxBool enableGrayscaleMode;
  late final Rx<ReadingMode> readingMode;
  late final RxBool continueFromLastRead;
  late final Rx<BookshelfLayout> bookshelfLayout;
  late final RxBool enableVolumeKeyNavigation;
  late final RxInt doublePageSpacing;
  late final RxDouble contrast;
  late final RxDouble saturation;

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
    final modeIndex =
        storageService.read<int>(ReadSettingKeys.readingMode) ?? 0;
    readingMode = ReadingMode
        .values[modeIndex.clamp(0, ReadingMode.values.length - 1)]
        .obs;
    continueFromLastRead =
        (storageService.read<bool>(ReadSettingKeys.continueFromLastRead) ??
                true)
            .obs;
    final layoutIndex =
        storageService.read<int>(ReadSettingKeys.bookshelfLayout) ?? 0;
    bookshelfLayout = BookshelfLayout.values[layoutIndex.clamp(0, 1)].obs;
    enableVolumeKeyNavigation =
        (storageService.read<bool>(ReadSettingKeys.enableVolumeKeyNavigation) ?? false).obs;
    doublePageSpacing =
        (storageService.read<int>(ReadSettingKeys.doublePageSpacing) ?? 8).obs;
    contrast =
        (storageService.read<double>(ReadSettingKeys.contrast) ?? 1.0).obs;
    saturation =
        (storageService.read<double>(ReadSettingKeys.saturation) ?? 1.0).obs;
  }

  Future<void> saveBookshelfLayout(BookshelfLayout value) async {
    bookshelfLayout.value = value;
    await saveConfig(ReadSettingKeys.bookshelfLayout, value.index);
  }

  Future<void> saveContinueFromLastRead(bool value) async {
    continueFromLastRead.value = value;
    await saveConfig(ReadSettingKeys.continueFromLastRead, value);
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

  Future<void> saveReadingMode(ReadingMode value) async {
    readingMode.value = value;
    await saveConfig(ReadSettingKeys.readingMode, value.index);
  }

  Future<void> saveEnableVolumeKeyNavigation(bool value) async {
    enableVolumeKeyNavigation.value = value;
    await saveConfig(ReadSettingKeys.enableVolumeKeyNavigation, value);
  }

  Future<void> saveDoublePageSpacing(int value) async {
    doublePageSpacing.value = value;
    await saveConfig(ReadSettingKeys.doublePageSpacing, value);
  }

  Future<void> saveContrast(double value) async {
    contrast.value = value;
    await saveConfig(ReadSettingKeys.contrast, value);
  }

  Future<void> saveSaturation(double value) async {
    saturation.value = value;
    await saveConfig(ReadSettingKeys.saturation, value);
  }
}

class ReadSettingKeys {
  static const String enableImmersiveMode = 'enableImmersiveMode';
  static const String imageSpacing = 'imageSpacing';
  static const String enableGrayscaleMode = 'enableGrayScaleMode';
  static const String readingMode = 'readingMode';
  static const String continueFromLastRead = 'continueFromLastRead';
  static const String bookshelfLayout = 'bookshelfLayout';
  static const String enableVolumeKeyNavigation = 'enableVolumeKeyNavigation';
  static const String doublePageSpacing = 'doublePageSpacing';
  static const String contrast = 'contrast';
  static const String saturation = 'saturation';
}
