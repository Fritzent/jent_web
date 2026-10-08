import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:jent_web/domain/entities/music_track.dart';
import 'package:jent_web/domain/repositories/spotify_repository.dart';
import 'package:jent_web/domain/usecases/spotify_usecases.dart';
import 'package:jent_web/features/music/bloc/music_event.dart';
import 'package:jent_web/features/music/bloc/music_state.dart';

@injectable
class MusicBloc extends Bloc<MusicEvent, MusicState> {
  Timer? _musicTimer;
  StreamSubscription<SpotifyPlayerState>? _spotifyPlayerSub;
  StreamSubscription<SpotifyStatus>? _spotifyStatusSub;

  final SpotifyRepository _spotify;
  final SearchTracks _searchTracks;
  final PlaySpotifyTrack _playTrack;

  MusicBloc(
    this._spotify,
    this._searchTracks,
    this._playTrack,
  ) : super(const MusicState()) {
    on<ToggleMusicPlayer>(_onToggleMusicPlayer);
    on<SpotifyConnectRequested>(_onSpotifyConnect);
    on<SpotifyTracksLoaded>(_onSpotifyTracksLoaded);
    on<SpotifySearchRequested>(_onSpotifySearch);
    on<SpotifySearchResults>(_onSpotifySearchResults);
    on<SpotifyPlayTrack>(_onSpotifyPlayTrack);
    on<SpotifyPlayerUpdated>(_onSpotifyPlayerUpdated);
    on<SpotifyStatusChanged>(_onSpotifyStatusChanged);
    on<CloseMusicPlayer>(_onCloseMusicPlayer);
    on<MinimizeMusicPlayer>(_onMinimizeMusicPlayer);
    on<ExpandMusicPlayer>(_onExpandMusicPlayer);
    on<SelectMusicTrack>(_onSelectMusicTrack);
    on<ToggleMusicPlayback>(_onToggleMusicPlayback);
    on<NextMusicTrack>(_onNextTrack);
    on<PreviousMusicTrack>(_onPreviousTrack);
    on<MusicProgressTicked>(_onProgressTicked);

    _spotifyStatusSub = _spotify.statusStream.listen(
      (status) => add(SpotifyStatusChanged(status)),
    );
    _spotifyPlayerSub = _spotify.playerState.listen(
      (player) => add(
        SpotifyPlayerUpdated(
          isPlaying: player.isPlaying,
          trackId: player.trackId,
          position: player.position,
          duration: player.duration,
        ),
      ),
    );
  }

  void _onToggleMusicPlayer(
    ToggleMusicPlayer event,
    Emitter<MusicState> emit,
  ) {
    final show = !state.isShowMusicPlayer;
    if (show) {
      emit(
        state.copyWith(
          isShowMusicPlayer: true,
          isMusicMinimized: false,
          isMusicExpanded: false,
          isMusicPlaying: true,
        ),
      );
      _startMusicTimer();
      add(SpotifyConnectRequested());
    } else {
      emit(state.copyWith(isShowMusicPlayer: false));
    }
  }

  Future<void> _onSpotifyConnect(
    SpotifyConnectRequested event,
    Emitter<MusicState> emit,
  ) async {
    if (state.spotifyStatus == SpotifyStatus.ready ||
        state.spotifyStatus == SpotifyStatus.connecting) {
      return;
    }
    _spotify.clearError();
    emit(
      state.copyWith(
        spotifyStatus: SpotifyStatus.connecting,
        spotifyErrorDetail: null,
      ),
    );
    try {
      await _spotify.ensureConnected();
      final tracks = await _spotify.getPlaylistTracks('');
      add(SpotifyTracksLoaded(tracks));
    } catch (e) {
      final account = _spotify.accountSummary;
      final playlist = _spotify.effectivePlaylistId;
      final context =
          account != null || playlist != null
              ? ' [account=$account playlist=$playlist]'
              : '';
      emit(
        state.copyWith(
          spotifyStatus: SpotifyStatus.error,
          spotifyErrorDetail:
              '${_spotify.lastError ?? e.toString()}$context',
        ),
      );
    }
  }

  void _onSpotifyTracksLoaded(
    SpotifyTracksLoaded event,
    Emitter<MusicState> emit,
  ) {
    emit(
      state.copyWith(
        spotifyTracks: event.tracks,
        spotifyStatus: SpotifyStatus.ready,
        musicTrackIndex: 0,
        musicPosition: Duration.zero,
      ),
    );
    if (event.tracks.isEmpty) return;
    _stopSimulation();
    emit(state.copyWith(isMusicPlaying: true));
    add(SpotifyPlayTrack(event.tracks.first.id));
  }

  Future<void> _onSpotifySearch(
    SpotifySearchRequested event,
    Emitter<MusicState> emit,
  ) async {
    final query = event.query.trim();
    emit(
      state.copyWith(
        spotifyQuery: event.query,
        spotifySearching: query.isNotEmpty,
        spotifySearchResults:
            query.isEmpty ? const [] : state.spotifySearchResults,
      ),
    );
    if (query.isEmpty) return;
    try {
      await _spotify.ensureConnected();
      final results = await _searchTracks(query);
      add(SpotifySearchResults(results));
    } catch (_) {
      emit(
        state.copyWith(
          spotifySearching: false,
          spotifyStatus: SpotifyStatus.error,
        ),
      );
    }
  }

  void _onSpotifySearchResults(
    SpotifySearchResults event,
    Emitter<MusicState> emit,
  ) {
    emit(
      state.copyWith(
        spotifySearchResults: event.results,
        spotifySearching: false,
      ),
    );
  }

  Future<void> _onSpotifyPlayTrack(
    SpotifyPlayTrack event,
    Emitter<MusicState> emit,
  ) async {
    try {
      await _playTrack(event.trackId);
    } catch (_) {
      emit(state.copyWith(spotifyStatus: SpotifyStatus.error));
    }
  }

  void _onSpotifyPlayerUpdated(
    SpotifyPlayerUpdated event,
    Emitter<MusicState> emit,
  ) {
    if (state.spotifyStatus != SpotifyStatus.ready) return;
    final index = state.spotifyTracks.indexWhere(
      (t) => t.id == event.trackId,
    );
    _musicTimer?.cancel();
    emit(
      state.copyWith(
        isMusicPlaying: event.isPlaying,
        musicPosition: event.position,
        musicTrackIndex: index >= 0 ? index : state.musicTrackIndex,
      ),
    );
  }

  void _onSpotifyStatusChanged(
    SpotifyStatusChanged event,
    Emitter<MusicState> emit,
  ) {
    emit(
      state.copyWith(
        spotifyStatus: event.status,
        spotifyErrorDetail: event.status == SpotifyStatus.error
            ? (_spotify.lastError ?? state.spotifyErrorDetail)
            : state.spotifyErrorDetail,
      ),
    );
  }

  void _stopSimulation() => _musicTimer?.cancel();

  void _onCloseMusicPlayer(CloseMusicPlayer event, Emitter<MusicState> emit) {
    _musicTimer?.cancel();
    emit(
      state.copyWith(
        isShowMusicPlayer: false,
        isMusicMinimized: false,
        isMusicExpanded: false,
        isMusicPlaying: false,
        musicPosition: Duration.zero,
      ),
    );
  }

  void _onMinimizeMusicPlayer(
    MinimizeMusicPlayer event,
    Emitter<MusicState> emit,
  ) {
    emit(
      state.copyWith(
        isShowMusicPlayer: false,
        isMusicMinimized: true,
        isMusicExpanded: false,
      ),
    );
  }

  void _onExpandMusicPlayer(ExpandMusicPlayer event, Emitter<MusicState> emit) {
    emit(state.copyWith(isMusicExpanded: !state.isMusicExpanded));
  }

  bool get _spotifyReady =>
      state.spotifyStatus == SpotifyStatus.ready &&
      state.spotifyTracks.isNotEmpty;

  void _onSelectMusicTrack(SelectMusicTrack event, Emitter<MusicState> emit) {
    if (_spotifyReady) {
      if (event.index < 0 || event.index >= state.spotifyTracks.length) {
        return;
      }
      emit(
        state.copyWith(
          musicTrackIndex: event.index,
          musicPosition: Duration.zero,
          isMusicPlaying: true,
          isShowMusicPlayer: true,
          isMusicMinimized: false,
        ),
      );
      add(SpotifyPlayTrack(state.spotifyTracks[event.index].id));
      return;
    }
    if (event.index < 0 || event.index >= MusicPlaylist.tracks.length) return;
    emit(
      state.copyWith(
        musicTrackIndex: event.index,
        musicPosition: Duration.zero,
        isMusicPlaying: true,
        isShowMusicPlayer: true,
        isMusicMinimized: false,
      ),
    );
    _startMusicTimer();
  }

  Future<void> _onToggleMusicPlayback(
    ToggleMusicPlayback event,
    Emitter<MusicState> emit,
  ) async {
    if (_spotifyReady) {
      try {
        await _spotify.togglePlayback();
      } catch (_) {
        emit(state.copyWith(spotifyStatus: SpotifyStatus.error));
      }
      return;
    }
    final playing = !state.isMusicPlaying;
    emit(state.copyWith(isMusicPlaying: playing));
    _musicTimer?.cancel();
    if (playing) _startMusicTimer();
  }

  void _startMusicTimer() {
    _musicTimer?.cancel();
    _musicTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(MusicProgressTicked(state.musicPosition + _tick)),
    );
  }

  Future<void> _onNextTrack(
    NextMusicTrack event,
    Emitter<MusicState> emit,
  ) async {
    if (_spotifyReady) {
      try {
        await _spotify.nextTrack();
      } catch (_) {
        emit(state.copyWith(spotifyStatus: SpotifyStatus.error));
      }
      return;
    }
    final next = (state.musicTrackIndex + 1) % MusicPlaylist.tracks.length;
    emit(state.copyWith(musicTrackIndex: next, musicPosition: Duration.zero));
  }

  Future<void> _onPreviousTrack(
    PreviousMusicTrack event,
    Emitter<MusicState> emit,
  ) async {
    if (_spotifyReady) {
      try {
        await _spotify.previousTrack();
      } catch (_) {
        emit(state.copyWith(spotifyStatus: SpotifyStatus.error));
      }
      return;
    }
    if (state.musicPosition > const Duration(seconds: 3)) {
      emit(state.copyWith(musicPosition: Duration.zero));
      return;
    }
    final previous =
        (state.musicTrackIndex - 1 + MusicPlaylist.tracks.length) %
        MusicPlaylist.tracks.length;
    emit(
      state.copyWith(musicTrackIndex: previous, musicPosition: Duration.zero),
    );
  }

  void _onProgressTicked(MusicProgressTicked event, Emitter<MusicState> emit) {
    // Real position arrives via the SDK stream when connected;
    // the simulated timer only drives the offline fallback list.
    if (state.spotifyStatus == SpotifyStatus.ready) return;
    final duration = MusicPlaylist.tracks[state.musicTrackIndex].duration;
    if (event.position >= duration) {
      final next = (state.musicTrackIndex + 1) % MusicPlaylist.tracks.length;
      emit(state.copyWith(musicTrackIndex: next, musicPosition: Duration.zero));
      return;
    }
    emit(state.copyWith(musicPosition: event.position));
  }

  static const _tick = Duration(seconds: 1);

  @override
  Future<void> close() {
    _musicTimer?.cancel();
    _spotifyPlayerSub?.cancel();
    _spotifyStatusSub?.cancel();
    return super.close();
  }
}
