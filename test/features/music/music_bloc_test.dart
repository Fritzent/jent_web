import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jent_web/domain/entities/music_track.dart';
import 'package:jent_web/domain/entities/spotify_track.dart';
import 'package:jent_web/domain/repositories/spotify_repository.dart';
import 'package:jent_web/domain/usecases/spotify_usecases.dart';
import 'package:jent_web/features/music/bloc/music_bloc.dart';
import 'package:jent_web/features/music/bloc/music_event.dart';
import 'package:jent_web/features/music/bloc/music_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockSpotify extends Mock implements SpotifyRepository {}
class _MockSearchTracks extends Mock implements SearchTracks {}
class _MockPlayTrack extends Mock implements PlaySpotifyTrack {}

void main() {
  late SpotifyRepository spotify;
  late SearchTracks searchTracks;
  late PlaySpotifyTrack playTrack;

  Stream<SpotifyPlayerState> playerStream(SpotifyPlayerState value) =>
      Stream.value(value);

  setUp(() {
    spotify = _MockSpotify();
    searchTracks = _MockSearchTracks();
    playTrack = _MockPlayTrack();
    when(
      () => spotify.statusStream,
    ).thenAnswer((_) => const Stream<SpotifyStatus>.empty());
    when(
      () => spotify.playerState,
    ).thenAnswer((_) => const Stream<SpotifyPlayerState>.empty());
    when(() => spotify.status).thenReturn(SpotifyStatus.disconnected);
    when(() => spotify.ensureConnected()).thenAnswer((_) async {});
    when(
      () => spotify.getPlaylistTracks(any()),
    ).thenAnswer((_) async => const []);
  });

  MusicBloc buildBloc() =>
      MusicBloc(spotify, searchTracks, playTrack);

  group('music player', () {
    blocTest<MusicBloc, MusicState>(
      'toggling shows the player, starts playback and connects Spotify',
      build: buildBloc,
      act: (bloc) => bloc.add(ToggleMusicPlayer()),
      expect: () => [
        isA<MusicState>()
            .having((s) => s.isShowMusicPlayer, 'shown', true)
            .having((s) => s.isMusicPlaying, 'playing', true)
            .having((s) => s.isMusicMinimized, 'minimized', false)
            .having((s) => s.isMusicExpanded, 'expanded', false),
        isA<MusicState>().having(
          (s) => s.spotifyStatus,
          'spotify',
          SpotifyStatus.connecting,
        ),
        isA<MusicState>()
            .having(
              (s) => s.spotifyTracks,
              'tracks',
              isEmpty,
            )
            .having(
              (s) => s.spotifyStatus,
              'spotify',
              SpotifyStatus.ready,
            ),
      ],
      verify: (_) {
        verify(() => spotify.ensureConnected()).called(1);
        verify(() => spotify.getPlaylistTracks('')).called(1);
      },
    );

    blocTest<MusicBloc, MusicState>(
      'toggling twice hides the player but keeps playback state',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(ToggleMusicPlayer());
        await Future<void>.delayed(Duration.zero);
        bloc.add(ToggleMusicPlayer());
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<MusicState>()
            .having((s) => s.isShowMusicPlayer, 'shown', true)
            .having((s) => s.isMusicPlaying, 'playing', true),
        isA<MusicState>().having(
          (s) => s.spotifyStatus,
          'spotify',
          SpotifyStatus.connecting,
        ),
        isA<MusicState>().having(
          (s) => s.spotifyStatus,
          'spotify',
          SpotifyStatus.ready,
        ),
        isA<MusicState>()
            .having((s) => s.isShowMusicPlayer, 'shown', false)
            .having((s) => s.isMusicPlaying, 'playing', true),
      ],
    );

    blocTest<MusicBloc, MusicState>(
      'minimize collapses to the mini bar, reshow restores the card',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(ToggleMusicPlayer());
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(MinimizeMusicPlayer())
          ..add(ToggleMusicPlayer());
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<MusicState>()
            .having((s) => s.isShowMusicPlayer, 'shown', true),
        isA<MusicState>().having(
          (s) => s.spotifyStatus,
          'spotify',
          SpotifyStatus.connecting,
        ),
        isA<MusicState>().having(
          (s) => s.spotifyStatus,
          'spotify',
          SpotifyStatus.ready,
        ),
        isA<MusicState>()
            .having((s) => s.isShowMusicPlayer, 'shown', false)
            .having((s) => s.isMusicMinimized, 'minimized', true),
        isA<MusicState>()
            .having((s) => s.isShowMusicPlayer, 'shown', true)
            .having((s) => s.isMusicMinimized, 'minimized', false),
      ],
    );

    blocTest<MusicBloc, MusicState>(
      'expand toggles the full-page playlist view',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(ToggleMusicPlayer());
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(ExpandMusicPlayer())
          ..add(ExpandMusicPlayer());
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<MusicState>()
            .having((s) => s.isShowMusicPlayer, 'shown', true),
        isA<MusicState>().having(
          (s) => s.spotifyStatus,
          'spotify',
          SpotifyStatus.connecting,
        ),
        isA<MusicState>().having(
          (s) => s.spotifyStatus,
          'spotify',
          SpotifyStatus.ready,
        ),
        isA<MusicState>()
            .having((s) => s.isMusicExpanded, 'expanded', true),
        isA<MusicState>()
            .having((s) => s.isMusicExpanded, 'expanded', false),
      ],
    );

    blocTest<MusicBloc, MusicState>(
      'close stops playback and resets position',
      build: buildBloc,
      seed: () => MusicState(
        isShowMusicPlayer: true,
        isMusicPlaying: true,
        musicPosition: const Duration(seconds: 42),
      ),
      act: (bloc) => bloc.add(CloseMusicPlayer()),
      expect: () => [
        isA<MusicState>()
            .having((s) => s.isShowMusicPlayer, 'shown', false)
            .having((s) => s.isMusicPlaying, 'playing', false)
            .having((s) => s.musicPosition, 'pos', Duration.zero),
      ],
    );

    blocTest<MusicBloc, MusicState>(
      'selecting a track starts it and restores the card',
      build: buildBloc,
      seed: () => MusicState(
        isShowMusicPlayer: false,
        isMusicMinimized: true,
        isMusicPlaying: true,
      ),
      act: (bloc) => bloc.add(SelectMusicTrack(2)),
      expect: () => [
        isA<MusicState>()
            .having((s) => s.musicTrackIndex, 'track', 2)
            .having((s) => s.musicPosition, 'pos', Duration.zero)
            .having((s) => s.isShowMusicPlayer, 'shown', true)
            .having((s) => s.isMusicMinimized, 'minimized', false),
      ],
    );

    blocTest<MusicBloc, MusicState>(
      'ignores out-of-range track selection',
      build: buildBloc,
      act: (bloc) => bloc.add(SelectMusicTrack(99)),
      expect: () => [],
    );

    blocTest<MusicBloc, MusicState>(
      'connect failure falls back to simulation with error status',
      build: () {
        when(
          () => spotify.ensureConnected(),
        ).thenThrow(Exception('no token'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(ToggleMusicPlayer()),
      expect: () => [
        isA<MusicState>()
            .having((s) => s.isShowMusicPlayer, 'shown', true)
            .having((s) => s.isMusicPlaying, 'playing', true),
        isA<MusicState>().having(
          (s) => s.spotifyStatus,
          'spotify',
          SpotifyStatus.connecting,
        ),
        isA<MusicState>().having(
          (s) => s.spotifyStatus,
          'spotify',
          SpotifyStatus.error,
        ),
      ],
    );

    blocTest<MusicBloc, MusicState>(
      'loaded Spotify tracks replace the fallback list and autoplay first',
      build: () {
        const tracks = [
          SpotifyTrack(
            id: 'abc',
            title: 'Real Song',
            artist: 'Real Artist',
            artworkUrl: 'https://img/x.jpg',
            duration: Duration(minutes: 3),
          ),
        ];
        when(
          () => spotify.getPlaylistTracks(any()),
        ).thenAnswer((_) async => tracks);
        when(
          () => playTrack(any()),
        ).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(ToggleMusicPlayer()),
      expect: () => [
        isA<MusicState>()
            .having((s) => s.isShowMusicPlayer, 'shown', true),
        isA<MusicState>().having(
          (s) => s.spotifyStatus,
          'spotify',
          SpotifyStatus.connecting,
        ),
        isA<MusicState>()
            .having((s) => s.spotifyTracks, 'tracks', hasLength(1))
            .having(
              (s) => s.spotifyStatus,
              'spotify',
              SpotifyStatus.ready,
            )
            .having((s) => s.musicTrackIndex, 'track', 0)
            .having((s) => s.musicPosition, 'pos', Duration.zero),
        isA<MusicState>().having((s) => s.isMusicPlaying, 'playing', true),
      ],
      verify: (_) => verify(() => playTrack('abc')).called(1),
    );

    blocTest<MusicBloc, MusicState>(
      'empty Spotify list keeps fallback without autoplay',
      build: () {
        when(
          () => spotify.getPlaylistTracks(any()),
        ).thenAnswer((_) async => const []);
        return buildBloc();
      },
      act: (bloc) => bloc.add(ToggleMusicPlayer()),
      expect: () => [
        isA<MusicState>()
            .having((s) => s.isShowMusicPlayer, 'shown', true),
        isA<MusicState>().having(
          (s) => s.spotifyStatus,
          'spotify',
          SpotifyStatus.connecting,
        ),
        isA<MusicState>()
            .having((s) => s.spotifyTracks, 'tracks', isEmpty)
            .having(
              (s) => s.spotifyStatus,
              'spotify',
              SpotifyStatus.ready,
            ),
      ],
      verify: (_) => verifyNever(() => playTrack(any())),
    );

    blocTest<MusicBloc, MusicState>(
      'search emits results',
      build: () {
        const results = [
          SpotifyTrack(
            id: 'xyz',
            title: 'Found',
            artist: 'Someone',
            artworkUrl: '',
            duration: Duration(minutes: 2),
          ),
        ];
        when(
          () => searchTracks(any()),
        ).thenAnswer((_) async => results);
        return buildBloc();
      },
      act: (bloc) => bloc.add(SpotifySearchRequested('hello')),
      expect: () => [
        isA<MusicState>()
            .having((s) => s.spotifyQuery, 'query', 'hello')
            .having((s) => s.spotifySearching, 'searching', true),
        isA<MusicState>()
            .having((s) => s.spotifySearchResults, 'results', hasLength(1))
            .having((s) => s.spotifySearching, 'searching', false),
      ],
      verify: (_) => verify(() => searchTracks('hello')).called(1),
    );

    blocTest<MusicBloc, MusicState>(
      'empty query clears results immediately',
      build: buildBloc,
      seed: () => MusicState(
        spotifySearchResults: const [
          SpotifyTrack(
            id: 'xyz',
            title: 'Found',
            artist: 'Someone',
            artworkUrl: '',
            duration: Duration(minutes: 2),
          ),
        ],
      ),
      act: (bloc) => bloc.add(SpotifySearchRequested('   ')),
      expect: () => [
        isA<MusicState>()
            .having((s) => s.spotifyQuery, 'query', '   ')
            .having((s) => s.spotifySearching, 'searching', false)
            .having((s) => s.spotifySearchResults, 'results', isEmpty),
      ],
      verify: (_) => verifyNever(() => searchTracks(any())),
    );

    blocTest<MusicBloc, MusicState>(
      'playing a Spotify track delegates to the repository',
      build: () {
        when(
          () => playTrack(any()),
        ).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(SpotifyPlayTrack('abc123')),
      expect: () => [],
      verify: (_) => verify(() => playTrack('abc123')).called(1),
    );

    blocTest<MusicBloc, MusicState>(
      'real player state drives playing flag and position',
      build: () {
        when(() => spotify.playerState).thenAnswer(
          (_) => playerStream(
            const SpotifyPlayerState(
              isPlaying: true,
              trackId: 'abc',
              position: Duration(seconds: 30),
              duration: Duration(minutes: 3),
            ),
          ),
        );
        return buildBloc();
      },
      seed: () => MusicState(
        spotifyStatus: SpotifyStatus.ready,
        spotifyTracks: const [
          SpotifyTrack(
            id: 'abc',
            title: 'Real Song',
            artist: 'Real Artist',
            artworkUrl: '',
            duration: Duration(minutes: 3),
          ),
        ],
      ),
      expect: () => [
        isA<MusicState>()
            .having((s) => s.isMusicPlaying, 'playing', true)
            .having((s) => s.musicPosition, 'pos', const Duration(seconds: 30))
            .having((s) => s.musicTrackIndex, 'track', 0),
      ],
    );

    blocTest<MusicBloc, MusicState>(
      'transport uses Spotify when connected',
      build: () {
        when(() => spotify.togglePlayback()).thenAnswer((_) async {});
        when(() => spotify.nextTrack()).thenAnswer((_) async {});
        when(() => spotify.previousTrack()).thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => MusicState(
        spotifyStatus: SpotifyStatus.ready,
        spotifyTracks: const [
          SpotifyTrack(
            id: 'abc',
            title: 'Real Song',
            artist: 'Real Artist',
            artworkUrl: '',
            duration: Duration(minutes: 3),
          ),
        ],
      ),
      act: (bloc) {
        bloc
          ..add(ToggleMusicPlayback())
          ..add(NextMusicTrack())
          ..add(PreviousMusicTrack());
      },
      expect: () => [],
      verify: (_) {
        verify(() => spotify.togglePlayback()).called(1);
        verify(() => spotify.nextTrack()).called(1);
        verify(() => spotify.previousTrack()).called(1);
      },
    );

    blocTest<MusicBloc, MusicState>(
      'restart position when previous is hit early in a track',
      build: buildBloc,
      seed: () => MusicState(
        musicTrackIndex: 1,
        musicPosition: const Duration(seconds: 10),
      ),
      act: (bloc) => bloc.add(PreviousMusicTrack()),
      expect: () => [
        isA<MusicState>()
            .having((s) => s.musicTrackIndex, 'track', 1)
            .having((s) => s.musicPosition, 'pos', Duration.zero),
      ],
    );

    blocTest<MusicBloc, MusicState>(
      'advances to the next track at the end of the duration',
      build: buildBloc,
      act: (bloc) => bloc.add(
        MusicProgressTicked(
          MusicPlaylist.tracks[0].duration + const Duration(seconds: 1),
        ),
      ),
      expect: () => [
        isA<MusicState>()
            .having((s) => s.musicTrackIndex, 'track', 1)
            .having((s) => s.musicPosition, 'pos', Duration.zero),
      ],
    );
  
  });
}
