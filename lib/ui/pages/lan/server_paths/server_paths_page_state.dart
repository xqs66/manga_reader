import 'package:manga_reader/models/discovered_server.dart';

class ServerPathsPageState {
  final DiscoveredServer server;
  List<Map<String, dynamic>> paths = [];
  bool isLoading = true;
  String? error;

  ServerPathsPageState({required this.server});
}
