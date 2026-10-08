import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:jent_web/data/datasources/spotify_api_datasource.dart';
import 'package:jent_web/data/datasources/spotify_auth.dart';
import 'package:jent_web/data/spotify/spotify_web_player.dart';
import 'package:jent_web/domain/entities/spotify_track.dart';
import 'package:jent_web/domain/repositories/spotify_repository.dart';

/// Owner-account Spotify: one Premium login (yours) serves every
/// visitor. Falls back to local simulation when unconfigured.
@LazySingleton(as: SpotifyRepository)
class SpotifyRepositoryImpl implements SpotifyRepository {
  final SpotifyAuth _auth;
  final SpotifyApiDatasource _api;
  final SpotifyWebPlayer _player;
  final String _playlistId;

  final _statusController =
      StreamController<SpotifyStatus>.broadcast();
  SpotifyStatus _status = SpotifyStatus.disconnected;
  String? _lastError;
  StreamSubscription<SpotifySdkState>? _sdkSub;
  final _playerStateController =
      StreamController<SpotifyPlayerState>.broadcast();
  String? _deviceId;
  Future<void>? _connecting;

  SpotifyRepositoryImpl(
    this._auth,
    this._api,
    this._player,
    @Named('spotifyPlaylistId') this._playlistId,
  );

  @override
  SpotifyStatus get status => _status;

  @override
  Stream<SpotifyStatus> get statusStream => _statusController.stream;

  @override
  Stream<SpotifyPlayerState> get playerState =>
      _playerStateController.stream;

  @override
  String? get lastError => _lastError;

  String? _accountSummary;
  @override
  String? get accountSummary => _accountSummary;

  @override
  String? get effectivePlaylistId =>
      _playlistId.isEmpty ? null : _playlistId;

  @override
  void clearError() {
    _lastError = null;
    _auth.invalidateToken();
  }

  void _setStatus(SpotifyStatus status, [Object? error]) {
    _status = status;
    if (error != null) {
      _lastError = error.toString();
      // ignore: avoid_print
      print('[Spotify] $status: $_lastError');
    } else if (status == SpotifyStatus.connecting ||
        status == SpotifyStatus.ready) {
      // ignore: avoid_print
      print('[Spotify] $status');
    }
    _statusController.add(status);
  }

  @override
  Future<void> ensureConnected() {
    _connecting ??= _connect();
    return _connecting!.whenComplete(() => _connecting = null);
  }

  Future<void> _connect() async {
    if (_status == SpotifyStatus.ready) return;
    if (!_auth.isConfigured) {
      _setStatus(
        SpotifyStatus.error,
        'Missing SPOTIFY_CLIENT_ID or SPOTIFY_REFRESH_TOKEN dart-define',
      );
      return;
    }
    if (!_player.isSupported) {
      _setStatus(
        SpotifyStatus.error,
        'Web Playback SDK not supported on this platform',
      );
      return;
    }
    _setStatus(SpotifyStatus.connecting);
    try {
      final me = await _api.currentUser();
      _accountSummary =
          '${me['display_name']} (${me['id']}, ${me['product']})';
      // ignore: avoid_print
      print(
        '[Spotify] account=${me['display_name']} '
        'id=${me['id']} product=${me['product']} '
        'country=${me['country']} playlist=$effectivePlaylistId',
      );
      // ignore: avoid_print
      print('[Spotify] creating SDK player…');
      final deviceId = await _player.create(
        getToken: _auth.accessToken,
      );
      _deviceId = deviceId;
      // ignore: avoid_print
      print('[Spotify] SDK ready, device=$deviceId, transferring…');
      await _api.transferPlayback(deviceId, play: false);
      _sdkSub ??= _player.stateChanged.listen(
        (sdk) => _playerStateController.add(
          SpotifyPlayerState(
            isPlaying: !sdk.paused,
            trackId: sdk.trackId,
            position: sdk.position,
            duration: sdk.duration,
          ),
        ),
      );
      _setStatus(SpotifyStatus.ready);
    } catch (e) {
      _setStatus(SpotifyStatus.error, e);
      rethrow;
    }
  }

  @override
  Future<List<SpotifyTrack>> getPlaylistTracks(String playlistId) =>
      _api.playlistTracks(
        playlistId.isEmpty ? _playlistId : playlistId,
      );

  @override
  Future<List<SpotifyTrack>> searchTracks(String query) =>
      _api.searchTracks(query);

  @override
  Future<void> playTrack(String trackId) async {
    await ensureConnected();
    final deviceId = _deviceId;
    if (deviceId == null) throw StateError('No Spotify device');
    await _api.playOnDevice(deviceId, trackId);
  }

  @override
  Future<void> togglePlayback() async {
    await ensureConnected();
    await _player.togglePlay();
  }

  @override
  Future<void> nextTrack() async {
    await ensureConnected();
    await _player.nextTrack();
  }

  @override
  Future<void> previousTrack() async {
    await ensureConnected();
    await _player.previousTrack();
  }
}
