import 'package:flutter/material.dart';
import 'package:jent_web/core/theme/app_colors.dart';
import 'package:jent_web/core/theme/app_dimens.dart';
import 'package:jent_web/gen/assets.gen.dart';

class MusicArtwork extends StatelessWidget {
  final bool isPlaying;
  final double? size;

  const MusicArtwork({super.key, required this.isPlaying, this.size});

  @override
  Widget build(BuildContext context) {
    final box = size ?? AppDimens.musicPlayerArtwork;
    return SizedBox(
      width: box,
      height: box,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          size == null ? AppDimens.musicPlayerRadius : 8,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Assets.icMusic.image(fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(110),
                  ],
                ),
              ),
            ),
            Center(
              child: _Vinyl(
                isPlaying: isPlaying,
                diameter: size == null
                    ? AppDimens.musicPlayerVinyl
                    : AppDimens.musicMiniVinyl,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Vinyl extends StatefulWidget {
  final bool isPlaying;
  final double diameter;

  const _Vinyl({required this.isPlaying, required this.diameter});

  @override
  State<_Vinyl> createState() => _VinylState();
}

class _VinylState extends State<_Vinyl> with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    if (!widget.isPlaying) _spin.stop();
  }

  @override
  void didUpdateWidget(covariant _Vinyl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying == oldWidget.isPlaying) return;
    if (widget.isPlaying) {
      _spin.repeat();
    } else {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _spin,
      child: Container(
        width: widget.diameter,
        height: widget.diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(90), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(120),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipOval(child: Assets.icVinyl.image(fit: BoxFit.cover)),
      ),
    );
  }
}

/// Spinning glyph shown while playback runs, used beside the track timer.
class MusicEqualizer extends StatefulWidget {
  final bool isPlaying;

  const MusicEqualizer({super.key, required this.isPlaying});

  @override
  State<MusicEqualizer> createState() => _MusicEqualizerState();
}

class _MusicEqualizerState extends State<MusicEqualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    if (!widget.isPlaying) _controller.stop();
  }

  @override
  void didUpdateWidget(covariant MusicEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying == oldWidget.isPlaying) return;
    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop(canceled: false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const heights = [10.0, 16.0, 7.0, 13.0];
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = widget.isPlaying ? _controller.value : 0.5;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < heights.length; i++)
              Container(
                width: 3,
                height: widget.isPlaying
                    ? heights[i] * (0.35 + 0.65 * ((t + i * 0.27) % 1.0))
                    : 4,
                margin: EdgeInsets.only(right: i == heights.length - 1 ? 0 : 3),
                decoration: BoxDecoration(
                  color: AppColors.musicPlayerAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        );
      },
    );
  }
}
