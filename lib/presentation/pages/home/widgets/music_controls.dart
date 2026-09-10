import 'package:flutter/material.dart';
import 'package:jent_web/core/theme/app_colors.dart';
import 'package:jent_web/domain/entities/music_track.dart';
import 'package:jent_web/presentation/pages/home/widgets/music_artwork.dart';

String formatTrackTime(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(1, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class MusicProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;

  const MusicProgressBar({
    super.key,
    required this.position,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final total = duration.inMilliseconds;
    final value = total == 0
        ? 0.0
        : position.inMilliseconds.clamp(0, total) / total;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 18,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (context, animated, _) {
                return LinearProgressIndicator(
                  value: animated,
                  backgroundColor: Colors.white.withAlpha(28),
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.musicPlayerAccent,
                  ),
                  minHeight: 7,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MusicEqualizer(isPlaying: value > 0 && value < 1),
                const SizedBox(width: 6),
                Text(
                  formatTrackTime(position),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            Text(
              formatTrackTime(duration),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class MusicTransportControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPrevious;
  final VoidCallback onToggle;
  final VoidCallback onNext;

  const MusicTransportControls({
    super.key,
    required this.isPlaying,
    required this.onPrevious,
    required this.onToggle,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlButton(
          icon: Icons.skip_previous_rounded,
          onTap: onPrevious,
          size: 34,
        ),
        const SizedBox(width: 6),
        _ControlButton(
          icon: isPlaying
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          onTap: onToggle,
          size: 46,
          filled: true,
        ),
        const SizedBox(width: 6),
        _ControlButton(
          icon: Icons.skip_next_rounded,
          onTap: onNext,
          size: 34,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool filled;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    required this.size,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? Colors.white.withAlpha(26)
                : Colors.transparent,
          ),
          child: Icon(icon, color: Colors.white, size: size * 0.55),
        ),
      ),
    );
  }
}

class MusicTrackHeader extends StatelessWidget {
  final MusicTrack track;
  final String statusLabel;

  const MusicTrackHeader({
    super.key,
    required this.track,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          statusLabel.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w600,
            color: AppColors.musicPlayerAccent.withAlpha(220),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          track.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: Colors.white60),
        ),
      ],
    );
  }
}
