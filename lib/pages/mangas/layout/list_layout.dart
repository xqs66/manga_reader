import 'package:flutter/material.dart';

/// Abstract list layout for manga and group folder list views.
///
/// Subclasses provide [itemCount] and [buildItem]; the base class handles
/// [ListView.builder] scrolling.
abstract class ListLayout extends StatelessWidget {
  final ScrollController? scrollController;

  const ListLayout({super.key, this.scrollController});

  int get itemCount;

  Widget buildItem(BuildContext context, int index);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) => buildItem(context, index),
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
    );
  }
}
