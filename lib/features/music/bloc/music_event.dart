import 'package:jent_web/domain/entities/spotify_track.dart';
import 'package:jent_web/domain/repositories/spotify_repository.dart';

abstract class MusicEvent {}

class ToggleMusicPlayer extends MusicEvent {}

class SpotifyConnectRequested extends MusicEvent {}

class SpotifyTracksLoaded extends MusicEvent {
  final List<SpotifyTrack> tracks;

  SpotifyTracksLoaded(this.tracks);
}

class SpotifySearchRequested extends MusicEvent {
  final String query;

  SpotifySearchRequested(this.query);
}

class SpotifySearchResults extends MusicEvent {
  final List<SpotifyTrack> results;

  SpotifySearchResults(this.results);
}

class SpotifyPlayTrack extends MusicEvent {
  final String trackId;

  SpotifyPlayTrack(this.trackId);
}

class SpotifyPlayerUpdated extends MusicEvent {
  final bool isPlaying;
  final String trackId;
  final Duration position;
  final Duration duration;

  SpotifyPlayerUpdated({
    required this.isPlaying,
    required this.trackId,
    required this.position,
    required this.duration,
  });
}

class SpotifyStatusChanged extends MusicEvent {
  final SpotifyStatus status;

  SpotifyStatusChanged(this.status);
}

class CloseMusicPlayer extends MusicEvent {}

class MinimizeMusicPlayer extends MusicEvent {}

class ExpandMusicPlayer extends MusicEvent {}

class SelectMusicTrack extends MusicEvent {
  final int index;

  SelectMusicTrack(this.index);
}

class ToggleMusicPlayback extends MusicEvent {}

class NextMusicTrack extends MusicEvent {}

class PreviousMusicTrack extends MusicEvent {}

class MusicProgressTicked extends MusicEvent {
  final Duration position;

  MusicProgressTicked(this.position);
}
