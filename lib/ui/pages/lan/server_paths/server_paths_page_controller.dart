import 'package:get/get.dart';
import 'package:manga_reader/service/lan_client_service.dart';
import 'package:manga_reader/models/discovered_server.dart';
import 'package:manga_reader/ui/pages/lan/server_paths/server_paths_page_state.dart';

class ServerPathsPageController extends GetxController {
  final DiscoveredServer server;
  final LanClientService _clientService;

  ServerPathsPageController({required this.server})
      : _clientService = LanClientService(
          host: server.host,
          port: server.port,
          token: server.token,
        );

  late final state = ServerPathsPageState(server: server);

  static const String bodyId = 'serverPathsBodyId';
  static const String appBarId = 'serverPathsAppBarId';

  LanClientService get client => _clientService;

  @override
  void onReady() {
    super.onReady();
    _loadPaths();
  }

  Future<void> _loadPaths() async {
    try {
      state.paths = await _clientService.fetchPaths();
      state.isLoading = false;
    } catch (e) {
      state.error = e.toString();
      state.isLoading = false;
    }
    update([bodyId]);
  }

  @override
  void onClose() {
    _clientService.dispose();
    super.onClose();
  }
}
