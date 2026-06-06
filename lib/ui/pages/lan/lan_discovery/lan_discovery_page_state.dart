import 'package:manga_reader/models/discovered_server.dart';

class LanDiscoveryPageState {
  bool isScanning = false;
  List<DiscoveredServer> discoveredServers = [];
  String manualHost = '';
  String manualPort = '9090';
  String manualToken = '';
}
