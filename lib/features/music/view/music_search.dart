import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jent_web/core/theme/app_colors.dart';
import 'package:jent_web/domain/entities/spotify_track.dart';
import 'package:jent_web/domain/repositories/spotify_repository.dart';
import 'package:jent_web/l10n/app_localizations.dart';
import 'package:jent_web/features/music/bloc/music_bloc.dart';
import 'package:jent_web/features/music/bloc/music_event.dart';
import 'package:jent_web/features/music/bloc/music_state.dart';
import 'package:jent_web/features/music/view/music_artwork.dart';
import 'package:jent_web/features/music/view/music_controls.dart';

class _SearchSnapshot {
  final SpotifyStatus status;
  final String query;
  final bool searching;
  final List<SpotifyTrack> results;

  const _SearchSnapshot({
    required this.status,
    required this.query,
    required this.searching,
    required this.results,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SearchSnapshot &&
          status == other.status &&
          query == other.query &&
          searching == other.searching &&
          results == other.results;

  @override
  int get hashCode => Object.hash(status, query, searching, results);
}

/// Search field + results for the expanded view. Hidden entirely
/// when Spotify is not connected (fallback playlist has no search).
class MusicSearch extends StatefulWidget {
  const MusicSearch({super.key});

  @override
  State<MusicSearch> createState() => _MusicSearchState();
}

class _MusicSearchState extends State<MusicSearch> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () {
        if (!mounted) return;
        context.read<MusicBloc>().add(SpotifySearchRequested(value));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;

    return BlocSelector<MusicBloc, MusicState, _SearchSnapshot>(
      selector: (state) => _SearchSnapshot(
        status: state.spotifyStatus,
        query: state.spotifyQuery,
        searching: state.spotifySearching,
        results: state.spotifySearchResults,
      ),
      builder: (context, snap) {
        if (snap.status != SpotifyStatus.ready) {
          return const SizedBox.shrink();
        }
        final bloc = context.read<MusicBloc>();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1, color: Colors.white10),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withAlpha(24)),
              ),
              child: TextField(
                controller: _controller,
                onChanged: _onChanged,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: strings.musicSearchHint,
                  hintStyle: const TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.white54,
                    size: 20,
                  ),
                  suffixIcon: snap.searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : snap.query.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _controller.clear();
                                bloc.add(SpotifySearchRequested(''));
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white54,
                                size: 18,
                              ),
                            )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  isDense: true,
                ),
              ),
            ),
            if (snap.query.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              if (!snap.searching && snap.results.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Text(
                    strings.musicNoResults,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                  ),
                )
              else
                ...snap.results.map(
                  (track) => _SearchResultTile(track: track),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final SpotifyTrack track;

  const _SearchResultTile({required this.track});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MusicBloc>();
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      leading: ClipRRect(
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
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        track.artist,
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
      onTap: () => bloc.add(SpotifyPlayTrack(track.id)),
    );
  }
}

/// Small status line under the player when Spotify is not ready.
/// On error the line is tappable: opens the full detail with a
/// copy button and a retry action.
class SpotifyStatusLine extends StatelessWidget {
  const SpotifyStatusLine({super.key});

  void _showDetail(
    BuildContext context,
    AppLocalizations strings,
    String detail,
  ) {
    // Capture the bloc before opening the dialog: the dialog route is
    // not under this page's providers, so reading it inside the
    // dialog's builder would throw ProviderNotFoundException.
    final bloc = context.read<MusicBloc>();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.musicPlayerPanel,
        title: Text(
          strings.musicErrorTitle,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: SelectableText(
          detail,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.dialogClose),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              bloc.add(SpotifyConnectRequested());
            },
            child: Text(strings.musicRetry),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return BlocSelector<MusicBloc, MusicState, (SpotifyStatus, String?)>(
      selector: (state) =>
          (state.spotifyStatus, state.spotifyErrorDetail),
      builder: (context, record) {
        final status = record.$1;
        final detail = record.$2;
        if (status == SpotifyStatus.ready) {
          return const SizedBox.shrink();
        }
        final label = switch (status) {
          SpotifyStatus.connecting => strings.musicConnecting,
          SpotifyStatus.error =>
            detail == null || detail.isEmpty
                ? strings.musicConnectError
                : '${strings.musicConnectError}: $detail',
          SpotifyStatus.disconnected => strings.musicOfflineMode,
          SpotifyStatus.ready => '',
        };
        final tappable =
            status == SpotifyStatus.error &&
            detail != null &&
            detail.isNotEmpty;
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: InkWell(
            onTap: tappable
                ? () => _showDetail(context, strings, detail)
                : null,
            borderRadius: BorderRadius.circular(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: status == SpotifyStatus.error
                        ? Colors.redAccent
                        : AppColors.musicPlayerAccent.withAlpha(160),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    tappable ? '$label (${strings.musicTapDetails})' : label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      decoration: tappable ? TextDecoration.underline : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
