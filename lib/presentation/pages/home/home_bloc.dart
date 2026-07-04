import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jent_web/presentation/pages/home/home_event.dart';
import 'package:jent_web/presentation/pages/home/home_state.dart';
import 'package:jent_web/source/constants/app_images.dart';

class HomeBloc
    extends Bloc<HomeEvent, HomeState> {
  Timer? _timer;
  bool _showWindow = false;
  bool _isExpandedWindow = false;
  bool _isMinimizedWindow = false;

  final List<String> images = AppImages.homeBackground;

  HomeBloc()
      : super(
          HomeState(
            currentIndex: 0,
            imagePath: AppImages.homeBackground[0],
          ),
        ) {
    on<StartWallpaperRotation>(_onStart);
    on<NextWallpaper>(_onNext);
    on<ToggleOpenEmailMenu>(_onToggleEmailMenu);
    on<ToggleCloseEmailMenu>(_onToggleCloseEmailMenu);
    on<ToggleMinimizeEmailMenu>(_onToggleMinimizeEmailMenu);
    on<ToggleExpandEmailMenu>(_onToggleExpandEmailMenu);
  }

  void _onStart(
    StartWallpaperRotation event,
    Emitter<HomeState> emit,
  ) {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => add(NextWallpaper()),
    );
  }

  void _onNext(
    NextWallpaper event,
    Emitter<HomeState> emit,
  ) {
    final nextIndex =
        (state.currentIndex + 1) % images.length;

    emit(
      state.copyWith(
        currentIndex: nextIndex,
        imagePath: images[nextIndex],
      ),
    );
  }

  void _onToggleEmailMenu(
    ToggleOpenEmailMenu event,
    Emitter<HomeState> emit,
  ) {
     if (_showWindow) return;

    _showWindow = true;

    _isMinimizedWindow = true;

    emit(
      state.copyWith(
        isShowWindow: _showWindow,
        isMinimizedWindow: _isMinimizedWindow,
      ),
    );
  }

  void _onToggleCloseEmailMenu(
    ToggleCloseEmailMenu event,
    Emitter<HomeState> emit,
  ) {
    if (!_showWindow) return;

    _showWindow = false;

    _isMinimizedWindow = true;

    emit(
      state.copyWith(
        isShowWindow: _showWindow,
        isMinimizedWindow: _isMinimizedWindow,
      ),
    );
  }

  void _onToggleMinimizeEmailMenu(
    ToggleMinimizeEmailMenu event,
    Emitter<HomeState> emit,
  ) {
    if (!_showWindow) return;

    _showWindow = false;

    _isMinimizedWindow = false;
    emit(
      state.copyWith(
        isMinimizedWindow: _isMinimizedWindow,
        isShowWindow: _showWindow,
      ),
    );
  }

  void _onToggleExpandEmailMenu(
    ToggleExpandEmailMenu event,
    Emitter<HomeState> emit,
  ) {
    _isExpandedWindow = !_isExpandedWindow;
    emit(
      state.copyWith(
        isExpandedWindow: _isExpandedWindow,
      ),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}