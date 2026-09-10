import 'package:flutter/material.dart';
import 'package:jent_web/core/theme/app_dimens.dart';

class TrafficLightButton extends StatefulWidget {
  final Color color;
  final VoidCallback onTap;
  final IconData glyph;

  const TrafficLightButton({
    super.key,
    required this.color,
    required this.onTap,
    required this.glyph,
  });

  @override
  State<TrafficLightButton> createState() => _TrafficLightButtonState();
}

class _TrafficLightButtonState extends State<TrafficLightButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: AppDimens.trafficLightSize,
          height: AppDimens.trafficLightSize,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: _hovering
              ? Icon(
                  widget.glyph,
                  size: AppDimens.trafficLightGlyphSize,
                  color: Colors.black.withAlpha(140),
                )
              : null,
        ),
      ),
    );
  }
}
