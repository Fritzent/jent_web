import 'package:jent_web/domain/entities/spotify_track.dart';

enum SpotifyStatus { disconnected, connecting, ready, error }

class SpotifyPlayerState {
  final bool isPlaying;
  final String trackId;
  final Duration position;
  final Duration duration;

  const SpotifyPlayerState({
    required this.isPlaying,
    required this.trackId,
    required this.position,
    required this.duration,
  });
}

abstract class SpotifyRepository {
  Future<void> ensureConnected();
  Future<List<SpotifyTrack>> getPlaylistTracks(String playlistId);
  Future<List<SpotifyTrack>> searchTracks(String query);
  Future<void> playTrack(String trackId);
  Future<void> togglePlayback();
  Future<void> nextTrack();
  Future<void> previousTrack();
  Stream<SpotifyPlayerState> get playerState;
  SpotifyStatus get status;
  Stream<SpotifyStatus> get statusStream;
  String? get lastError;

  /// "display (id, product)" of the token's account, set after /me.
  String? get accountSummary;

  /// Effective playlist id used when callers pass ''.
  String? get effectivePlaylistId;

  /// Clears error state so a manual retry starts clean.
  void clearError();
}
