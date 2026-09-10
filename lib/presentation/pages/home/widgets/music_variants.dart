import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jent_web/core/theme/app_colors.dart';
import 'package:jent_web/core/theme/app_dimens.dart';
import 'package:jent_web/domain/entities/music_track.dart';
import 'package:jent_web/l10n/app_localizations.dart';
import 'package:jent_web/presentation/pages/home/home_bloc.dart';
import 'package:jent_web/presentation/pages/home/home_event.dart';
import 'package:jent_web/presentation/pages/home/home_state.dart';
import 'package:jent_web/presentation/pages/home/widgets/music_artwork.dart';
import 'package:jent_web/presentation/pages/home/widgets/music_controls.dart';

/// Collapsed single-row bar shown after minimize: artwork dot,
/// marquee-ish title, and play/pause + close.
class MusicMiniBar extends StatelessWidget {
  final ValueChanged<Offset> onDrag;

  const MusicMiniBar({super.key, required this.onDrag});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeBloc, HomeState, _MiniSnapshot>(
      selector: (state) => _MiniSnapshot(
        isPlaying: state.isMusicPlaying,
        track: MusicPlaylist.tracks[state.musicTrackIndex],
      ),
      builder: (context, snap) {
        final bloc = context.read<HomeBloc>();
        return Material(
          elevation: 18,
          borderRadius: BorderRadius.circular(AppDimens.musicPlayerRadius),
          clipBehavior: Clip.antiAlias,
          color: AppColors.musicPlayerBackground,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) => onDrag(details.delta),
            child: Container(
              width: AppDimens.musicPlayerWidth,
              height: AppDimens.musicMiniHeight,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  AppDimens.musicPlayerRadius,
                ),
                border: Border.all(color: Colors.white.withAlpha(22)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: MusicArtwork(isPlaying: snap.isPlaying, size: 34),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          snap.track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          snap.track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  MusicEqualizer(isPlaying: snap.isPlaying),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => bloc.add(ToggleMusicPlayback()),
                    iconSize: 22,
                    color: Colors.white,
                    icon: Icon(
                      snap.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  ),
                  IconButton(
                    onPressed: () => bloc.add(ToggleMusicPlayer()),
                    iconSize: 20,
                    color: Colors.white70,
                    icon: const Icon(Icons.open_in_full_rounded),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniSnapshot {
  final bool isPlaying;
  final MusicTrack track;

  const _MiniSnapshot({required this.isPlaying, required this.track});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MiniSnapshot &&
          isPlaying == other.isPlaying &&
          track == other.track;

  @override
  int get hashCode => Object.hash(isPlaying, track);
}

/// Expanded full-page view with the playlist below the player body.
class MusicExpandedView extends StatelessWidget {
  final bool isPlaying;
  final int trackIndex;
  final Duration position;

  const MusicExpandedView({
    super.key,
    required this.isPlaying,
    required this.trackIndex,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final bloc = context.read<HomeBloc>();

    return Container(
      width: AppDimens.musicExpandedWidth,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.musicYourPlaylist,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.musicPlayerAccent.withAlpha(220),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: AppDimens.musicExpandedPlaylistHeight,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: MusicPlaylist.tracks.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                color: Colors.white10,
              ),
              itemBuilder: (context, i) {
                final track = MusicPlaylist.tracks[i];
                final active = i == trackIndex;
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tileColor: active
                      ? Colors.white.withAlpha(22)
                      : Colors.transparent,
                  leading: active
                      ? MusicEqualizer(isPlaying: isPlaying)
                      : Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                          ),
                        ),
                  title: Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Text(
                    formatTrackTime(track.duration),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  onTap: () => bloc.add(SelectMusicTrack(i)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
