import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/routes.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('设置'), centerTitle: true),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('本地'),
            trailing: Icon(Icons.arrow_forward_ios, size: 15),
            onTap: () => Get.toNamed(Routes.localSetting),
          ),
          ListTile(
            leading: Icon(Icons.book),
            title: Text('阅读'),
            trailing: Icon(Icons.arrow_forward_ios, size: 15),
            onTap: () => Get.toNamed(Routes.readSetting),
          ),
        ],
      ),
    );
  }
}
