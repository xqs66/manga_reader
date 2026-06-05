import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:manga_reader/models/discovered_server.dart';
import 'package:manga_reader/service/lan_client_service.dart';
import 'package:manga_reader/service/lan_discovery_service.dart';
import 'package:manga_reader/service/storage_service.dart';
import 'package:manga_reader/ui/pages/lan/lan_discovery/lan_discovery_page_state.dart';

class LanDiscoveryPageController extends GetxController {
  final LanDiscoveryService _discoveryService;

  LanDiscoveryPageController({
    LanDiscoveryService? discoveryService,
  }) : _discoveryService = discoveryService ?? LanDiscoveryService();

  final state = LanDiscoveryPageState();

  static const String bodyId = 'lanDiscoveryBodyId';

  static const String _savedServersKey = 'lan_saved_servers';

  /// Persisted known servers (even when offline).
  List<DiscoveredServer> get savedServers {
    final raw = storageService.read<List<dynamic>>(_savedServersKey);
    if (raw == null) return [];
    return raw
        .cast<Map<String, dynamic>>()
        .map((m) => DiscoveredServer.fromJson(m))
        .toList();
  }

  Future<void> _saveServer(DiscoveredServer server) async {
    final servers = savedServers
        .where((s) => s != server)
        .toList();
    servers.insert(0, server.copyWith(lastConnectedAt: DateTime.now()));
    await storageService.write(
      _savedServersKey,
      servers.map((s) => s.toJson()).toList(),
    );
  }

  Future<void> removeSavedServer(DiscoveredServer server) async {
    final servers = savedServers.where((s) => s != server).toList();
    await storageService.write(
      _savedServersKey,
      servers.map((s) => s.toJson()).toList(),
    );
    update([bodyId]);
  }

  Future<void> startScan() async {
    if (state.isScanning) return;
    state.isScanning = true;
    state.discoveredServers = [];
    update([bodyId]);

    final servers = await _discoveryService.scanLan();
    state.discoveredServers = servers;
    state.isScanning = false;
    update([bodyId]);

    if (servers.isEmpty) {
      Fluttertoast.showToast(msg: '未发现服务器，请尝试手动输入 IP 连接');
    }
  }

  Future<DiscoveredServer?> connectToServer(DiscoveredServer server) async {
    final client = LanClientService(
      host: server.host,
      port: server.port,
      token: server.token,
    );

    final ok = await client.healthCheck();
    client.dispose();

    if (!ok) {
      Fluttertoast.showToast(msg: '无法连接到 ${server.displayName}');
      return null;
    }

    await _saveServer(server);
    Fluttertoast.showToast(msg: '已连接到 ${server.displayName}');
    update([bodyId]);
    return server;
  }

  Future<DiscoveredServer?> connectManual() async {
    final host = state.manualHost.trim();
    final port = int.tryParse(state.manualPort.trim()) ?? 9090;
    final token = state.manualToken.trim();

    if (host.isEmpty) {
      Fluttertoast.showToast(msg: '请输入服务器地址');
      return null;
    }

    final server = DiscoveredServer(
      host: host,
      port: port,
      token: token,
      deviceName: host,
    );

    return connectToServer(server);
  }

  @override
  void onClose() {
    _discoveryService.dispose();
    super.onClose();
  }
}
