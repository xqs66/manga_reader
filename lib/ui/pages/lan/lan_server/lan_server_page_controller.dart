import 'package:get/get.dart';
import 'package:manga_reader/service/lan_server_service.dart';
import 'package:manga_reader/service/storage_service.dart';
import 'package:manga_reader/ui/pages/lan/lan_server/lan_server_page_state.dart';

class LanServerPageController extends GetxController {
  LanServerPageController();

  final state = LanServerPageState();

  static const String bodyId = 'lanServerBodyId';
  static const _wifiNoticeKey = 'lan_server_wifi_notice_dismissed';
  static const _batteryNoticeKey = 'lan_server_battery_notice_dismissed';

  @override
  void onInit() {
    super.onInit();
    _syncFromService();
    state.wifiNoticeDismissed = storageService.read<bool>(_wifiNoticeKey) ?? false;
    state.batteryNoticeDismissed = storageService.read<bool>(_batteryNoticeKey) ?? false;
  }

  void dismissWifiNotice() {
    state.wifiNoticeDismissed = true;
    storageService.write(_wifiNoticeKey, true);
    update([bodyId]);
  }

  void dismissBatteryNotice() {
    state.batteryNoticeDismissed = true;
    storageService.write(_batteryNoticeKey, true);
    update([bodyId]);
  }

  void _syncFromService() {
    if (lanServerService.isRunning) {
      state.isRunning = true;
      state.address = lanServerService.address;
      state.token = lanServerService.token;
    }
  }

  Future<void> startServer() async {
    if (lanServerService.isRunning) {
      _syncFromService();
      update([bodyId]);
      return;
    }
    final addr = await lanServerService.start();
    state.isRunning = true;
    state.address = addr;
    state.token = lanServerService.token;
    final host = addr.split(':')[0];
    state.connectionUrl = 'mangareader://connect?host=$host&port=9090&token=${lanServerService.token}';
    update([bodyId]);
  }

  Future<void> stopServer() async {
    await lanServerService.stop();
    state.isRunning = false;
    state.address = '';
    state.token = '';
    state.connectionUrl = '';
    update([bodyId]);
  }
}
