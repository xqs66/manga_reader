import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

extension WidgetExt on Widget {
  Widget fadeIn([Key? key]) => FadeIn(key: key, child: this);

  Widget fadeOut([Key? key]) => FadeOut(key: key, animate: true, child: this);

  Widget center() => Center(child: this);

  Widget alignLeft() => Align(alignment: .centerLeft, child: this);

  Widget alignRight() => Align(alignment: .centerRight, child: this);
}
