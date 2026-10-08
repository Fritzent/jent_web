import 'spotify_web_player.dart';

/// Non-web fallback used by tests and native builds.
SpotifyWebPlayer createSpotifyWebPlayer() =>
    UnsupportedSpotifyWebPlayer();
