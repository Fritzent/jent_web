import 'package:flutter/material.dart';
import 'package:jent_web/core/theme/app_dimens.dart';
import 'package:jent_web/core/widgets/window/traffic_light_button.dart';
import 'package:jent_web/core/widgets/window/window_drag_area.dart';

class WindowTitleBar extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final VoidCallback onExpand;
  final ValueChanged<Offset> onPanUpdate;

  const WindowTitleBar({
    super.key,
    required this.onClose,
    required this.onMinimize,
    required this.onExpand,
    required this.onPanUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimens.titleBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          TrafficLightButton(
            color: const Color(0xFFFF5F57),
            onTap: onClose,
            glyph: Icons.close_rounded,
          ),
          const SizedBox(width: 8),
          TrafficLightButton(
            color: const Color(0xFFFEBC2E),
            onTap: onMinimize,
            glyph: Icons.remove_circle,
          ),
          const SizedBox(width: 8),
          TrafficLightButton(
            color: const Color(0xFF28C840),
            onTap: onExpand,
            glyph: Icons.expand_circle_down,
          ),
          Expanded(
            child: WindowDragArea(
              onPanUpdate: (details) => onPanUpdate(details.delta),
            ),
          ),
        ],
      ),
    );
  }
}
