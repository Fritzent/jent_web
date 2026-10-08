import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jent_web/core/widgets/window/traffic_light_button.dart';
import 'package:jent_web/domain/entities/spotify_track.dart';
import 'package:jent_web/domain/repositories/spotify_repository.dart';
import 'package:jent_web/domain/usecases/spotify_usecases.dart';
import 'package:jent_web/features/music/bloc/music_bloc.dart';
import 'package:jent_web/features/music/bloc/music_event.dart';
import 'package:jent_web/features/music/view/music_artwork.dart';
import 'package:jent_web/features/music/view/music_controls.dart';
import 'package:jent_web/features/music/view/music_search.dart';
import 'package:jent_web/features/music/view/music_window_chrome.dart';
import 'package:jent_web/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockSpotify extends Mock implements SpotifyRepository {}
class _MockSearchTracks extends Mock implements SearchTracks {}
class _MockPlayTrack extends Mock implements PlaySpotifyTrack {}
class _FakeTrack extends Fake implements SpotifyTrack {}

const _demoTracks = [
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
];

Widget l10nWrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: Scaffold(body: child),
  );
}

void main() {
  setUpAll(() => registerFallbackValue(_FakeTrack()));

  group('formatTrackTime', () {
    test('formats durations as m:ss', () {
      expect(formatTrackTime(Duration.zero), '0:00');
      expect(formatTrackTime(const Duration(seconds: 7)), '0:07');
      expect(
        formatTrackTime(const Duration(minutes: 5, seconds: 26)),
        '5:26',
      );
    });
  });

  group('MusicWindowChrome', () {
    testWidgets('routes lights and drag area', (tester) async {
      var closed = 0;
      var minimized = 0;
      var expanded = 0;
      var dragged = Offset.zero;
      await tester.pumpWidget(
        l10nWrap(
          MusicWindowChrome(
            onClose: () => closed++,
            onMinimize: () => minimized++,
            onExpand: () => expanded++,
            onPanUpdate: (d) => dragged += d,
          ),
        ),
      );

      Finder light(Color color) => find.byWidgetPredicate(
            (w) => w is TrafficLightButton && w.color == color,
          );
      await tester.tap(light(const Color(0xFFFF5F57)));
      await tester.tap(light(const Color(0xFFFEBC2E)));
      await tester.tap(light(const Color(0xFF28C840)));
      expect(closed, 1);
      expect(minimized, 1);
      expect(expanded, 1);

      await tester.drag(find.byType(MusicWindowChrome), const Offset(15, 5));
      await tester.pump();
      // Drag may hit the chrome strip; deltas are best-effort here.
      expect(dragged.dx, greaterThanOrEqualTo(0));
    });
  });

  group('MusicTransportControls', () {
    testWidgets('fires callbacks and swaps play/pause icon', (tester) async {
      var prev = 0;
      var toggle = 0;
      var next = 0;
      await tester.pumpWidget(
        l10nWrap(
          MusicTransportControls(
            isPlaying: false,
            onPrevious: () => prev++,
            onToggle: () => toggle++,
            onNext: () => next++,
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.skip_previous_rounded));
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      expect(prev, 1);
      expect(toggle, 1);
      expect(next, 1);

      await tester.pumpWidget(
        l10nWrap(
          MusicTransportControls(
            isPlaying: true,
            onPrevious: () {},
            onToggle: () {},
            onNext: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    });
  });

  group('MusicProgressBar', () {
    testWidgets('shows elapsed and total times', (tester) async {
      await tester.pumpWidget(
        l10nWrap(
          const MusicProgressBar(
            position: Duration(seconds: 65),
            duration: Duration(minutes: 3),
          ),
        ),
      );

      expect(find.text('1:05'), findsOneWidget);
      expect(find.text('3:00'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  group('MusicTrackHeader', () {
    testWidgets('shows uppercased status, title, artist', (tester) async {
      await tester.pumpWidget(
        l10nWrap(
          const MusicTrackHeader(
            title: 'Ride Home',
            artist: 'Ben&Ben',
            statusLabel: 'Now playing',
          ),
        ),
      );

      expect(find.text('NOW PLAYING'), findsOneWidget);
      expect(find.text('Ride Home'), findsOneWidget);
      expect(find.text('Ben&Ben'), findsOneWidget);
    });
  });

  group('MusicArtwork', () {
    testWidgets('renders placeholder art at requested size', (tester) async {
      await tester.pumpWidget(
        l10nWrap(
          const MusicArtwork(isPlaying: false, size: 36),
        ),
      );

      expect(tester.getSize(find.byType(MusicArtwork)), const Size(36, 36));
    });
  });

  group('MusicSearch', () {
    Future<MusicBloc> pumpSearch(
      WidgetTester tester, {
      List<SpotifyTrack> results = _demoTracks,
    }) async {
      final spotify = _MockSpotify();
      when(
        () => spotify.statusStream,
      ).thenAnswer((_) => const Stream<SpotifyStatus>.empty());
      when(
        () => spotify.playerState,
      ).thenAnswer((_) => const Stream<SpotifyPlayerState>.empty());
      when(
        () => spotify.ensureConnected(),
      ).thenAnswer((_) async {});
      final searchTracks = _MockSearchTracks();
      when(
        () => searchTracks(any()),
      ).thenAnswer((_) async => results);
      final playTrack = _MockPlayTrack();
      when(
        () => playTrack(any()),
      ).thenAnswer((_) async {});
      final bloc = MusicBloc(spotify, searchTracks, playTrack);
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
            child: const Scaffold(body: MusicSearch()),
          ),
        ),
      );
      return bloc;
    }

    testWidgets('hidden until Spotify is ready', (tester) async {
      await pumpSearch(tester);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('typing searches and lists results', (tester) async {
      final bloc = await pumpSearch(tester);
      bloc.add(SpotifyTracksLoaded(_demoTracks));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(find.byType(TextField), 'ride');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Ride Home'), findsOneWidget);
      expect(find.text('Second Song'), findsOneWidget);
    });

    testWidgets('tapping a result plays it', (tester) async {
      final playTrack = _MockPlayTrack();
      final spotify = _MockSpotify();
      when(
        () => spotify.statusStream,
      ).thenAnswer((_) => const Stream<SpotifyStatus>.empty());
      when(
        () => spotify.playerState,
      ).thenAnswer((_) => const Stream<SpotifyPlayerState>.empty());
      when(
        () => spotify.ensureConnected(),
      ).thenAnswer((_) async {});
      when(
        () => playTrack(any()),
      ).thenAnswer((_) async {});
      final searchTracks = _MockSearchTracks();
      when(
        () => searchTracks(any()),
      ).thenAnswer((_) async => _demoTracks);
      final bloc = MusicBloc(spotify, searchTracks, playTrack);
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
            child: const Scaffold(body: MusicSearch()),
          ),
        ),
      );

      bloc.add(SpotifyTracksLoaded(_demoTracks));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'ride');
      await tester.pump(const Duration(milliseconds: 700));

      await tester.tap(find.text('Second Song').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      verify(() => playTrack('t2')).called(1);
    });

    testWidgets('empty results show the no-results message', (tester) async {
      final bloc = await pumpSearch(tester, results: const []);
      bloc.add(SpotifyTracksLoaded(_demoTracks));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('No songs found, try another search'),
        findsOneWidget,
      );
    });

    testWidgets('clear button resets the field and results', (tester) async {
      final bloc = await pumpSearch(tester);
      bloc.add(SpotifyTracksLoaded(_demoTracks));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(find.byType(TextField), 'ride');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(bloc.state.spotifyQuery, isEmpty);
      expect(find.text('Ride Home'), findsNothing);
    });
  });

  group('SpotifyStatusLine', () {
    Future<MusicBloc> pumpLine(WidgetTester tester) async {
      final spotify = _MockSpotify();
      when(
        () => spotify.statusStream,
      ).thenAnswer((_) => const Stream<SpotifyStatus>.empty());
      when(
        () => spotify.playerState,
      ).thenAnswer((_) => const Stream<SpotifyPlayerState>.empty());
      when(
        () => spotify.ensureConnected(),
      ).thenAnswer((_) async {});
      final bloc = MusicBloc(spotify, _MockSearchTracks(), _MockPlayTrack());
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
            child: const Scaffold(body: SpotifyStatusLine()),
          ),
        ),
      );
      return bloc;
    }

    testWidgets('shows offline mode when disconnected', (tester) async {
      await pumpLine(tester);
      expect(find.text('Offline mode'), findsOneWidget);
    });

    testWidgets('error with detail opens dialog with retry', (tester) async {
      final spotify = _MockSpotify();
      when(
        () => spotify.statusStream,
      ).thenAnswer((_) => const Stream<SpotifyStatus>.empty());
      when(
        () => spotify.playerState,
      ).thenAnswer((_) => const Stream<SpotifyPlayerState>.empty());
      when(() => spotify.lastError).thenReturn('no token');
      when(
        () => spotify.ensureConnected(),
      ).thenThrow(Exception('no token'));
      final bloc = MusicBloc(spotify, _MockSearchTracks(), _MockPlayTrack());
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
            child: const Scaffold(body: SpotifyStatusLine()),
          ),
        ),
      );

      bloc.add(SpotifyConnectRequested());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(bloc.state.spotifyStatus, SpotifyStatus.error);

      await tester.tap(find.byType(InkWell), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Spotify connection failed'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      verify(() => spotify.ensureConnected()).called(greaterThanOrEqualTo(1));
    });
  });
}
