import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/core/constants/constants.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/ui/pages/mangas/mangas_page_controller.dart';
import 'package:manga_reader/ui/layout/grid/grid_layout.dart';
import 'package:manga_reader/ui/pages/mangas/group_grid_card.dart';
import 'package:manga_reader/ui/widgets/styled_menu.dart';

class GroupGridView extends GridLayout {
  final List<String> groups;
  final List<Manga> allMangas;
  final MangasPageController controller;
  final void Function(String groupName) onEnter;
  final Widget Function(String groupName) deleteGroupDialogBuilder;

  const GroupGridView({
    super.key,
    required this.groups,
    required this.allMangas,
    required this.controller,
    required this.onEnter,
    required this.deleteGroupDialogBuilder,
  });

  @override
  int get itemCount => groups.length;

  List<Manga> _mangasInGroup(String groupName) =>
      allMangas.where((m) => m.groupName == groupName).toList();

  @override
  Widget buildItem(BuildContext context, int index, double cardWidth) {
    final groupName = groups[index];
    final mangas = _mangasInGroup(groupName);
    final previewMangas = mangas.take(4).toList();

    return GroupGridCard(
      groupName: groupName,
      previewMangas: previewMangas,
      totalCount: mangas.length,
      width: cardWidth,
      onTap: () => onEnter(groupName),
      onLongPress: groupName == Constants.defaultGroupName
          ? null
          : () => StyledActionSheet.show(
                context: context,
                actions: [
                  StyledAction(
                    label: '删除分组',
                    isDestructive: true,
                    onPressed: () =>
                        Get.dialog(deleteGroupDialogBuilder(groupName)),
                  ),
                ],
              ),
    );
  }
}
