import 'package:flutter/material.dart';

class DockIconWidget extends StatelessWidget {
  final Widget icon;

  const DockIconWidget({super.key, 
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            Colors.white.withAlpha(0x38),
            Colors.white.withAlpha(0x14),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: icon,
    );
  }
}