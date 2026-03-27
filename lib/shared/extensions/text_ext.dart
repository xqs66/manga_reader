import 'package:flutter/material.dart';

extension TextExt on Text {
  Text size(double size) => Text(
    data ?? '',
    style: ((style ?? TextStyle()).copyWith(fontSize: size)),
  );

  Text color(Color? color) =>
      Text(data ?? '', style: ((style ?? TextStyle()).copyWith(color: color)));

  Text get bold => Text(
    data ?? '',
    style: ((style ?? TextStyle()).copyWith(fontWeight: FontWeight.bold)),
  );

  Text get light => Text(
    data ?? '',
    style: ((style ?? TextStyle()).copyWith(fontWeight: .w300)),
  );
}
