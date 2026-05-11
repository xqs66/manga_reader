import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/config/ui_config.dart';

/// Abstract grid layout shared by both manga and group folder grids.
///
/// Subclasses provide [itemCount] and [buildItem]; the base class handles
/// column calculation, row construction, and [ListView.builder] scrolling.
abstract class GridLayout extends StatelessWidget {
  const GridLayout({super.key});

  int get itemCount;

  int columnsForWidth(double availableWidth) {
    return ((availableWidth + UiConfig.gridCardSpacing) /
            (UiConfig.gridCardTargetWidth + UiConfig.gridCardSpacing))
        .floor()
        .clamp(2, 5);
  }

  double cardWidth(double availableWidth) {
    final columns = columnsForWidth(availableWidth);
    return (availableWidth - UiConfig.gridCardSpacing * (columns - 1)) /
        columns;
  }

  static double coverHeight(double width) =>
      width * UiConfig.gridCardAspectRatio;

  Widget buildItem(BuildContext context, int index, double cardWidth);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConfig.gridCardPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final columns = columnsForWidth(availableWidth);
          final cardW = cardWidth(availableWidth);
          final rowCount = (itemCount / columns).ceil();

          return ListView.builder(
            padding: .only(top: UiConfig.gridCardPadding),
            itemCount: rowCount,
            cacheExtent: Get.height * 0.4,
            itemBuilder: (_, rowIndex) {
              final start = rowIndex * columns;
              final rowChildren = <Widget>[];
              for (var j = 0; j < columns && start + j < itemCount; j++) {
                if (j > 0) rowChildren.add(SizedBox(width: UiConfig.gridCardSpacing));
                rowChildren.add(
                  SizedBox(
                    width: cardW,
                    child: buildItem(context, start + j, cardW),
                  ),
                );
              }
              return Padding(
                padding: EdgeInsets.only(
                  bottom: rowIndex < rowCount - 1
                      ? UiConfig.gridCardSpacing
                      : 0,
                ),
                child: Row(children: rowChildren),
              );
            },
          );
        },
      ),
    );
  }
}
