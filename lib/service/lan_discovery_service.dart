import 'dart:async';

import 'package:manga_reader/core/utils/log_util.dart';
import 'package:manga_reader/models/discovered_server.dart';
import 'package:multicast_dns/multicast_dns.dart';

class LanDiscoveryService {
  MDnsClient? _mdnsClient;
  bool _isScanning = false;

  bool get isScanning => _isScanning;

  /// Scan the local network for _manga-reader._tcp.local services.
  /// Returns a list of discovered servers.
  /// Falls back to empty list on any error (e.g. Android `reusePort`).
  Future<List<DiscoveredServer>> scanLan({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_isScanning) return [];
    _isScanning = true;

    final servers = <DiscoveredServer>[];
    try {
      _mdnsClient = MDnsClient();
      try {
        await _mdnsClient!.start();
      } catch (e) {
        // Known issue: MDnsClient.start() may fail on Android with
        // "reusePort not supported on this platform" from dart:io.
        LogUtil.e('mDNS client start failed — falling back to manual IP', error: e);
        return servers;
      }

      final completer = Completer<void>();
      Timer(timeout, () {
        if (!completer.isCompleted) completer.complete();
      });

      StreamSubscription<PtrResourceRecord>? sub;
      try {
        sub = _mdnsClient!
            .lookup<PtrResourceRecord>(
              ResourceRecordQuery.serverPointer('_manga-reader._tcp.local'),
            )
            .listen(
          (ptr) async {
            try {
              await _resolveService(ptr.domainName, servers);
            } catch (e) {
              LogUtil.e('mDNS: failed to resolve ${ptr.domainName}', error: e);
            }
          },
          onDone: () {
            if (!completer.isCompleted) completer.complete();
          },
          onError: (e) {
            LogUtil.e('mDNS scan error', error: e);
            if (!completer.isCompleted) completer.complete();
          },
        );
      } catch (e) {
        LogUtil.e('mDNS lookup failed', error: e);
        return servers;
      }

      await completer.future;
      await sub.cancel();
    } catch (e) {
      LogUtil.e('mDNS scan failed', error: e);
    } finally {
      _isScanning = false;
      _mdnsClient?.stop();
    }

    return servers;
  }

  Future<void> _resolveService(
    String domainName,
    List<DiscoveredServer> servers,
  ) async {
    final client = _mdnsClient;
    if (client == null) return;

    String? host;
    int? port;
    String token = '';
    String deviceName = '';
    String version = '1.0.0';

    final srvSub = client
        .lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(domainName),
        )
        .listen(
      (srv) {
        host = srv.target;
        port = srv.port;
      },
    );

    final txtSub = client
        .lookup<TxtResourceRecord>(
          ResourceRecordQuery.text(domainName),
        )
        .listen(
      (txt) {
        final text = txt.text;
        if (text.startsWith('token=')) {
          token = text.substring(6);
        } else if (text.startsWith('deviceName=')) {
          deviceName = text.substring(11);
        } else if (text.startsWith('version=')) {
          version = text.substring(8);
        }
      },
    );

    // Wait briefly for SRV and TXT records to arrive
    await Future.delayed(const Duration(milliseconds: 800));
    await srvSub.cancel();
    await txtSub.cancel();

    final resolvedHost = host;
    final resolvedPort = port;
    if (resolvedHost != null && resolvedPort != null) {
      servers.add(DiscoveredServer(
        host: resolvedHost,
        port: resolvedPort,
        token: token,
        deviceName: deviceName,
        version: version,
      ));
    }
  }

  void stopScan() {
    _mdnsClient?.stop();
    _mdnsClient = null;
    _isScanning = false;
  }

  void dispose() {
    stopScan();
  }
}
