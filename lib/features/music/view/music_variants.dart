import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jent_web/core/theme/app_colors.dart';
import 'package:jent_web/core/theme/app_dimens.dart';
import 'package:jent_web/domain/entities/music_track.dart';
import 'package:jent_web/domain/entities/spotify_track.dart';
import 'package:jent_web/domain/repositories/spotify_repository.dart';
import 'package:jent_web/l10n/app_localizations.dart';
import 'package:jent_web/features/music/bloc/music_bloc.dart';
import 'package:jent_web/features/music/bloc/music_event.dart';
import 'package:jent_web/features/music/bloc/music_state.dart';
import 'package:jent_web/features/music/view/music_artwork.dart';
import 'package:jent_web/features/music/view/music_controls.dart';
import 'package:jent_web/features/music/view/music_search.dart';

/// Collapsed single-row bar shown after minimize: artwork dot,
/// marquee-ish title, and play/pause + close.
class MusicMiniBar extends StatelessWidget {
  final ValueChanged<Offset> onDrag;

  const MusicMiniBar({super.key, required this.onDrag});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MusicBloc, MusicState, _MiniSnapshot>(
      selector: (state) {
        if (state.spotifyStatus == SpotifyStatus.ready &&
            state.spotifyTracks.isNotEmpty) {
          final track =
              state.spotifyTracks[state.musicTrackIndex.clamp(
                0,
                state.spotifyTracks.length - 1,
              )];
          return _MiniSnapshot(
            isPlaying: state.isMusicPlaying,
            title: track.title,
            artist: track.artist,
            artworkUrl: track.artworkUrl,
          );
        }
        final track = MusicPlaylist.tracks[state.musicTrackIndex];
        return _MiniSnapshot(
          isPlaying: state.isMusicPlaying,
          title: track.title,
          artist: track.artist,
          artworkUrl: '',
        );
      },
      builder: (context, snap) {
        final bloc = context.read<MusicBloc>();
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
                    child: MusicArtwork(
                      isPlaying: snap.isPlaying,
                      size: 34,
                      artworkUrl: snap.artworkUrl,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          snap.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          snap.artist,
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
  final String title;
  final String artist;
  final String artworkUrl;

  const _MiniSnapshot({
    required this.isPlaying,
    required this.title,
    required this.artist,
    required this.artworkUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MiniSnapshot &&
          isPlaying == other.isPlaying &&
          title == other.title &&
          artist == other.artist &&
          artworkUrl == other.artworkUrl;

  @override
  int get hashCode => Object.hash(isPlaying, title, artist, artworkUrl);
}

/// Expanded full-page view with the playlist below the player body.
/// Shows Spotify tracks + search when connected, otherwise the local
/// fallback playlist.
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

    return BlocSelector<MusicBloc, MusicState, _PlaylistSnapshot>(
      selector: (state) => _PlaylistSnapshot(
        spotifyReady:
            state.spotifyStatus == SpotifyStatus.ready &&
            state.spotifyTracks.isNotEmpty,
        spotifyTracks: state.spotifyTracks,
        trackIndex: state.musicTrackIndex,
        isPlaying: state.isMusicPlaying,
      ),
      builder: (context, snap) {
        final bloc = context.read<MusicBloc>();
        // No fixed width: the parent card already sizes to
        // musicExpandedWidth and applies its own padding — a fixed
        // width here overflowed the card by the padding amount.
        return Container(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                snap.spotifyReady
                    ? strings.musicYourPlaylist
                    : strings.musicOfflinePlaylist,
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
                child: snap.spotifyReady
                    ? ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: snap.spotifyTracks.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          color: Colors.white10,
                        ),
                        itemBuilder: (context, i) {
                          final track = snap.spotifyTracks[i];
                          final active = i == snap.trackIndex;
                          return _SpotifyTrackTile(
                            track: track,
                            active: active,
                            isPlaying: snap.isPlaying,
                            index: i,
                            onTap: () => bloc.add(SelectMusicTrack(i)),
                          );
                        },
                      )
                    : ListView.separated(
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
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
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
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w500,
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
                                fontFeatures: [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            onTap: () => bloc.add(SelectMusicTrack(i)),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 4),
              const MusicSearch(),
            ],
          ),
        );
      },
    );
  }
}

class _PlaylistSnapshot {
  final bool spotifyReady;
  final List<SpotifyTrack> spotifyTracks;
  final int trackIndex;
  final bool isPlaying;

  const _PlaylistSnapshot({
    required this.spotifyReady,
    required this.spotifyTracks,
    required this.trackIndex,
    required this.isPlaying,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PlaylistSnapshot &&
          spotifyReady == other.spotifyReady &&
          spotifyTracks == other.spotifyTracks &&
          trackIndex == other.trackIndex &&
          isPlaying == other.isPlaying;

  @override
  int get hashCode =>
      Object.hash(spotifyReady, spotifyTracks, trackIndex, isPlaying);
}

class _SpotifyTrackTile extends StatelessWidget {
  final SpotifyTrack track;
  final bool active;
  final bool isPlaying;
  final int index;
  final VoidCallback onTap;

  const _SpotifyTrackTile({
    required this.track,
    required this.active,
    required this.isPlaying,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      tileColor: active ? Colors.white.withAlpha(22) : Colors.transparent,
      leading: active
          ? MusicEqualizer(isPlaying: isPlaying)
          : ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: track.artworkUrl.isEmpty
                  ? const SizedBox(
                      width: 36,
                      height: 36,
                      child: MusicArtwork(isPlaying: false, size: 36),
                    )
                  : Image.network(
                      track.artworkUrl,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(
                        width: 36,
                        height: 36,
                        child: MusicArtwork(isPlaying: false, size: 36),
                      ),
                    ),
            ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        track.artist.isEmpty ? '—' : track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: Text(
        formatTrackTime(track.duration),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      onTap: onTap,
    );
  }
}
