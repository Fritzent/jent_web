import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:jent_web/core/constants/app_images.dart';
import 'package:jent_web/features/wallpaper/bloc/wallpaper_event.dart';
import 'package:jent_web/features/wallpaper/bloc/wallpaper_state.dart';

@injectable
class WallpaperBloc extends Bloc<WallpaperEvent, WallpaperState> {
  Timer? _timer;

  final List<String> images = AppImages.homeBackground;

  WallpaperBloc() : super(WallpaperState.initial()) {
    on<StartWallpaperRotation>(_onStart);
    on<NextWallpaper>(_onNext);
  }

  void _onStart(StartWallpaperRotation event, Emitter<WallpaperState> emit) {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => add(NextWallpaper()),
    );
  }

  void _onNext(NextWallpaper event, Emitter<WallpaperState> emit) {
    final nextIndex = (state.currentIndex + 1) % images.length;

    emit(state.copyWith(currentIndex: nextIndex, imagePath: images[nextIndex]));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
