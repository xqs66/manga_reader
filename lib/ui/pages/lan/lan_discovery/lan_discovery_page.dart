import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'lan_discovery_page_controller.dart';
import 'lan_discovery_page_state.dart';

class LanDiscoveryPage extends StatelessWidget {
  const LanDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LanDiscoveryPageController());
    final state = controller.state;

    return GetBuilder<LanDiscoveryPageController>(
      id: LanDiscoveryPageController.bodyId,
      builder: (_) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('添加服务器'),
            centerTitle: false,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // QR scan button
              _buildQrScanSection(controller),
              const SizedBox(height: 20),
              // Manual connection
              _buildManualSection(controller, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ── QR Scan ──

  Widget _buildQrScanSection(LanDiscoveryPageController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('扫描二维码'),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton.icon(
            onPressed: () async {
              final result = await controller.scanQrCode();
              if (result != null && Get.isRegistered<LanDiscoveryPageController>()) {
                Get.back(result: result);
              }
            },
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('扫描服务器二维码'),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Manual connection ──

  Widget _buildManualSection(
    LanDiscoveryPageController controller,
    LanDiscoveryPageState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('手动连接'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: TextEditingController(text: state.manualHost)
                  ..selection = TextSelection.collapsed(
                    offset: state.manualHost.length,
                  ),
                onChanged: (v) => state.manualHost = v,
                decoration: InputDecoration(
                  hintText: '192.168.1.100',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: TextField(
                controller: TextEditingController(text: state.manualPort)
                  ..selection = TextSelection.collapsed(
                    offset: state.manualPort.length,
                  ),
                onChanged: (v) => state.manualPort = v,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '9090',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () async {
                final result = await controller.connectManual();
                if (result != null && Get.isRegistered<LanDiscoveryPageController>()) {
                  Get.back(result: result);
                }
              },
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('连接'),
            ),
          ],
        ),
      ],
    );
  }
}
