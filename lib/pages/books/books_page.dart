import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:manga_reader/models/read_info.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/shared/extensions/string_ext.dart';
import 'package:manga_reader/wigets/group_header.dart';
import 'package:manga_reader/wigets/manga_list_tile_card.dart';
import 'package:simple_animations/animation_mixin/animation_mixin.dart';
import 'package:get/get.dart';
import 'package:manga_reader/pages/books/books_page_controller.dart';

import '../../config/ui_config.dart';
import '../../models/manga.dart';
import '../../routes/routes.dart';
import '../../settings/path_setting.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage>
    with
        AutomaticKeepAliveClientMixin,
        AnimationMixin,
        SingleTickerProviderStateMixin {
  final _controller = Get.put(BooksPageController(), permanent: true);
  final _state = Get.find<BooksPageController>().state;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(appBar: _buildAppbar(), body: _buildBody());
  }

  AppBar _buildAppbar() {
    return AppBar(
      title: Text('Books'),
      centerTitle: true,
      actions: [
        GetBuilder<BooksPageController>(
          id: _controller.popUpMenuId,
          builder: (_) {
            return PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: _controller.back2Root,
                  height: UiConfig.popUpMenuHeight,
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back),
                      SizedBox(width: 10),
                      Text('返回根目录'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: () => _controller.refreshMangas(),
                  height: UiConfig.popUpMenuHeight,
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 10),
                      Text('刷新'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: () => '',
                  height: UiConfig.popUpMenuHeight,
                  child: Row(
                    children: [
                      Icon(Icons.search),
                      SizedBox(width: 10),
                      Text('搜索'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return GetBuilder<BooksPageController>(
      id: _controller.bodyId,
      builder: (_) {
        if (_state.isAtRoot) {
          return _buildLocalPaths();
        } else {
          return _buildGroupedBooksList();
        }
      },
    );
  }

  Widget _buildLocalPaths() {
    return ListView.builder(
      itemCount: pathSetting.paths.length,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            minTileHeight: 30,
            title: Text(
              pathSetting.paths[index].displayPath(),
              overflow: .ellipsis,
              maxLines: 2,
            ),
            onTap: () {
              _controller.enterMangaDir(pathSetting.paths[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildGroupedBooksList() {
    /// TODO: 可配置项，不过设置稍微多点会卡顿
    return CustomScrollView(
      slivers: _buildSlivers(),
      cacheExtent: Get.height * 0.5,
    );
  }

  List<Widget> _buildSlivers() {
    List<Widget> slivers = [];

    for (int i = 0; i < 1; i++) {
      slivers.add(_buildGroupSliver(i));
      slivers.add(_buildElementSliver(i, _state.books));
    }

    return slivers;
  }

  Widget _buildElementSliver(int groupIndex, List<Manga> books) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildElement(context, groupIndex, books[index]),
        childCount: books.length,
        addAutomaticKeepAlives: true,
      ),
    );
  }

  Widget _buildGroupSliver(int index) {
    return SliverToBoxAdapter(child: _buildGroup(index));
  }

  Widget _buildGroup(int index) {
    return GetBuilder<BooksPageController>(
      id: 'Group::$index',
      builder: (_) {
        final isDisplay = _state.displayGroups.contains(index);
        return GestureDetector(
          onTap: () {
            _controller.toggleOpen(index);
          },
          child: GroupHeader(
            child: Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Text('Group $index'),
                isDisplay
                    ? Icon(Icons.keyboard_arrow_up)
                    : Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildElement(BuildContext context, int groupIndex, Manga manga) {
    return GetBuilder<BooksPageController>(
      id: 'Group::$groupIndex',
      builder: (_) {
        final isDisplay = _state.displayGroups.contains(groupIndex);
        if (!isDisplay) return const SizedBox();
        return GestureDetector(
          onLongPress: () => showCupertinoModalPopup(context: context, builder: (context) {
            return CupertinoActionSheet(
              actions: [
                CupertinoActionSheetAction(
                  onPressed: () {
                    Get.back();
                  },
                  child: Text('取消'),
                ),
              ],
            );
          }),
          onTap: () {
            Get.toNamed(
              Routes.reader,
              arguments: ReadInfo(
                title: manga.title,
                images: localMangaService.getMangaImages(manga),
                pageCount: manga.pageCount,
              ),
            );
          },
          child: MangaListTileCard(
            manga: manga,
          ).paddingSymmetric(horizontal: 10),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
