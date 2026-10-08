import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:jent_web/data/spotify/spotify_web_player.dart';
import 'package:jent_web/data/spotify/spotify_web_player_create.dart'
    show createSpotifyWebPlayer;
import 'package:jent_web/di/injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();

@module
abstract class AppModule {
  @Named('emailUsername')
  String get emailUsername =>
      const String.fromEnvironment('EMAIL_USERNAME');

  @Named('emailPassword')
  String get emailPassword =>
      const String.fromEnvironment('EMAIL_PASSWORD');

  @Named('emailRecipient')
  String get emailRecipient =>
      const String.fromEnvironment('EMAIL_RECIPIENT');

  @Named('spotifyClientId')
  String get spotifyClientId =>
      const String.fromEnvironment('SPOTIFY_CLIENT_ID').trim();

  @Named('spotifyRefreshToken')
  String get spotifyRefreshToken =>
      const String.fromEnvironment('SPOTIFY_REFRESH_TOKEN').trim();

  @Named('spotifyPlaylistId')
  String get spotifyPlaylistId =>
      const String.fromEnvironment('SPOTIFY_PLAYLIST_ID').trim();

  @lazySingleton
  SpotifyWebPlayer get spotifyWebPlayer => createSpotifyWebPlayer();
}
