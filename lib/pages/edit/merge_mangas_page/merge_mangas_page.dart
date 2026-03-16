import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';
import 'package:manga_reader/models/manga.dart';
import 'package:manga_reader/service/local_manga_service.dart';
import 'package:manga_reader/shared/extensions/string_ext.dart';
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
  late final Future<List<Manga>> loadMangasFuture;

  @override
  void initState() {
    super.initState();
    loadMangasFuture = localMangaService.getMangasInDir(
      Directory(localMangaService.mangasInLocalSettingPaths.keys.first),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: BottomAppBar(
        height: UiConfig.bottomBarHeight,
        child: ElevatedButton(
          onPressed: () => '',
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
                      ? '已选 (${_state.selectedMangaPaths.length})'
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
                  ? _buildMangaList(_state.selectedDir!)
                  : Center(child: Text('请先选择需要合并的漫画所在目录')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMangaList(Directory dir) {
    return FutureBuilder(
      future: localMangaService.getMangasInDir(dir),
      builder: (context, snapshot) {
        if (snapshot.connectionState == .waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.connectionState == .done) {
          if (snapshot.data == null || snapshot.data?.isEmpty == true) {
            return Center(child: Text('未发现漫画'));
          }
          return ListView.builder(
            itemCount: snapshot.data?.length,
            itemBuilder: (context, index) {
              if (snapshot.data?[index] == null) {
                return const SizedBox();
              }
              return _buildMangaListTile(index, snapshot.data?[index] as Manga);
            },
          );
        } else {
          return Center(child: Text('Error'));
        }
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
      builder: (context) {
        return GestureDetector(
          onTap: () => _controller.toggleMangaSelection(index, manga),
          child: _state.selectedMangaPaths.contains(manga.path)
              ? _buildSelectedMangaListTile(manga)
              : MangaListTileCard(manga: manga),
        );
      },
    );
  }

  Widget _buildSelectedMangaListTile(Manga manga) {
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Stack(
          alignment: .center,
          children: [
            Icon(Icons.circle_outlined, color: Color(0xFF5C6BC0)),
            Text(
              '${_state.selectedMangaPaths.indexOf(manga.path) + 1}',
              style: TextStyle(color: Color(0xFF5C6BC0), fontSize: 12),
            ),
          ],
        ),
        SizedBox(width: 10),
        Flexible(child: MangaListTileCard(manga: manga)),
      ],
    ).paddingSymmetric(horizontal: 10);
  }
}
