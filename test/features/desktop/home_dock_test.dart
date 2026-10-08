import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jent_web/data/datasources/notes_remote_datasource.dart';
import 'package:jent_web/features/desktop/widgets/home_dock.dart';
import 'package:jent_web/features/mail/bloc/mail_bloc.dart';
import 'package:jent_web/features/mail/bloc/mail_event.dart';
import 'package:jent_web/features/music/bloc/music_bloc.dart';
import 'package:jent_web/features/music/bloc/music_event.dart';
import 'package:jent_web/features/notes/bloc/notes_bloc.dart';
import 'package:jent_web/features/notes/bloc/notes_event.dart';
import 'package:jent_web/features/photos/bloc/photos_bloc.dart';
import 'package:jent_web/features/photos/bloc/photos_event.dart';
import 'package:jent_web/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import 'package:jent_web/domain/repositories/spotify_repository.dart';
import 'package:jent_web/domain/usecases/send_email_usecase.dart';
import 'package:jent_web/domain/usecases/spotify_usecases.dart';

class _MockSendEmail extends Mock implements SendEmailUseCase {}
class _MockSpotify extends Mock implements SpotifyRepository {}
class _MockSearchTracks extends Mock implements SearchTracks {}
class _MockPlayTrack extends Mock implements PlaySpotifyTrack {}

void main() {
  /// The running-app indicator dot under a dock icon: an 8x8 grey
  /// circle. Icon tiles use rounded rectangles, so the circle shape
  /// identifies dots uniquely.
  Finder dockDots() => find.byWidgetPredicate((w) {
        if (w is! Container) return false;
        final decoration = w.decoration;
        return decoration is BoxDecoration &&
            decoration.shape == BoxShape.circle;
      });

  late MailBloc mailBloc;
  late NotesBloc notesBloc;
  late MusicBloc musicBloc;
  late PhotosBloc photosBloc;

  Future<void> pumpDock(WidgetTester tester) {
    final spotify = _MockSpotify();
    when(
      () => spotify.statusStream,
    ).thenAnswer((_) => const Stream<SpotifyStatus>.empty());
    when(
      () => spotify.playerState,
    ).thenAnswer((_) => const Stream<SpotifyPlayerState>.empty());
    mailBloc = MailBloc(_MockSendEmail());
    notesBloc = NotesBloc(NotesRemoteDataSource());
    musicBloc = MusicBloc(spotify, _MockSearchTracks(), _MockPlayTrack());
    photosBloc = PhotosBloc();
    addTearDown(() async {
      await mailBloc.close();
      await notesBloc.close();
      await musicBloc.close();
      await photosBloc.close();
    });
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: mailBloc),
            BlocProvider.value(value: notesBloc),
            BlocProvider.value(value: musicBloc),
            BlocProvider.value(value: photosBloc),
          ],
          child: const Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: HomeDock(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('email dot tracks open, minimize, and close', (tester) async {
    await pumpDock(tester);

    // Launch: nothing running, no dots.
    expect(dockDots(), findsNothing);

    // Open: running app shows the dot.
    mailBloc.add(ToggleOpenEmailMenu());
    await settle(tester);
    expect(mailBloc.state.isShowWindow, isTrue);
    expect(dockDots(), findsOneWidget);

    // Minimize: window hidden but the dot stays (regression test).
    mailBloc.add(ToggleMinimizeEmailMenu());
    await settle(tester);
    expect(mailBloc.state.isMinimizedWindow, isTrue);
    expect(dockDots(), findsOneWidget);

    // Dock tap restores; closing clears the dot.
    mailBloc.add(ToggleOpenEmailMenu());
    await settle(tester);
    expect(mailBloc.state.isShowWindow, isTrue);
    expect(dockDots(), findsOneWidget);
    mailBloc.add(ToggleCloseEmailMenu());
    await settle(tester);
    expect(mailBloc.state.isShowWindow, isFalse);
    expect(dockDots(), findsNothing);
  });

  testWidgets('dock icons toggle their own feature windows', (tester) async {
    await pumpDock(tester);

    // Music toggles open with a dot.
    musicBloc.add(ToggleMusicPlayer());
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 400));
    expect(dockDots(), findsOneWidget);

    // Notes asks for the PIN first: still no window, no dot.
    notesBloc.add(ToggleNotesWindow());
    await settle(tester);
    expect(notesBloc.state.isNotesPinVisible, isTrue);
    expect(dockDots(), findsNWidgets(1));

    // Photos PIN gate shows nothing yet either.
    photosBloc.add(TogglePhotosWindow());
    await settle(tester);
    expect(photosBloc.state.isPhotosPinVisible, isTrue);
    expect(dockDots(), findsNWidgets(1));

    // Quiesce the music simulation timer before teardown.
    musicBloc.add(CloseMusicPlayer());
    await settle(tester);
  });
}
