import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/core/constants/constants.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/pages/mangas/layout/list_layout.dart';
import 'package:manga_reader/widgets/styled_menu.dart';

class GroupListView extends ListLayout {
  final List<String> groups;
  final List<Manga> allMangas;
  final void Function(String groupName) onEnter;
  final Widget Function(String groupName) deleteGroupDialogBuilder;

  const GroupListView({
    super.key,
    required this.groups,
    required this.allMangas,
    required this.onEnter,
    required this.deleteGroupDialogBuilder,
  });

  @override
  int get itemCount => groups.length;

  List<Manga> _mangasInGroup(String name) =>
      allMangas.where((m) => m.groupName == name).toList();

  @override
  Widget buildItem(BuildContext context, int index) {
    final name = groups[index];
    final count = _mangasInGroup(name).length;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: .circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: const Icon(Icons.folder_rounded, color: Colors.indigo),
        title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text('$count 部', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        trailing: const Icon(Icons.chevron_right_rounded),
        shape: RoundedRectangleBorder(borderRadius: .circular(12)),
        onTap: () => onEnter(name),
        onLongPress: name == Constants.defaultGroupName
            ? null
            : () => StyledActionSheet.show(
                  context: context,
                  actions: [
                    StyledAction(
                      label: '删除分组',
                      isDestructive: true,
                      onPressed: () => Get.dialog(deleteGroupDialogBuilder(name)),
                    ),
                  ],
                ),
      ),
    );
  }
}
