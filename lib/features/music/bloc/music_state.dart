import 'package:jent_web/domain/entities/spotify_track.dart';
import 'package:jent_web/domain/repositories/spotify_repository.dart';

class MusicState {
  final bool isShowMusicPlayer;
  final bool isMusicMinimized;
  final bool isMusicExpanded;
  final bool isMusicPlaying;
  final int musicTrackIndex;
  final Duration musicPosition;
  final SpotifyStatus spotifyStatus;
  final String? spotifyErrorDetail;
  final List<SpotifyTrack> spotifyTracks;
  final List<SpotifyTrack> spotifySearchResults;
  final String spotifyQuery;
  final bool spotifySearching;

  const MusicState({
    this.isShowMusicPlayer = false,
    this.isMusicMinimized = false,
    this.isMusicExpanded = false,
    this.isMusicPlaying = false,
    this.musicTrackIndex = 0,
    this.musicPosition = Duration.zero,
    this.spotifyStatus = SpotifyStatus.disconnected,
    this.spotifyErrorDetail,
    this.spotifyTracks = const [],
    this.spotifySearchResults = const [],
    this.spotifyQuery = '',
    this.spotifySearching = false,
  });

  MusicState copyWith({
    bool? isShowMusicPlayer,
    bool? isMusicMinimized,
    bool? isMusicExpanded,
    bool? isMusicPlaying,
    int? musicTrackIndex,
    Duration? musicPosition,
    SpotifyStatus? spotifyStatus,
    String? spotifyErrorDetail,
    List<SpotifyTrack>? spotifyTracks,
    List<SpotifyTrack>? spotifySearchResults,
    String? spotifyQuery,
    bool? spotifySearching,
  }) {
    return MusicState(
      isShowMusicPlayer: isShowMusicPlayer ?? this.isShowMusicPlayer,
      isMusicMinimized: isMusicMinimized ?? this.isMusicMinimized,
      isMusicExpanded: isMusicExpanded ?? this.isMusicExpanded,
      isMusicPlaying: isMusicPlaying ?? this.isMusicPlaying,
      musicTrackIndex: musicTrackIndex ?? this.musicTrackIndex,
      musicPosition: musicPosition ?? this.musicPosition,
      spotifyStatus: spotifyStatus ?? this.spotifyStatus,
      spotifyErrorDetail: spotifyErrorDetail ?? this.spotifyErrorDetail,
      spotifyTracks: spotifyTracks ?? this.spotifyTracks,
      spotifySearchResults:
          spotifySearchResults ?? this.spotifySearchResults,
      spotifyQuery: spotifyQuery ?? this.spotifyQuery,
      spotifySearching: spotifySearching ?? this.spotifySearching,
    );
  }
}
