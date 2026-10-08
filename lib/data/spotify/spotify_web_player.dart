import 'dart:async';

/// Browser-only Spotify Web Playback SDK surface, hidden behind an
/// interface so blocs and tests never touch JS interop directly.
abstract class SpotifyWebPlayer {
  bool get isSupported;
  Future<String> create({required Future<String> Function() getToken});
  Future<void> connect();
  Future<void> disconnect();
  Future<void> togglePlay();
  Future<void> nextTrack();
  Future<void> previousTrack();
  Stream<SpotifySdkState> get stateChanged;
}

class SpotifySdkState {
  final bool paused;
  final String trackId;
  final Duration position;
  final Duration duration;

  const SpotifySdkState({
    required this.paused,
    required this.trackId,
    required this.position,
    required this.duration,
  });
}

/// Non-web / test fallback: SDK only runs in real browsers.
class UnsupportedSpotifyWebPlayer implements SpotifyWebPlayer {
  @override
  bool get isSupported => false;

  @override
  Future<String> create({required Future<String> Function() getToken}) =>
      throw UnsupportedError('Spotify SDK requires a browser');

  @override
  Future<void> connect() =>
      throw UnsupportedError('Spotify SDK requires a browser');

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> nextTrack() =>
      throw UnsupportedError('Spotify SDK requires a browser');

  @override
  Future<void> previousTrack() =>
      throw UnsupportedError('Spotify SDK requires a browser');

  @override
  Future<void> togglePlay() =>
      throw UnsupportedError('Spotify SDK requires a browser');

  @override
  Stream<SpotifySdkState> get stateChanged => const Stream.empty();
}
