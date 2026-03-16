import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

extension WidgetExt on Widget {
  Widget fadeIn() => FadeIn(child: this);

  Widget fadeOut() => FadeOut(child: this);

  Widget center() => Center(child: this);

  Widget alignLeft() => Align(alignment: .centerLeft, child: this);

  Widget alignRight() => Align(alignment: .centerRight, child: this);
}
