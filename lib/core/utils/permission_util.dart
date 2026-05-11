import 'dart:io' show Platform;

import 'package:permission_handler/permission_handler.dart';

class PermissionUtil {
  static Future<bool> checkAndRequestStoragePermission() async {
    if (!Platform.isAndroid) return true;
    var permission = Permission.manageExternalStorage;
    var status = await permission.status;
    if (status.isDenied) {
      status = await permission.request();
    }
    if (!status.isGranted) {
      openAppSettings();
      return false;
    }
    return true;
  }
}
