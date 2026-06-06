import 'dart:io' show Platform;

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Callback that runs in the foreground isolate on Android/iOS.
/// Keeps the app process alive while the LAN server is in the background.
@pragma('vm:entry-point')
void lanServerForegroundTask() {
  FlutterForegroundTask.setTaskHandler(LanServerTaskHandler());
}

class LanServerTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

/// Prevents the system from killing the app when the server is in the
/// background. On Android this shows a persistent notification; on iOS
/// it registers background execution. Desktop platforms are no-ops.
Future<void> startForegroundNotification(String address) async {
  if (!(Platform.isAndroid || Platform.isIOS)) return;

  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'lan_server_channel',
      channelName: '局域网服务',
      channelDescription: '漫画服务器运行状态通知',
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.nothing(),
      autoRunOnBoot: false,
      allowWifiLock: true,
    ),
  );

  await FlutterForegroundTask.startService(
    notificationTitle: '漫画服务器运行中',
    notificationText: address,
    callback: lanServerForegroundTask,
  );
}

Future<void> stopForegroundNotification() async {
  if (!(Platform.isAndroid || Platform.isIOS)) return;
  await FlutterForegroundTask.stopService();
}
