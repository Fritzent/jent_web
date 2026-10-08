import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jent_web/core/widgets/dock/dock_widget.dart';
import 'package:jent_web/data/datasources/notes_remote_datasource.dart';
import 'package:jent_web/domain/entities/email_message.dart';
import 'package:jent_web/domain/entities/spotify_track.dart';
import 'package:jent_web/domain/repositories/email_repository.dart';
import 'package:jent_web/domain/repositories/spotify_repository.dart';
import 'package:jent_web/domain/usecases/send_email_usecase.dart';
import 'package:jent_web/domain/usecases/spotify_usecases.dart';
import 'package:jent_web/features/mail/bloc/mail_bloc.dart';
import 'package:jent_web/features/mail/bloc/mail_event.dart';
import 'package:jent_web/features/music/bloc/music_bloc.dart';
import 'package:jent_web/features/music/bloc/music_event.dart';
import 'package:jent_web/features/notes/bloc/notes_bloc.dart';
import 'package:jent_web/features/notes/bloc/notes_event.dart';
import 'package:jent_web/features/photos/bloc/photos_bloc.dart';
import 'package:jent_web/features/photos/bloc/photos_event.dart';
import 'package:jent_web/gen/assets.gen.dart';
import 'package:jent_web/l10n/app_localizations.dart';

/// Desktop dock. Each entry reads its own feature bloc, so the dot
/// reflects that window's open/minimized state.
class HomeDock extends StatelessWidget {
  const HomeDock({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final mailActive = context.select<MailBloc, bool>(
      (b) => b.state.isShowWindow || b.state.isMinimizedWindow,
    );
    final notesActive = context.select<NotesBloc, bool>(
      (b) => b.state.isShowNotesWindow || b.state.isNotesMinimized,
    );
    final musicActive = context.select<MusicBloc, bool>(
      (b) => b.state.isShowMusicPlayer || b.state.isMusicMinimized,
    );
    final photosActive = context.select<PhotosBloc, bool>(
      (b) => b.state.isShowPhotosWindow || b.state.isPhotosMinimized,
    );
    final mailOpen = context.select<MailBloc, bool>(
      (b) => b.state.isShowWindow,
    );

    return DockWidget(
      icons: [
        Assets.icFinder.image(
          key: const ValueKey('dock-icon-finder'),
          width: 28,
          height: 28,
        ),
        Assets.icEmail.image(
          key: const ValueKey('dock-icon-email'),
          width: 28,
          height: 28,
        ),
        Assets.icNotes.image(
          key: const ValueKey('dock-icon-notes'),
          width: 28,
          height: 28,
        ),
        Assets.icMusic.image(
          key: const ValueKey('dock-icon-music'),
          width: 28,
          height: 28,
        ),
        Assets.icPhotos.image(
          key: const ValueKey('dock-icon-photos'),
          width: 28,
          height: 28,
        ),
        Assets.icSpotLight.image(
          key: const ValueKey('dock-icon-spotlight'),
          width: 28,
          height: 28,
        ),
      ],
      tooltips: [
        localizations.textFinder,
        localizations.textEmail,
        localizations.textNotes,
        localizations.textMusic,
        localizations.textPhotos,
        localizations.textSpotlight,
      ],
      listDockMinimized: [
        false,
        mailActive,
        notesActive,
        musicActive,
        photosActive,
        false,
      ],
      onIconTapped: (int p1) {
        if (p1 == 1) {
          if (mailOpen) {
            context.read<MailBloc>().add(ToggleCloseEmailMenu());
          } else {
            context.read<MailBloc>().add(ToggleOpenEmailMenu());
          }
        } else if (p1 == 2) {
          context.read<NotesBloc>().add(ToggleNotesWindow());
        } else if (p1 == 3) {
          context.read<MusicBloc>().add(ToggleMusicPlayer());
        } else if (p1 == 4) {
          context.read<PhotosBloc>().add(TogglePhotosWindow());
        }
      },
    );
  }
}

/// No-op email repository so the dock preview never touches the network.
class _PreviewEmailRepository implements EmailRepository {
  @override
  Future<void> send(EmailMessage message) async {}
}

/// Disconnected Spotify stub with empty streams so the preview stays
/// hermetic (no native plugins, no `dart:io`, no timers at startup).
class _PreviewSpotifyRepository implements SpotifyRepository {
  @override
  Future<void> ensureConnected() async {}

  @override
  Future<List<SpotifyTrack>> getPlaylistTracks(String playlistId) async =>
      const [];

  @override
  Future<List<SpotifyTrack>> searchTracks(String query) async => const [];

  @override
  Future<void> playTrack(String trackId) async {}

  @override
  Future<void> togglePlayback() async {}

  @override
  Future<void> nextTrack() async {}

  @override
  Future<void> previousTrack() async {}

  @override
  Stream<SpotifyPlayerState> get playerState => const Stream.empty();

  @override
  SpotifyStatus get status => SpotifyStatus.disconnected;

  @override
  Stream<SpotifyStatus> get statusStream => const Stream.empty();

  @override
  String? get lastError => null;

  @override
  String? get accountSummary => null;

  @override
  String? get effectivePlaylistId => null;

  @override
  void clearError() {}
}

Widget _homeDockPreviewRoot({
  required MailBloc mailBloc,
  required NotesBloc notesBloc,
  required MusicBloc musicBloc,
  required PhotosBloc photosBloc,
}) {
  return MaterialApp(
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
        body: Align(alignment: Alignment.bottomCenter, child: HomeDock()),
      ),
    ),
  );
}

MusicBloc _previewMusicBloc(_PreviewSpotifyRepository spotify) =>
    MusicBloc(spotify, SearchTracks(spotify), PlaySpotifyTrack(spotify));

@Preview(name: 'HomeDock - idle', group: 'Dock', size: Size(700, 200))
Widget homeDockIdlePreview() {
  final spotify = _PreviewSpotifyRepository();
  return _homeDockPreviewRoot(
    mailBloc: MailBloc(SendEmailUseCase(_PreviewEmailRepository())),
    notesBloc: NotesBloc(NotesRemoteDataSource()),
    musicBloc: _previewMusicBloc(spotify),
    photosBloc: PhotosBloc(),
  );
}

@Preview(name: 'HomeDock - mail running', group: 'Dock', size: Size(700, 200))
Widget homeDockRunningPreview() {
  final spotify = _PreviewSpotifyRepository();
  return _homeDockPreviewRoot(
    mailBloc: MailBloc(SendEmailUseCase(_PreviewEmailRepository()))
      ..add(ToggleOpenEmailMenu()),
    notesBloc: NotesBloc(NotesRemoteDataSource()),
    musicBloc: _previewMusicBloc(spotify),
    photosBloc: PhotosBloc(),
  );
}
