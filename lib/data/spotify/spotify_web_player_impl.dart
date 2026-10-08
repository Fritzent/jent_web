import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:jent_web/data/spotify/spotify_web_player.dart';

/// Web implementation of [SpotifyWebPlayer] using the Spotify Web
/// Playback SDK loaded from web/index.html.
///
/// Registered manually via [AppModule.spotifyWebPlayer] (conditional
/// import picks the stub on non-web platforms).
///
/// Uses only plain `@JS()` static bindings (no js_interop_unsafe)
/// so compilation is deterministic.
class SpotifyWebPlayerImpl implements SpotifyWebPlayer {
  StreamController<SpotifySdkState>? _stateController;
  SpotifyPlayerJs? _player;
  bool _ready = false;
  Completer<String>? _readyCompleter;

  @override
  bool get isSupported => true;

  @override
  Future<String> create({
    required Future<String> Function() getToken,
  }) async {
    _stateController ??= StreamController<SpotifySdkState>.broadcast();
    _readyCompleter = Completer<String>();

    await _whenSdkReady();

    // Temporary diagnostics: verify the SDK constructor is real.
    // ignore: avoid_print
    print(
      '[Spotify] SDK check: hasPlayer=$spotifyHasPlayer '
      'flag=$spotifyPlayerLoaded',
    );
    if (!spotifyHasPlayer) {
      throw StateError(
        'Spotify.Player is not a constructor '
        '(loaded=$spotifyPlayerLoaded). '
        'The SDK script may have failed to initialize.',
      );
    }

    // Construct via callAsConstructor (the official package:web pattern
    // for JS constructors): an external factory on a dotted @JS path
    // does not reliably perform `new` on the SDK constructor.
    final player = spotifyPlayerCtor.callAsConstructor(
      _PlayerOptionsJs(
        name: 'Jent Web Player'.toJS,
        volume: 0.8.toJS,
        getOAuthToken: ((JSFunction cb) {
          () async {
            final token = await getToken();
            cb.callAsFunction(null, token.toJS);
          }();
        }).toJS,
      ),
    ) as SpotifyPlayerJs;
    _player = player;

    player.addListener(
      'ready',
      ((JSAny data) {
        final id = (data as SpotifyReadyEventJs).deviceId;
        _ready = true;
        if (!(_readyCompleter?.isCompleted ?? true)) {
          _readyCompleter?.complete(id);
        }
      }).toJS,
    );

    player.addListener(
      'player_state_changed',
      ((JSAny? data) {
        if (data == null || data.isUndefinedOrNull) return;
        _stateController?.add(_parseState(data as SpotifyStateJs));
      }).toJS,
    );

    player.connect();

    return _readyCompleter!.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw TimeoutException('Spotify player not ready'),
    );
  }

  @override
  Future<void> connect() async {
    if (!_ready) throw StateError('Player not created');
  }

  @override
  Future<void> disconnect() async {
    _player?.disconnect();
    _player = null;
    _ready = false;
    await _stateController?.close();
    _stateController = null;
  }

  @override
  Future<void> togglePlay() async => _requirePlayer().togglePlay();

  @override
  Future<void> nextTrack() async => _requirePlayer().nextTrack();

  @override
  Future<void> previousTrack() async => _requirePlayer().previousTrack();

  @override
  Stream<SpotifySdkState> get stateChanged =>
      _stateController?.stream ?? const Stream.empty();

  SpotifyPlayerJs _requirePlayer() {
    final player = _player;
    if (player == null || !_ready) throw StateError('Player not ready');
    return player;
  }

  Future<void> _whenSdkReady() {
    if (spotifyPlayerLoaded && spotifyHasPlayer) {
      return Future.value();
    }
    final completer = Completer<void>();
    onSpotifySdkReady = (() {
      if (!completer.isCompleted) completer.complete();
    }).toJS;
    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () =>
          throw TimeoutException('Spotify SDK script not loaded'),
    );
  }

  SpotifySdkState _parseState(SpotifyStateJs data) {
    final current = data.trackWindow.currentTrack;
    return SpotifySdkState(
      paused: data.paused.toDart,
      trackId: current.id.toDart,
      position: Duration(milliseconds: data.position.toDartInt.toInt()),
      duration: Duration(
        milliseconds: current.durationMs.toDartInt.toInt(),
      ),
    );
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}

@JS('Spotify.Player')
extension type SpotifyPlayerJs._(JSObject _) implements JSObject {
  external void addListener(String event, JSAny callback);
  external void connect();
  external void disconnect();
  external void togglePlay();
  external void nextTrack();
  external void previousTrack();
}

/// Options dictionary (official @anonymous pattern for JS object args).
@JS()
@anonymous
extension type _PlayerOptionsJs._(JSObject _) implements JSObject {
  external factory _PlayerOptionsJs({
    JSString name,
    JSNumber volume,
    JSAny getOAuthToken,
  });
}

// ignore: non_constant_identifier_names
@JS()
@anonymous
extension type SpotifyReadyEventJs._(JSObject _) implements JSObject {
  // ignore: non_constant_identifier_names
  external JSString get device_id;
  String get deviceId => device_id.toDart;
}

// ignore: non_constant_identifier_names, library_private_types_in_public_api
@JS()
@anonymous
extension type SpotifyStateJs._(JSObject _) implements JSObject {
  external JSBoolean get paused;
  external JSNumber get position;
  // ignore: non_constant_identifier_names, library_private_types_in_public_api
  external _TrackWindowJs get track_window;
  // ignore: library_private_types_in_public_api
  _TrackWindowJs get trackWindow => track_window;
}

// ignore: library_private_types_in_public_api
@JS()
@anonymous
extension type _TrackWindowJs._(JSObject _) implements JSObject {
  // ignore: non_constant_identifier_names
  external _CurrentTrackJs get current_track;
  _CurrentTrackJs get currentTrack => current_track;
}

@JS()
@anonymous
extension type _CurrentTrackJs._(JSObject _) implements JSObject {
  external JSString get id;
  // ignore: non_constant_identifier_names
  external JSNumber get duration_ms;
  JSNumber get durationMs => duration_ms;
}

@JS('window.SpotifyPlayerLoaded')
external bool get spotifyPlayerLoaded;

@JS('Spotify.Player')
external JSFunction get spotifyPlayerCtor;

bool get spotifyHasPlayer =>
    spotifyPlayerCtor.isDefinedAndNotNull;

@JS('window.onSpotifyWebPlaybackSDKReady')
external set onSpotifySdkReady(JSFunction callback);
