import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import 'lan_server_page_controller.dart';
import 'lan_server_page_state.dart';

class LanServerPage extends StatelessWidget {
  const LanServerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LanServerPageController());
    final state = controller.state;

    return GetBuilder<LanServerPageController>(
      id: LanServerPageController.bodyId,
      builder: (_) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('局域网服务'),
            centerTitle: false,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Spacer(flex: 1),
                  // Status indicator
                  _buildStatusIndicator(state),
                  const SizedBox(height: 32),
                  // Server info card
                  _buildInfoCard(controller, state),
                  const SizedBox(height: 24),
                  // Start/Stop button
                  _buildControlButton(controller, state),
                  const Spacer(flex: 2),
                  // Security notice
                  _buildSecurityNotice(controller, state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(LanServerPageState state) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: state.isRunning
                ? Colors.green.shade50
                : Colors.grey.shade100,
            border: Border.all(
              color: state.isRunning ? Colors.green : Colors.grey.shade300,
              width: 3,
            ),
          ),
          child: Icon(
            state.isRunning ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            size: 40,
            color: state.isRunning ? Colors.green : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          state.isRunning ? '● 运行中' : '○ 未启动',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: state.isRunning ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(LanServerPageController controller, LanServerPageState state) {
    if (!state.isRunning) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCopyRow(
              label: '地址',
              value: state.address,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: state.address));
                Fluttertoast.showToast(msg: '地址已复制');
              },
            ),
            const Divider(height: 20),
            _buildCopyRow(
              label: 'Token',
              value: state.token,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: state.token));
                Fluttertoast.showToast(msg: 'Token 已复制');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyRow({
    required String label,
    required String value,
    required VoidCallback onCopy,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontFamily: 'monospace',
            ),
          ),
        ),
        IconButton(
          onPressed: onCopy,
          icon: const Icon(Icons.copy_rounded, size: 18),
        ),
      ],
    );
  }

  Widget _buildControlButton(
    LanServerPageController controller,
    LanServerPageState state,
  ) {
    return SizedBox(
      width: 200,
      height: 44,
      child: state.isRunning
          ? OutlinedButton.icon(
              onPressed: controller.stopServer,
              icon: const Icon(Icons.stop_rounded),
              label: const Text('停止服务'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          : FilledButton.icon(
              onPressed: controller.startServer,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('启动服务'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
    );
  }

  Widget _buildSecurityNotice(LanServerPageController controller, LanServerPageState state) {
    if (state.wifiNoticeDismissed && state.batteryNoticeDismissed) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        if (!state.wifiNoticeDismissed)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '此服务仅在当前 WiFi 网络下可访问',
                    style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                  ),
                ),
                TextButton(
                  onPressed: controller.dismissWifiNotice,
                  child: Text(
                    '不再提示',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.blueGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (!state.wifiNoticeDismissed || !state.batteryNoticeDismissed)
          const SizedBox(height: 8),
        if (!state.batteryNoticeDismissed)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.battery_alert_rounded, size: 18, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '请关闭本应用的电池优化，否则锁屏或切到后台后服务可能被系统终止',
                    style: TextStyle(fontSize: 13, color: Colors.brown),
                  ),
                ),
                TextButton(
                  onPressed: controller.dismissBatteryNotice,
                  child: Text(
                    '不再提示',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.brown,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.brown,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
