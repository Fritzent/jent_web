import 'package:flutter/material.dart';
import 'package:jent_web/core/theme/app_dimens.dart';
import 'package:jent_web/core/widgets/window/traffic_light_button.dart';
import 'package:jent_web/core/widgets/window/window_drag_area.dart';

/// Dark traffic-light strip for the floating music player, matching
/// macOS window chrome. Close hides the player, minimize collapses it
/// to the mini bar, expand opens the full-page playlist view.
class MusicWindowChrome extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final VoidCallback onExpand;
  final ValueChanged<Offset> onPanUpdate;
  final bool isExpanded;

  const MusicWindowChrome({
    super.key,
    required this.onClose,
    required this.onMinimize,
    required this.onExpand,
    required this.onPanUpdate,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimens.musicChromeHeight,
      child: Row(
        children: [
          TrafficLightButton(
            color: const Color(0xFFFF5F57),
            onTap: onClose,
            glyph: Icons.close_rounded,
          ),
          const SizedBox(width: 7),
          TrafficLightButton(
            color: const Color(0xFFFEBC2E),
            onTap: onMinimize,
            glyph: Icons.remove_rounded,
          ),
          const SizedBox(width: 7),
          TrafficLightButton(
            color: const Color(0xFF28C840),
            onTap: onExpand,
            glyph: isExpanded
                ? Icons.fullscreen_exit_rounded
                : Icons.open_in_full_rounded,
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
