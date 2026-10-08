import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jent_web/di/injection.dart';
import 'package:jent_web/domain/repositories/spotify_repository.dart';
import 'package:jent_web/features/desktop/view/home_page.dart';
import 'package:jent_web/features/mail/view/mail_window.dart';
import 'package:jent_web/features/music/bloc/music_bloc.dart';
import 'package:jent_web/features/music/view/music_player_overlay.dart';
import 'package:jent_web/features/photos/view/photos_window_overlay.dart';
import 'package:jent_web/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockSpotify extends Mock implements SpotifyRepository {}

/// Pumps the real desktop shell and asserts `Stack` paint order:
/// later children paint on top, so the latest opened window must sort
/// after the older ones.
void main() {
  Future<void> pumpHome(WidgetTester tester) async {
    // Real DI graph, but with Spotify stubbed: the toggle connects on
    // open, and the stub keeps it instant and offline.
    if (!getIt.isRegistered<MusicBloc>()) configureDependencies();
    if (getIt.isRegistered<SpotifyRepository>()) {
      getIt.unregister<SpotifyRepository>();
    }
    final spotify = _MockSpotify();
    when(
      () => spotify.statusStream,
    ).thenAnswer((_) => const Stream<SpotifyStatus>.empty());
    when(
      () => spotify.playerState,
    ).thenAnswer((_) => const Stream<SpotifyPlayerState>.empty());
    when(() => spotify.ensureConnected()).thenAnswer((_) async {});
    when(
      () => spotify.getPlaylistTracks(any()),
    ).thenAnswer((_) async => const []);
    getIt.registerLazySingleton<SpotifyRepository>(() => spotify);
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en')],
        home: HomePage(),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Paint index of a window wrapper in the desktop `Stack`.
  /// Later children paint on top.
  int windowIndex(WidgetTester tester, String id) {
    final stacks = tester.widgetList<Stack>(find.byType(Stack));
    final desktop = stacks.firstWhere(
      (s) => s.children.any((c) => c.key == const ValueKey('window-mail')),
      orElse: () => throw StateError('desktop stack not found'),
    );
    final keys = [
      for (final c in desktop.children) c.key,
    ];
    return keys.indexOf(ValueKey('window-$id'));
  }

  testWidgets('latest opened window paints in front', (tester) async {
    await pumpHome(tester);

    // Mail first, then music: music must sort after mail.
    await tester.tap(find.byKey(const ValueKey('dock-icon-email')));
    await settle(tester);
    expect(find.byType(MailWindow), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dock-icon-music')));
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MusicPlayerOverlay), findsOneWidget);

    var mailIdx = windowIndex(tester, 'mail');
    var musicIdx = windowIndex(tester, 'music');
    expect(musicIdx, greaterThan(mailIdx));

    // Photos unlocks last via PIN: it must land on top of both.
    await tester.tap(find.byKey(const ValueKey('dock-icon-photos')));
    await settle(tester);
    final pinField = find.descendant(
      of: find.byKey(const ValueKey('photos-pin-card')),
      matching: find.byType(TextField),
    );
    await tester.enterText(pinField, '1234');
    await tester.tap(find.text('Unlock'));
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PhotosWindowOverlay), findsOneWidget);

    mailIdx = windowIndex(tester, 'mail');
    musicIdx = windowIndex(tester, 'music');
    final photosIdx = windowIndex(tester, 'photos');
    expect(photosIdx, greaterThan(musicIdx));
    expect(musicIdx, greaterThan(mailIdx));

    // Clicking the behind mail window brings it to the front,
    // above music and photos.
    await tester.tap(find.text('Name:'));
    await settle(tester);
    mailIdx = windowIndex(tester, 'mail');
    musicIdx = windowIndex(tester, 'music');
    expect(mailIdx, greaterThan(musicIdx));
    expect(
      mailIdx,
      greaterThan(windowIndex(tester, 'photos')),
    );

    // Unmount the page so page-owned blocs (and their timers) die
    // before teardown.
    await tester.pumpWidget(Container());
  });
}
