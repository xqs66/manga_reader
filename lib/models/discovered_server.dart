class DiscoveredServer {
  final String host;
  final int port;
  final String token;
  final String deviceName;
  final String version;
  final DateTime? lastConnectedAt;
  final bool isConnected;

  const DiscoveredServer({
    required this.host,
    required this.port,
    required this.token,
    required this.deviceName,
    this.version = '1.0.0',
    this.lastConnectedAt,
    this.isConnected = false,
  });

  String get baseUrl => 'http://$host:$port';

  String get displayName => deviceName.isNotEmpty ? deviceName : host;

  DiscoveredServer copyWith({
    String? host,
    int? port,
    String? token,
    String? deviceName,
    String? version,
    DateTime? lastConnectedAt,
    bool? isConnected,
  }) {
    return DiscoveredServer(
      host: host ?? this.host,
      port: port ?? this.port,
      token: token ?? this.token,
      deviceName: deviceName ?? this.deviceName,
      version: version ?? this.version,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  Map<String, dynamic> toJson() => {
        'host': host,
        'port': port,
        'token': token,
        'deviceName': deviceName,
        'version': version,
        'lastConnectedAt': lastConnectedAt?.toIso8601String(),
      };

  factory DiscoveredServer.fromJson(Map<String, dynamic> json) {
    return DiscoveredServer(
      host: json['host'] as String,
      port: json['port'] as int,
      token: json['token'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? '',
      version: json['version'] as String? ?? '1.0.0',
      lastConnectedAt: json['lastConnectedAt'] != null
          ? DateTime.tryParse(json['lastConnectedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DiscoveredServer && other.host == host && other.port == port;

  @override
  int get hashCode => Object.hash(host, port);
}
