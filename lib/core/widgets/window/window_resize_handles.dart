import 'package:flutter/material.dart';

/// Which window edges a resize handle drags.
class WindowResizeEdges {
  final bool left;
  final bool right;
  final bool top;
  final bool bottom;

  const WindowResizeEdges({
    this.left = false,
    this.right = false,
    this.top = false,
    this.bottom = false,
  });

  static const onLeft = WindowResizeEdges(left: true);
  static const onRight = WindowResizeEdges(right: true);
  static const onTop = WindowResizeEdges(top: true);
  static const onBottom = WindowResizeEdges(bottom: true);
  static const onTopLeft = WindowResizeEdges(left: true, top: true);
  static const onTopRight = WindowResizeEdges(right: true, top: true);
  static const onBottomLeft = WindowResizeEdges(left: true, bottom: true);
  static const onBottomRight = WindowResizeEdges(right: true, bottom: true);
}

/// Invisible macOS-style resize zone with the matching resize cursor.
/// Place above the window content so it wins hit tests against the
/// move-drag area.
class WindowResizeHandle extends StatelessWidget {
  final MouseCursor cursor;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? width;
  final double? height;
  final ValueChanged<Offset> onResize;
  final VoidCallback onResizeStart;
  final VoidCallback onResizeEnd;

  const WindowResizeHandle({
    super.key,
    required this.cursor,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.width,
    this.height,
    required this.onResize,
    required this.onResizeStart,
    required this.onResizeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: width,
      height: height,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => onResizeStart(),
          onPanUpdate: (details) => onResize(details.delta),
          onPanEnd: (_) => onResizeEnd(),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
