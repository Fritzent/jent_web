import 'dart:math';
import 'package:flutter/material.dart';
import 'package:jent_web/core/theme/app_colors.dart';

class WaterFillLogo extends StatefulWidget {
  final double progress;
  final Widget logo;
  final Color waterColor;
  final Color backgroundColor;
  final double size;

  const WaterFillLogo({
    super.key,
    required this.progress,
    required this.logo,
    required this.waterColor,
    required this.backgroundColor,
    this.size = 320,
  });

  @override
  State<WaterFillLogo> createState() => _WaterFillLogoState();
}

class _WaterFillLogoState extends State<WaterFillLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  widget.backgroundColor,
                  BlendMode.srcIn,
                ),
                child: widget.logo,
              ),
              Stack(
                children: [
                  _buildWaveLayer(
                    color: AppColors.foamWaterColor.withAlpha(64),
                    phase: _controller.value * 5 * pi,
                    amplitude: 8,
                  ),
                  _buildWaveLayer(
                    color: AppColors.lightWaterColor.withAlpha(128),
                    phase: _controller.value * 4 * pi,
                    amplitude: 6,
                  ),
                  _buildWaveLayer(
                    color: AppColors.midWaterColor.withAlpha(200),
                    phase: _controller.value * 3 * pi,
                    amplitude: 4,
                  ),
                  _buildWaveLayer(
                    color: AppColors.deepWaterColor,
                    phase: _controller.value * 2 * pi,
                    amplitude: 2,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWaveLayer({
    required Color color,
    required double phase,
    required double amplitude,
  }) {
    return ClipPath(
      clipper: _WaveClipper(
        progress: widget.progress,
        wavePhase: phase,
        amplitude: amplitude,
      ),
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          color,
          BlendMode.srcIn,
        ),
        child: widget.logo,
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  final double progress;
  final double wavePhase;
  final double amplitude;

  _WaveClipper({
    required this.progress,
    required this.wavePhase,
    required this.amplitude,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    final fillHeight = size.height * (1 - progress);

    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final normalizedX = x / size.width;

      final primaryWave =
          sin((normalizedX * 2 * pi) + wavePhase) * amplitude;

      final secondaryWave =
          sin((normalizedX * 5 * pi) + wavePhase * 1.8) * 4;

      final splashWave =
          sin((normalizedX * 12 * pi) + wavePhase * 2.5) * 2;

      final spread =
          sin(wavePhase + normalizedX * pi) * 5;

      final y = fillHeight +
          primaryWave +
          secondaryWave +
          splashWave +
          spread;

      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) => true;
}