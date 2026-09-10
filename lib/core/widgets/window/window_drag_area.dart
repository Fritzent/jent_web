import 'package:flutter/material.dart';

class WindowDragArea extends StatefulWidget {
  final GestureDragUpdateCallback onPanUpdate;

  const WindowDragArea({super.key, required this.onPanUpdate});

  @override
  State<WindowDragArea> createState() => _WindowDragAreaState();
}

class _WindowDragAreaState extends State<WindowDragArea> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:
          _dragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => setState(() => _dragging = true),
        onPanUpdate: widget.onPanUpdate,
        onPanEnd: (_) => setState(() => _dragging = false),
        onPanCancel: () => setState(() => _dragging = false),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
