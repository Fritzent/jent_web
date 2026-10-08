import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jent_web/domain/entities/spotify_track.dart';
import 'package:jent_web/domain/repositories/spotify_repository.dart';
import 'package:jent_web/domain/usecases/spotify_usecases.dart';
import 'package:jent_web/l10n/app_localizations.dart';
import 'package:jent_web/features/music/bloc/music_bloc.dart';
import 'package:jent_web/features/music/bloc/music_event.dart';
import 'package:jent_web/core/widgets/window/traffic_light_button.dart';
import 'package:jent_web/features/music/view/music_player_overlay.dart';
import 'package:mocktail/mocktail.dart';

class _MockSpotify extends Mock implements SpotifyRepository {}
class _MockSearchTracks extends Mock implements SearchTracks {}
class _MockPlayTrack extends Mock implements PlaySpotifyTrack {}

void main() {
  testWidgets(
    'expanded player lists Spotify tracks and tapping selects one',
    (tester) async {
      final spotify = _MockSpotify();
      when(
        () => spotify.statusStream,
      ).thenAnswer((_) => const Stream<SpotifyStatus>.empty());
      when(
        () => spotify.playerState,
      ).thenAnswer((_) => const Stream<SpotifyPlayerState>.empty());
      final searchTracks = _MockSearchTracks();
      final playTrack = _MockPlayTrack();
      when(
        () => playTrack(any()),
      ).thenAnswer((_) async {});
      final bloc = MusicBloc(
        spotify,
        searchTracks,
        playTrack,
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: BlocProvider.value(
            value: bloc,
            child: const Scaffold(
              body: Stack(children: [MusicPlayerOverlay()]),
            ),
          ),
        ),
      );

      // Open, connect, and seed the playlist exactly as the repo
      // would after a successful fetch.
      bloc.add(ToggleMusicPlayer());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      bloc.add(
        SpotifyTracksLoaded(
          const [
            SpotifyTrack(
              id: 't1',
              title: 'Ride Home',
              artist: 'Ben&Ben',
              artworkUrl: '',
              duration: Duration(minutes: 5, seconds: 26),
            ),
            SpotifyTrack(
              id: 't2',
              title: 'Second Song',
              artist: 'Someone',
              artworkUrl: '',
              duration: Duration(minutes: 3),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Expand via the green chrome button. (Traffic-light glyphs are
      // hover-only, so match the button widget, not the icon.)
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is TrafficLightButton && w.color == const Color(0xFF28C840),
        ),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 400));

      // Spotify titles are visible in the list. "Ride Home" appears
      // twice: in the now-playing header AND in the playlist list.
      expect(find.text('Your playlist'), findsOneWidget);
      expect(find.text('Ride Home'), findsNWidgets(2));
      expect(find.text('Second Song'), findsOneWidget);
      expect(find.text('Ben&Ben'), findsNWidgets(2));

      // Tapping the second row selects it and plays it.
      await tester.tap(find.text('Second Song'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(bloc.state.musicTrackIndex, 1);
      expect(bloc.state.isMusicPlaying, isTrue);
      verify(() => playTrack('t2')).called(1);
    },
  );
}
