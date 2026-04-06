import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/shared/extensions/string_ext.dart';
import 'package:manga_reader/shared/utils/file_util.dart';
import 'package:manga_reader/wigets/common_dialog.dart';
import 'package:manga_reader/wigets/manga_list_tile_card.dart';

import 'merge_mangas_page_controller.dart';

class MergeMangasPage extends StatefulWidget {
  const MergeMangasPage({super.key});

  @override
  State<StatefulWidget> createState() => _MergeMangasPageState();
}

class _MergeMangasPageState extends State<MergeMangasPage> {
  final _controller = Get.put(MergeMangasPageController());
  final _state = Get.find<MergeMangasPageController>().state;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: BottomAppBar(
        height: UiConfig.bottomHeightInMergePasge,
        child: ElevatedButton(
          onPressed: () =>
              Get.dialog(_buildNameTargetDialog(), barrierDismissible: false),
          child: Text('合并选中的漫画为合集'),
        ).paddingSymmetric(horizontal: 50),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: GetBuilder<MergeMangasPageController>(
        id: _controller.titleId,
        builder: (context) {
          return Text(
            _state.isDirSelected
                ? _state.hasSelectedManga
                      ? '已选 (${_state.selectedMangas.length})'
                      : '请选择要合并的漫画'
                : '将漫画合并为合集',
          );
        },
      ),
      centerTitle: true,
      actions: [
        GetBuilder<MergeMangasPageController>(
          id: _controller.cancelButtonId,
          builder: (context) {
            return _state.hasSelectedManga
                ? TextButton(
                    onPressed: _controller.cancelSelected,
                    child: Text('取消'),
                  )
                : const SizedBox();
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return GetBuilder<MergeMangasPageController>(
      id: _controller.bodyId,
      builder: (context) {
        return Column(
          children: [
            _buildSelectPathsArea(),
            Expanded(
              child: _state.isDirSelected
                  ? _buildMangaListArea(_state.selectedDir!)
                  : Center(child: Text('请先选择需要合并的漫画所在目录')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMangaListArea(Directory dir) {
    return FutureBuilder(
      future: localMangaService.getMangasInDir(dir),  //这里是引用传递拿的mangasInLocalSettingPaths[state.selectedDir?.path]
      builder: (context, snapshot) {
        if (snapshot.connectionState == .waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.connectionState == .done) {
          _state.mangas = snapshot.data ?? [];
          if (snapshot.data == null || snapshot.data?.isEmpty == true) {
            return Center(child: Text('未发现漫画'));
          }
          return CupertinoScrollbar(
            controller: _state.scrollController,
            child: NotificationListener(
              onNotification: (ScrollNotification notification) =>
                  _controller.handleScrollEvent(notification),
              child: _buildMangaList(),
            ),
          );
        } else {
          return Center(child: Text('Error'));
        }
      },
    );
  }

  Widget _buildMangaList() {
    return GetBuilder<MergeMangasPageController>(
      id: _controller.mangasId,
      builder: (_) {
        return ListView.builder(
          controller: _state.scrollController,
          itemCount: _state.mangas.length,
          itemBuilder: (context, index) =>
              _buildMangaListTile(index, _state.mangas[index]),
        );
      },
    );
  }

  Widget _buildSelectPathsArea() {
    return Column(
      mainAxisSize: .min,
      children: [
        GetBuilder<MergeMangasPageController>(
          id: _controller.selectDirId,
          builder: (context) {
            return _buildSelectDirLine(
              leadingText: '已选目录',
              path: _state.selectedDir?.path,
              buttonText: '选择目录',
              isSelected: _state.isDirSelected,
              onButtonTap: () => _controller.selectDir(),
            );
          },
        ),
        SizedBox(height: 10),
        GetBuilder<MergeMangasPageController>(
          id: _controller.selectOutputDirId,
          builder: (context) {
            return _buildSelectDirLine(
              leadingText: '输出目录',
              path: _state.outputDir?.path,
              buttonText: '选择输出目录',
              isSelected: _state.isOutputDirSelected,
              onButtonTap: () => _controller.selectOutputDir(),
            );
          },
        ),
      ],
    ).paddingAll(10);
  }

  Widget _buildSelectDirLine({
    required String leadingText,
    String? path,
    required String buttonText,
    required bool isSelected,
    required Function() onButtonTap,
  }) {
    return isSelected
        ? Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '$leadingText: ${path!.displayPath()}',
                  maxLines: 2,
                  overflow: .ellipsis,
                ),
              ),
              SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed: () => onButtonTap(),
                  child: Text('重新选择'),
                ),
              ),
            ],
          )
        : SizedBox(
            height: 30,
            child: ElevatedButton(
              onPressed: () => onButtonTap(),
              child: Text(buttonText),
            ),
          );
  }

  Widget _buildMangaListTile(int index, Manga manga) {
    return GetBuilder<MergeMangasPageController>(
      id: '${_controller.mangaListTileIdPrefix}::$index',
      builder: (_) {
        final mangaListTileCard = MangaListTileCard(
          manga: manga,
          buildCover: !_state.isScrolling,
          onTap: () => _controller.toggleMangaSelection(index, manga),
          onLongPressed: () => _controller.handleLongPressManga(
            context,
            _buildLongPressActions(manga),
          ),
        );
        return _state.selectedMangas.contains(manga)
            ? _buildSelectedMangaListTile(manga, mangaListTileCard)
            : mangaListTileCard;
      },
    );
  }

  List<SheetAction> _buildLongPressActions(Manga manga) {
    return [
      SheetAction(
        label: '复制漫画名',
        onPressed: () => FileUtil.copyMangaName(manga.title),
      ),
    ];
  }

  Widget _buildSelectedMangaListTile(Manga manga, MangaListTileCard card) {
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Stack(
          alignment: .center,
          children: [
            Icon(Icons.circle_outlined, color: Color(0xFF5C6BC0)),
            Text(
              '${_state.selectedMangas.indexOf(manga) + 1}',
              style: TextStyle(color: Color(0xFF5C6BC0), fontSize: 12),
            ),
          ],
        ),
        SizedBox(width: 10),
        Flexible(child: card),
      ],
    ).paddingSymmetric(horizontal: 10);
  }

  Widget _buildNameTargetDialog() {
    return GetBuilder<MergeMangasPageController>(
      id: _controller.mergeStartDialogId,
      builder: (context) {
        return CommonDialog(
          title: '请输入合集名称',
          content: SizedBox(
            height: 110,
            child: Column(
              crossAxisAlignment: .end,
              mainAxisSize: .max,
              mainAxisAlignment: .spaceBetween,
              children: [
                TextField(
                  controller: _state.targetDirNameController,
                  decoration: InputDecoration(hintText: '请输入合集名称'),
                ),
                CheckboxListTile(
                  value: _state.deleteSourceMangas,
                  onChanged: _controller.handleToggleDeleteSource,
                  title: Text('合并后删除原漫画'),
                  contentPadding: .zero,
                  horizontalTitleGap: 0,
                ),
              ],
            ),
          ),
          onConfirm: _controller.handleTapStartMerge,
        );
      },
    );
  }
}
