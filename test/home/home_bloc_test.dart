import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jent_web/core/constants/app_images.dart';
import 'package:jent_web/domain/entities/email_message.dart';
import 'package:jent_web/domain/entities/music_track.dart';
import 'package:jent_web/domain/usecases/send_email_usecase.dart';
import 'package:jent_web/presentation/pages/home/home_bloc.dart';
import 'package:jent_web/presentation/pages/home/home_event.dart';
import 'package:jent_web/presentation/pages/home/home_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockSendEmail extends Mock implements SendEmailUseCase {}
class _FakeMessage extends Fake implements EmailMessage {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeMessage()));

  late SendEmailUseCase sendEmail;

  setUp(() => sendEmail = _MockSendEmail());

  HomeBloc buildBloc() => HomeBloc(sendEmail);

  group('wallpaper', () {
    blocTest<HomeBloc, HomeState>(
      'rotates to the next wallpaper',
      build: buildBloc,
      act: (bloc) => bloc.add(NextWallpaper()),
      expect: () => [
        isA<HomeState>()
            .having((s) => s.currentIndex, 'currentIndex', 1)
            .having(
              (s) => s.imagePath,
              'imagePath',
              AppImages.homeBackground[1],
            ),
      ],
    );
  });

  group('mail window toggles derive from state', () {
    blocTest<HomeBloc, HomeState>(
      'opens only once; second open is a no-op',
      build: buildBloc,
      act: (bloc) {
        bloc
          ..add(ToggleOpenEmailMenu())
          ..add(ToggleOpenEmailMenu());
      },
      expect: () => [
        isA<HomeState>()
            .having((s) => s.isShowWindow, 'isShowWindow', true)
            .having(
              (s) => s.isMinimizedWindow,
              'isMinimizedWindow',
              true,
            ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'close then minimize toggle window flags',
      build: buildBloc,
      seed: () => HomeState(
        currentIndex: 0,
        imagePath: AppImages.homeBackground[0],
        isShowWindow: true,
      ),
      act: (bloc) {
        bloc
          ..add(ToggleCloseEmailMenu())
          ..add(ToggleOpenEmailMenu())
          ..add(ToggleMinimizeEmailMenu());
      },
      expect: () => [
        isA<HomeState>().having((s) => s.isShowWindow, 'shown', false),
        isA<HomeState>().having((s) => s.isShowWindow, 'shown', true),
        isA<HomeState>()
            .having((s) => s.isShowWindow, 'shown', false)
            .having((s) => s.isMinimizedWindow, 'minimized', false),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'expand toggles from current state',
      build: buildBloc,
      act: (bloc) {
        bloc
          ..add(ToggleExpandEmailMenu())
          ..add(ToggleExpandEmailMenu());
      },
      expect: () => [
        isA<HomeState>()
            .having((s) => s.isExpandedWindow, 'expanded', true),
        isA<HomeState>()
            .having((s) => s.isExpandedWindow, 'expanded', false),
      ],
    );
  });

  group('send email', () {
    const event = (
      name: 'Ada',
      from: 'ada@mail.com',
      subject: 'Hi',
      body: 'Hello',
    );

    blocTest<HomeBloc, HomeState>(
      'emits sending then sent on success',
      build: () {
        when(() => sendEmail(any())).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        SendEmail(
          name: event.name,
          from: event.from,
          subject: event.subject,
          body: event.body,
        ),
      ),
      expect: () => [
        isA<HomeState>()
            .having((s) => s.emailStatus, 'status', EmailStatus.sending),
        isA<HomeState>()
            .having((s) => s.emailStatus, 'status', EmailStatus.sent),
      ],
      verify: (_) => verify(
        () => sendEmail(
          any(
            that: isA<EmailMessage>()
                .having((m) => m.subject, 'subject', 'Hi')
                .having((m) => m.body, 'body', 'Hello'),
          ),
        ),
      ).called(1),
    );

    blocTest<HomeBloc, HomeState>(
      'emits sending then error on failure',
      build: () {
        when(() => sendEmail(any())).thenThrow(Exception('smtp'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        SendEmail(
          name: event.name,
          from: event.from,
          subject: event.subject,
          body: event.body,
        ),
      ),
      expect: () => [
        isA<HomeState>()
            .having((s) => s.emailStatus, 'status', EmailStatus.sending),
        isA<HomeState>()
            .having((s) => s.emailStatus, 'status', EmailStatus.error),
      ],
    );
  });

  group('music player', () {
    blocTest<HomeBloc, HomeState>(
      'toggling shows the player and starts playback atomically',
      build: buildBloc,
      act: (bloc) => bloc.add(ToggleMusicPlayer()),
      expect: () => [
        isA<HomeState>()
            .having((s) => s.isShowMusicPlayer, 'shown', true)
            .having((s) => s.isMusicPlaying, 'playing', true)
            .having((s) => s.isMusicMinimized, 'minimized', false)
            .having((s) => s.isMusicExpanded, 'expanded', false),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'toggling twice hides the player but keeps playback state',
      build: buildBloc,
      act: (bloc) {
        bloc
          ..add(ToggleMusicPlayer())
          ..add(ToggleMusicPlayer());
      },
      expect: () => [
        isA<HomeState>()
            .having((s) => s.isShowMusicPlayer, 'shown', true)
            .having((s) => s.isMusicPlaying, 'playing', true),
        isA<HomeState>()
            .having((s) => s.isShowMusicPlayer, 'shown', false)
            .having((s) => s.isMusicPlaying, 'playing', true),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'minimize collapses to the mini bar, reshow restores the card',
      build: buildBloc,
      act: (bloc) {
        bloc
          ..add(ToggleMusicPlayer())
          ..add(MinimizeMusicPlayer())
          ..add(ToggleMusicPlayer());
      },
      expect: () => [
        isA<HomeState>()
            .having((s) => s.isShowMusicPlayer, 'shown', true),
        isA<HomeState>()
            .having((s) => s.isShowMusicPlayer, 'shown', false)
            .having((s) => s.isMusicMinimized, 'minimized', true),
        isA<HomeState>()
            .having((s) => s.isShowMusicPlayer, 'shown', true)
            .having((s) => s.isMusicMinimized, 'minimized', false),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'expand toggles the full-page playlist view',
      build: buildBloc,
      act: (bloc) {
        bloc
          ..add(ToggleMusicPlayer())
          ..add(ExpandMusicPlayer())
          ..add(ExpandMusicPlayer());
      },
      expect: () => [
        isA<HomeState>()
            .having((s) => s.isShowMusicPlayer, 'shown', true),
        isA<HomeState>()
            .having((s) => s.isMusicExpanded, 'expanded', true),
        isA<HomeState>()
            .having((s) => s.isMusicExpanded, 'expanded', false),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'close stops playback and resets position',
      build: buildBloc,
      seed: () => HomeState(
        currentIndex: 0,
        imagePath: AppImages.homeBackground[0],
        isShowMusicPlayer: true,
        isMusicPlaying: true,
        musicPosition: const Duration(seconds: 42),
      ),
      act: (bloc) => bloc.add(CloseMusicPlayer()),
      expect: () => [
        isA<HomeState>()
            .having((s) => s.isShowMusicPlayer, 'shown', false)
            .having((s) => s.isMusicPlaying, 'playing', false)
            .having((s) => s.musicPosition, 'pos', Duration.zero),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'selecting a track starts it and restores the card',
      build: buildBloc,
      seed: () => HomeState(
        currentIndex: 0,
        imagePath: AppImages.homeBackground[0],
        isShowMusicPlayer: false,
        isMusicMinimized: true,
        isMusicPlaying: true,
      ),
      act: (bloc) => bloc.add(SelectMusicTrack(2)),
      expect: () => [
        isA<HomeState>()
            .having((s) => s.musicTrackIndex, 'track', 2)
            .having((s) => s.musicPosition, 'pos', Duration.zero)
            .having((s) => s.isShowMusicPlayer, 'shown', true)
            .having((s) => s.isMusicMinimized, 'minimized', false),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'ignores out-of-range track selection',
      build: buildBloc,
      act: (bloc) => bloc.add(SelectMusicTrack(99)),
      expect: () => [],
    );

    blocTest<HomeBloc, HomeState>(
      'restart position when previous is hit early in a track',
      build: buildBloc,
      seed: () => HomeState(
        currentIndex: 0,
        imagePath: AppImages.homeBackground[0],
        musicTrackIndex: 1,
        musicPosition: const Duration(seconds: 10),
      ),
      act: (bloc) => bloc.add(PreviousMusicTrack()),
      expect: () => [
        isA<HomeState>()
            .having((s) => s.musicTrackIndex, 'track', 1)
            .having((s) => s.musicPosition, 'pos', Duration.zero),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'advances to the next track at the end of the duration',
      build: buildBloc,
      act: (bloc) => bloc.add(
        MusicProgressTicked(
          MusicPlaylist.tracks[0].duration + const Duration(seconds: 1),
        ),
      ),
      expect: () => [
        isA<HomeState>()
            .having((s) => s.musicTrackIndex, 'track', 1)
            .having((s) => s.musicPosition, 'pos', Duration.zero),
      ],
    );
  });
}
