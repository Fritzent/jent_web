import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:jent_web/source/widget/dock/dock_icon_widget.dart';

class DockWidget extends StatefulWidget {
  final List<Widget> icons;
  final List<String> tooltips;
  final Function(int) onIconTapped;
  final List<bool> listDockMinimized;

  const DockWidget({
    super.key,
    required this.icons,
    required this.tooltips,
    required this.onIconTapped,
    required this.listDockMinimized,
  });

  @override
  State<DockWidget> createState() => _DockWidgetState();
}

class _DockWidgetState extends State<DockWidget> {
  int? hoveredIndex;

  late final List<GlobalKey> _iconKeys;

  @override
  void initState() {
    super.initState();
    _iconKeys = List.generate(
      widget.icons.length,
      (_) => GlobalKey(),
    );
  }

  double _scaleFor(int index) {
    if (hoveredIndex == null) return 1.0;

    final distance = (index - hoveredIndex!).abs();

    switch (distance) {
      case 0:
        return 1.1;
      default:
        return 1.0;
    }
  }

  double _spacingFor(int index) {
    final scale = _scaleFor(index);

    return 6 + ((scale - 1) * 22);
  }

  double _tooltipX(BuildContext context) {
    if (hoveredIndex == null) return 0;

    final keyContext = _iconKeys[hoveredIndex!].currentContext;

    if (keyContext == null) return 0;

    final box = keyContext.findRenderObject() as RenderBox;
    final stackBox = context.findRenderObject() as RenderBox;

    final iconPosition =
        box.localToGlobal(Offset.zero, ancestor: stackBox);

    return iconPosition.distance + (box.size.width / 2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      alignment: Alignment.bottomCenter,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 18,
                  sigmaY: 18,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withAlpha(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(70),
                        blurRadius: 25,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(widget.icons.length, (index) {
                      return MouseRegion(
                        onEnter: (_) => setState(() => hoveredIndex = index),
                        onExit: (_) => setState(() => hoveredIndex = null),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.symmetric(
                            horizontal: _spacingFor(index),
                          ),
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            scale: _scaleFor(index),
                            alignment: Alignment.bottomCenter,
                            child: AnimatedSlide(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              offset: Offset(
                                0,
                                -(_scaleFor(index) - 1) * 0.05,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  if (index == 0) {
                                    widget.onIconTapped(index);
                                  } else if (index == 1) {
                                    widget.onIconTapped(index);
                                  } else if (index == 2) {
                                    widget.onIconTapped(index);
                                  }
                                },
                                child: Container(
                                  key: _iconKeys[index],
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      DockIconWidget(
                                        icon: widget.icons[index],
                                      ),
                                      if (widget.listDockMinimized[index]) ... [
                                        const SizedBox(height: 4),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Colors.grey,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              )
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        
          if (hoveredIndex != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              top: 0,
              bottom: widget.listDockMinimized.firstWhere((element) => element == true, orElse: () => false) ? 100 : 80,
              left: _tooltipX(context) - 40,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(0, 0.015),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  key: ValueKey(hoveredIndex),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(210),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    widget.tooltips[hoveredIndex!],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ]
      ),
    );
  }
}