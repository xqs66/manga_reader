import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/models/discovered_server.dart';

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
              // Scan button
              _buildScanSection(controller, state),
              const SizedBox(height: 20),
              // Discovered servers
              if (state.discoveredServers.isNotEmpty) ...[
                _buildDiscoveredServers(controller, state),
                const SizedBox(height: 20),
              ],
              // Manual connection
              _buildManualSection(controller, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }

  // ── Scan ──

  Widget _buildScanSection(
    LanDiscoveryPageController controller,
    LanDiscoveryPageState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('扫描局域网'),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: state.isScanning ? null : controller.startScan,
            icon: state.isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_find_rounded),
            label: Text(state.isScanning ? '扫描中...' : '开始扫描'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Discovered servers ──

  Widget _buildDiscoveredServers(
    LanDiscoveryPageController controller,
    LanDiscoveryPageState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          '发现的服务器',
          subtitle: '(${state.discoveredServers.length})',
        ),
        ...state.discoveredServers.map((s) => _buildServerCard(
              controller: controller,
              server: s,
            )),
      ],
    );
  }

  Widget _buildServerCard({
    required LanDiscoveryPageController controller,
    required DiscoveredServer server,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: UiConfig.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.computer_rounded,
                color: UiConfig.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    server.displayName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${server.host}:${server.port}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            FilledButton(
              onPressed: () async {
                final result = await controller.connectToServer(server);
                if (result != null && Get.isRegistered<LanDiscoveryPageController>()) {
                  Get.back(result: result);
                }
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('连接'),
            ),
          ],
        ),
      ),
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
