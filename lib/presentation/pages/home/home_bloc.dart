import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:jent_web/domain/entities/email_message.dart';
import 'package:jent_web/domain/entities/music_track.dart';
import 'package:jent_web/domain/usecases/send_email_usecase.dart';
import 'package:jent_web/presentation/pages/home/home_event.dart';
import 'package:jent_web/presentation/pages/home/home_state.dart';
import 'package:jent_web/core/constants/app_images.dart';

@injectable
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  Timer? _timer;
  Timer? _musicTimer;

  final List<String> images = AppImages.homeBackground;
  final SendEmailUseCase _sendEmail;

  HomeBloc(this._sendEmail)
    : super(
        HomeState(currentIndex: 0, imagePath: AppImages.homeBackground[0]),
      ) {
    on<StartWallpaperRotation>(_onStart);
    on<NextWallpaper>(_onNext);
    on<ToggleOpenEmailMenu>(_onToggleEmailMenu);
    on<ToggleCloseEmailMenu>(_onToggleCloseEmailMenu);
    on<ToggleMinimizeEmailMenu>(_onToggleMinimizeEmailMenu);
    on<ToggleExpandEmailMenu>(_onToggleExpandEmailMenu);
    on<ToggleMusicPlayer>(_onToggleMusicPlayer);
    on<CloseMusicPlayer>(_onCloseMusicPlayer);
    on<MinimizeMusicPlayer>(_onMinimizeMusicPlayer);
    on<ExpandMusicPlayer>(_onExpandMusicPlayer);
    on<SelectMusicTrack>(_onSelectMusicTrack);
    on<ToggleMusicPlayback>(_onToggleMusicPlayback);
    on<NextMusicTrack>(_onNextTrack);
    on<PreviousMusicTrack>(_onPreviousTrack);
    on<MusicProgressTicked>(_onProgressTicked);
    on<SendEmail>(_onSendEmail);
  }

  void _onStart(StartWallpaperRotation event, Emitter<HomeState> emit) {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => add(NextWallpaper()),
    );
  }

  void _onNext(NextWallpaper event, Emitter<HomeState> emit) {
    final nextIndex = (state.currentIndex + 1) % images.length;

    emit(state.copyWith(currentIndex: nextIndex, imagePath: images[nextIndex]));
  }

  void _onToggleEmailMenu(ToggleOpenEmailMenu event, Emitter<HomeState> emit) {
    if (state.isShowWindow) return;

    emit(state.copyWith(isShowWindow: true, isMinimizedWindow: true));
  }

  void _onToggleCloseEmailMenu(
    ToggleCloseEmailMenu event,
    Emitter<HomeState> emit,
  ) {
    if (!state.isShowWindow) return;

    emit(state.copyWith(isShowWindow: false, isMinimizedWindow: true));
  }

  void _onToggleMinimizeEmailMenu(
    ToggleMinimizeEmailMenu event,
    Emitter<HomeState> emit,
  ) {
    if (!state.isShowWindow) return;

    emit(state.copyWith(isMinimizedWindow: false, isShowWindow: false));
  }

  void _onToggleExpandEmailMenu(
    ToggleExpandEmailMenu event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(isExpandedWindow: !state.isExpandedWindow));
  }

  void _onToggleMusicPlayer(ToggleMusicPlayer event, Emitter<HomeState> emit) {
    final show = !state.isShowMusicPlayer;
    if (show) {
      emit(
        state.copyWith(
          isShowMusicPlayer: true,
          isMusicMinimized: false,
          isMusicExpanded: false,
          isMusicPlaying: true,
        ),
      );
      _startMusicTimer();
    } else {
      emit(state.copyWith(isShowMusicPlayer: false));
    }
  }

  void _onCloseMusicPlayer(CloseMusicPlayer event, Emitter<HomeState> emit) {
    _musicTimer?.cancel();
    emit(
      state.copyWith(
        isShowMusicPlayer: false,
        isMusicMinimized: false,
        isMusicExpanded: false,
        isMusicPlaying: false,
        musicPosition: Duration.zero,
      ),
    );
  }

  void _onMinimizeMusicPlayer(
    MinimizeMusicPlayer event,
    Emitter<HomeState> emit,
  ) {
    emit(
      state.copyWith(
        isShowMusicPlayer: false,
        isMusicMinimized: true,
        isMusicExpanded: false,
      ),
    );
  }

  void _onExpandMusicPlayer(ExpandMusicPlayer event, Emitter<HomeState> emit) {
    emit(state.copyWith(isMusicExpanded: !state.isMusicExpanded));
  }

  void _onSelectMusicTrack(SelectMusicTrack event, Emitter<HomeState> emit) {
    if (event.index < 0 || event.index >= MusicPlaylist.tracks.length) return;
    emit(
      state.copyWith(
        musicTrackIndex: event.index,
        musicPosition: Duration.zero,
        isMusicPlaying: true,
        isShowMusicPlayer: true,
        isMusicMinimized: false,
      ),
    );
    _startMusicTimer();
  }

  void _onToggleMusicPlayback(
    ToggleMusicPlayback event,
    Emitter<HomeState> emit,
  ) {
    final playing = !state.isMusicPlaying;
    emit(state.copyWith(isMusicPlaying: playing));
    _musicTimer?.cancel();
    if (playing) _startMusicTimer();
  }

  void _startMusicTimer() {
    _musicTimer?.cancel();
    _musicTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(MusicProgressTicked(state.musicPosition + _tick)),
    );
  }

  void _onNextTrack(NextMusicTrack event, Emitter<HomeState> emit) {
    final next = (state.musicTrackIndex + 1) % MusicPlaylist.tracks.length;
    emit(state.copyWith(musicTrackIndex: next, musicPosition: Duration.zero));
  }

  void _onPreviousTrack(PreviousMusicTrack event, Emitter<HomeState> emit) {
    if (state.musicPosition > const Duration(seconds: 3)) {
      emit(state.copyWith(musicPosition: Duration.zero));
      return;
    }
    final previous =
        (state.musicTrackIndex - 1 + MusicPlaylist.tracks.length) %
        MusicPlaylist.tracks.length;
    emit(
      state.copyWith(musicTrackIndex: previous, musicPosition: Duration.zero),
    );
  }

  void _onProgressTicked(MusicProgressTicked event, Emitter<HomeState> emit) {
    final duration = MusicPlaylist.tracks[state.musicTrackIndex].duration;
    if (event.position >= duration) {
      final next = (state.musicTrackIndex + 1) % MusicPlaylist.tracks.length;
      emit(state.copyWith(musicTrackIndex: next, musicPosition: Duration.zero));
      return;
    }
    emit(state.copyWith(musicPosition: event.position));
  }

  static const _tick = Duration(seconds: 1);

  Future<void> _onSendEmail(SendEmail event, Emitter<HomeState> emit) async {
    emit(state.copyWith(emailStatus: EmailStatus.sending));
    try {
      await _sendEmail(
        EmailMessage(
          name: event.name,
          from: event.from,
          subject: event.subject,
          body: event.body,
        ),
      );
      emit(state.copyWith(emailStatus: EmailStatus.sent));
    } catch (_) {
      emit(state.copyWith(emailStatus: EmailStatus.error));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _musicTimer?.cancel();
    return super.close();
  }
}
