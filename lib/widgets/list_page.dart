import 'package:flutter/material.dart';

/// Abstract base for pages that display a scrollable list of sectioned
/// settings/action tiles (EditPage, SettingsPage, MorePage).
abstract class ListPage extends StatelessWidget {
  const ListPage({super.key});

  String get title;

  List<Widget> buildItems(BuildContext context);

  Widget sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: Color(0xFF757575), letterSpacing: 0.5,
      )),
    );
  }

  Widget section(String title, Widget card) {
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [sectionHeader(title), const SizedBox(height: 8), card],
    );
  }

  Widget card(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: .circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: .circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, size: 20) : null),
      shape: RoundedRectangleBorder(borderRadius: .circular(12)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: buildItems(context),
      ),
    );
  }
}
