import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:manga_reader/core/utils/log_util.dart';
import 'package:manga_reader/models/discovered_server.dart';
import 'package:manga_reader/service/lan_client_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'lan_discovery_page_state.dart';

class LanDiscoveryPageController extends GetxController {
  final state = LanDiscoveryPageState();
  static const String bodyId = 'lanDiscoveryBodyId';

  final _scannerController = MobileScannerController();

  MobileScannerController get scannerController => _scannerController;

  Future<DiscoveredServer?> scanQrCode() async {
    try {
      final result = await Get.to<DiscoveredServer?>(
        () => _QrScannerPage(controller: this),
        fullscreenDialog: true,
      );
      if (result != null) {
        final ok = await _connectToServer(result);
        return ok ? result : null;
      }
    } catch (e) {
      LogUtil.e('QR scan failed', error: e);
      Fluttertoast.showToast(msg: '无法打开相机，请尝试手动输入');
    }
    return null;
  }

  Future<bool> _connectToServer(DiscoveredServer server) async {
    final client = LanClientService(
      host: server.host,
      port: server.port,
      token: server.token,
    );

    LogUtil.i('Connecting to ${server.host}:${server.port}', tag: 'LAN');
    final ok = await client.healthCheck();
    client.dispose();

    if (!ok) {
      Fluttertoast.showToast(msg: '无法连接到 ${server.displayName}');
      return false;
    }

    Fluttertoast.showToast(msg: '已连接到 ${server.displayName}');
    return true;
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

    final ok = await _connectToServer(server);
    return ok ? server : null;
  }

  @override
  void onClose() {
    _scannerController.dispose();
    super.onClose();
  }
}

/// Full-screen QR scanner page.
class _QrScannerPage extends StatefulWidget {
  final LanDiscoveryPageController controller;

  const _QrScannerPage({required this.controller});

  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  // Guard against MobileScanner firing onDetect repeatedly while the route
  // is being popped — a second Get.back would pop the page below instead.
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('扫描二维码'), centerTitle: false),
      body: MobileScanner(
        controller: widget.controller.scannerController,
        onDetect: (capture) {
          if (_handled) return;
          final barcodes = capture.barcodes;
          if (barcodes.isEmpty) return;
          final value = barcodes.first.rawValue;
          if (value == null) return;
          final server = _parseQrValue(value);
          if (server != null) {
            if (Get.isRegistered<LanDiscoveryPageController>()) {
              _handled = true;
              Get.back(result: server);
            }
          } else {
            Fluttertoast.showToast(msg: '无效的二维码，请扫描服务器页面的二维码');
          }
        },
      ),
    );
  }

  static DiscoveredServer? _parseQrValue(String value) {
    try {
      final uri = Uri.parse(value);
      if (uri.scheme == 'mangareader' && uri.host == 'connect') {
        final host = uri.queryParameters['host'];
        final port = int.tryParse(uri.queryParameters['port'] ?? '') ?? 9090;
        final token = uri.queryParameters['token'] ?? '';
        if (host != null && host.isNotEmpty) {
          return DiscoveredServer(host: host, port: port, token: token, deviceName: host);
        }
      }
    } catch (_) {}
    // Fallback: try parsing as raw host:port:token
    try {
      final parts = value.split(':');
      if (parts.length >= 2) {
        return DiscoveredServer(
          host: parts[0],
          port: int.tryParse(parts[1]) ?? 9090,
          token: parts.length >= 3 ? parts[2] : '',
          deviceName: parts[0],
        );
      }
    } catch (_) {}
    return null;
  }
}
