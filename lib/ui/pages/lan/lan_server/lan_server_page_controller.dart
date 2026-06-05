import 'package:get/get.dart';
import 'package:manga_reader/service/lan_server_service.dart';
import 'package:manga_reader/ui/pages/lan/lan_server/lan_server_page_state.dart';

class LanServerPageController extends GetxController {
  LanServerPageController();

  final state = LanServerPageState();

  static const String bodyId = 'lanServerBodyId';

  @override
  void onInit() {
    super.onInit();
    // Restore state from global singleton (survives page navigation)
    _syncFromService();
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
    update([bodyId]);
  }

  Future<void> stopServer() async {
    await lanServerService.stop();
    state.isRunning = false;
    state.address = '';
    state.token = '';
    update([bodyId]);
  }
}
