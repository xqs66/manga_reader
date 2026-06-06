import 'dart:io' show Platform;

import 'package:permission_handler/permission_handler.dart';

class PermissionUtil {
  static Future<bool> checkAndRequestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Try MANAGE_EXTERNAL_STORAGE first (required for Android 11+).
    // On Android 10 and below this permission doesn't exist and will
    // return permanentlyDenied — fall back to legacy storage permission.
    final status = await _requestPermission(Permission.manageExternalStorage);
    if (status.isGranted) return true;

    final legacyStatus = await _requestPermission(Permission.storage);
    if (legacyStatus.isGranted) return true;

    openAppSettings();
    return false;
  }

  static Future<PermissionStatus> _requestPermission(Permission permission) async {
    var status = await permission.status;
    if (status.isDenied) {
      status = await permission.request();
    }
    return status;
  }
}
