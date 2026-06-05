import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:manga_reader/core/constants/constants.dart';
import 'package:manga_reader/core/extensions/string_ext.dart';
import 'package:manga_reader/core/repository/manga_repository.dart';
import 'package:manga_reader/models/result.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/ui/pages/mangas/mangas_page_controller.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/ui/widgets/dialogs/common_dialog.dart';
import 'package:manga_reader/ui/widgets/styled_menu.dart';

class GroupManagePage extends StatefulWidget {
  const GroupManagePage({super.key});

  @override
  State<GroupManagePage> createState() => _GroupManagePageState();
}

class _GroupManagePageState extends State<GroupManagePage> {
  final _controller = Get.find<MangasPageController>();
  final _repo = Get.find<MangaRepository>();
  final _allGroups = <String, List<String>>{};

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    _allGroups.clear();
    for (final e in localMangaService.settingPath2Mangas.entries) {
      final mangas = e.value;
      final fromMangas = mangas.map((m) => m.groupName).toSet();
      final result = await _repo.fetchGroups(e.key);
      if (result is Ok) {
        final dbGroups = result.okValue!.map((g) => g.name);
        fromMangas.addAll(dbGroups.where((g) => !fromMangas.contains(g)));
      }
      _allGroups[e.key] = fromMangas.toList()..sort();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final entries = localMangaService.settingPath2Mangas.entries.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('分组管理'), centerTitle: true),
      body: GetBuilder<MangasPageController>(
        id: _controller.bodyId,
        builder: (_) {
          if (_allGroups.isEmpty && entries.isNotEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (entries.isEmpty) {
            return const Center(child: Text('暂无漫画源路径'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final path = entries[i].key;
              final mangas = entries[i].value;
              final groups = _allGroups[path] ?? [];
              final displayPath = path.displayPath();
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: .circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    ListTile(
                      dense: true,
                      title: Text(displayPath, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF757575))),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_rounded, size: 20),
                        onPressed: () => _showAddDialog(context, _controller, path),
                        tooltip: '添加分组',
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ...groups.map(
                      (g) =>
                          _buildGroupTile(context, _controller, g, mangas, path),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGroupTile(
    BuildContext context,
    MangasPageController controller,
    String name,
    List<Manga> mangas,
    String parentPath,
  ) {
    final count = mangas.where((m) => m.groupName == name).length;
    final isDefault = name == Constants.defaultGroupName;
    return ListTile(
      leading: const Icon(Icons.folder_rounded, color: Colors.orange, size: 22),
      title: Text(
        name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '$count 部漫画',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert_rounded, size: 20),
        onPressed: () =>
            _showActions(context, controller, name, isDefault, parentPath),
      ),
      shape: RoundedRectangleBorder(borderRadius: .circular(12)),
    );
  }

  void _showActions(
    BuildContext context,
    MangasPageController controller,
    String name,
    bool isDefault,
    String parentPath,
  ) {
    if (isDefault) {
      Fluttertoast.showToast(msg: '默认分组不支持修改');
      return;
    }
    StyledActionSheet.show(
      context: context,
      actions: [
        StyledAction(
          label: '重命名',
          onPressed: () =>
              _showRenameDialog(context, controller, name, parentPath),
        ),
        StyledAction(
          label: '删除',
          isDestructive: true,
          onPressed: () =>
              _showDeleteDialog(context, controller, name, parentPath),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context, MangasPageController controller, String path) {
    final text = TextEditingController();
    Get.dialog(CommonDialog(
      title: '新建分组',
      content: TextField(
        autofocus: true,
        controller: text,
        decoration: const InputDecoration(hintText: '请输入分组名称'),
      ),
      onConfirm: () async {
        final name = text.text.trim();
        if (name.isEmpty) {
          Fluttertoast.showToast(msg: '分组名不能为空');
          return;
        }
        final mangas = localMangaService.settingPath2Mangas[path] ?? [];
        if (mangas.any((m) => m.groupName == name)) {
          Fluttertoast.showToast(msg: '该分组名已存在');
          return;
        }
        await controller.handleAddGroupToPath(name, path);
        Get.back();
        _loadGroups();
      },
    ));
  }

  void _showRenameDialog(
    BuildContext context,
    MangasPageController controller,
    String oldName,
    String parentPath,
  ) {
    final text = TextEditingController(text: oldName);
    Get.dialog(
      CommonDialog(
        title: '重命名分组',
        content: TextField(
          autofocus: true,
          controller: text,
          decoration: const InputDecoration(hintText: '请输入新名称'),
        ),
        onConfirm: () async {
          final newName = text.text.trim();
          if (newName.isNotEmpty && newName != oldName) {
            await controller.handleRenameGroupInPath(oldName, newName, parentPath);
          }
          Get.back();
          _loadGroups();
        },
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    MangasPageController controller,
    String groupName,
    String parentPath,
  ) {
    final state = controller.state;
    Get.dialog(
      GetBuilder<MangasPageController>(
        id: controller.deleteGroupDialogId,
        builder: (_) {
          return CommonDialog(
            title: '删除分组"$groupName"',
            content: Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                const Text('请选择对该分组下漫画的处理方式：', style: TextStyle(fontSize: 15)),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: state.toDefaultGroupOnceDelete,
                  onChanged: (v) =>
                      controller.handleChangeDeleteGroupOption(v ?? false),
                  title: const Text('移动至默认分组'),
                  contentPadding: .zero,
                  horizontalTitleGap: 0,
                  controlAffinity: .leading,
                  dense: true,
                ),
                CheckboxListTile(
                  value: state.deleteOnceGroupDeleted,
                  onChanged: (v) =>
                      controller.handleChangeDeleteGroupOption(!(v ?? false)),
                  title: const Text('同时删除分组下漫画'),
                  subtitle: const Text('此操作不可恢复'),
                  contentPadding: .zero,
                  horizontalTitleGap: 0,
                  controlAffinity: .leading,
                  dense: true,
                ),
              ],
            ),
            onConfirm: () async {
              await controller.handleDeleteGroupInPath(groupName, parentPath);
              Get.back();
              _loadGroups();
            },
          );
        },
      ),
    );
  }
}
