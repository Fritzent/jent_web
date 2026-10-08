// Platform-selective Spotify player factory: the JS bridge only
// compiles for web (`dart:js_interop`), everything else (VM tests,
// native builds) gets the unsupported stub.
export 'spotify_web_player_create_stub.dart'
    if (dart.library.js_interop) 'spotify_web_player_create_web.dart';
