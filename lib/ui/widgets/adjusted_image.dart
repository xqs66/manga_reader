import 'package:flutter/material.dart';

const _r = 0.3086;
const _g = 0.6094;
const _b = 0.0820;

ColorFilter _makeMatrix(double contrast, double saturation) {
  final c = contrast;
  final s = saturation;
  final t = (1.0 - c) / 2.0;

  // saturation lerp + contrast scale, combined into one 5×4 matrix
  return ColorFilter.matrix(<double>[
    c * (s + (1 - s) * _r), c * ((1 - s) * _g),    c * ((1 - s) * _b),    0, t,
    c * ((1 - s) * _r),    c * (s + (1 - s) * _g), c * ((1 - s) * _b),    0, t,
    c * ((1 - s) * _r),    c * ((1 - s) * _g),     c * (s + (1 - s) * _b), 0, t,
    0,                     0,                      0,                      1, 0,
  ]);
}

class AdjustedImage extends StatelessWidget {
  final Widget child;
  final double contrast;
  final double saturation;

  const AdjustedImage({
    super.key,
    required this.child,
    this.contrast = 1.0,
    this.saturation = 1.0,
  });

  bool get _isIdentity =>
      (contrast - 1.0).abs() < 0.005 && (saturation - 1.0).abs() < 0.005;

  @override
  Widget build(BuildContext context) {
    if (_isIdentity) return child;
    return ColorFiltered(
      colorFilter: _makeMatrix(contrast, saturation),
      child: child,
    );
  }
}
