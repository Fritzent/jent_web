import 'package:injectable/injectable.dart';
import 'package:jent_web/domain/entities/spotify_track.dart';
import 'package:jent_web/domain/repositories/spotify_repository.dart';

@injectable
class SearchTracks {
  final SpotifyRepository _repository;

  SearchTracks(this._repository);

  Future<List<SpotifyTrack>> call(String query) =>
      _repository.searchTracks(query);
}

@injectable
class PlaySpotifyTrack {
  final SpotifyRepository _repository;

  PlaySpotifyTrack(this._repository);

  Future<void> call(String trackId) => _repository.playTrack(trackId);
}
