import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A [Stack] whose hit test iterates ALL children instead of short-circuiting
/// at the first match. This ensures multiple overlapping gesture detectors at
/// the same position all participate in the gesture arena.
///
/// Default Stack: top child that claims the hit → stops → siblings below are
/// never tested. With HitAccumulateStack, the loop continues so a transparent
/// tap layer *below* PhotoView can still register its TapGestureRecognizer,
/// while PhotoView *above* registers its drag/scale recognizers. Both
/// recognizers compete in the arena and the correct one wins per gesture type.
class HitAccumulateStack extends Stack {
  const HitAccumulateStack({
    super.key,
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
    super.children,
  });

  @override
  RenderStack createRenderObject(BuildContext context) {
    return _RenderHitAccumulateStack(
      alignment: alignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      fit: fit,
      clipBehavior: clipBehavior,
    );
  }
}

class _RenderHitAccumulateStack extends RenderStack {
  _RenderHitAccumulateStack({
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
  });

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    bool hit = false;
    RenderBox? child = lastChild;
    while (child != null) {
      final childParentData = child.parentData! as ContainerBoxParentData<RenderBox>;
      hit = hit |
          result.addWithPaintOffset(
            offset: childParentData.offset,
            position: position,
            hitTest: (BoxHitTestResult result, Offset transformed) {
              assert(transformed == position - childParentData.offset);
              return child!.hitTest(result, position: transformed);
            },
          );
      child = childParentData.previousSibling;
    }
    return hit;
  }
}
