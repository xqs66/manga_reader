import 'package:flutter/material.dart';

extension TextExt on Text {
  Text copyWith({double? fontSize, Color? color, FontWeight? fontWeight}) {
    return Text(
      data ?? '',
      style: (style ?? const TextStyle()).copyWith(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
      ),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      strutStyle: strutStyle,
      textScaler: textScaler,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
    );
  }

  Text size(double? size) => copyWith(fontSize: size);

  Text color(Color? color) => copyWith(color: color);

  Text get bold => copyWith(fontWeight: FontWeight.bold);

  Text get light => copyWith(fontWeight: FontWeight.w300);
}
