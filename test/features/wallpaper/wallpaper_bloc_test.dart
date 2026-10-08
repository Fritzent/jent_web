import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jent_web/core/constants/app_images.dart';
import 'package:jent_web/features/wallpaper/bloc/wallpaper_bloc.dart';
import 'package:jent_web/features/wallpaper/bloc/wallpaper_event.dart';
import 'package:jent_web/features/wallpaper/bloc/wallpaper_state.dart';

void main() {
  WallpaperBloc buildBloc() => WallpaperBloc();

  group('wallpaper', () {
    blocTest<WallpaperBloc, WallpaperState>(
      'rotates to the next wallpaper',
      build: buildBloc,
      act: (bloc) => bloc.add(NextWallpaper()),
      expect: () => [
        isA<WallpaperState>()
            .having((s) => s.currentIndex, 'currentIndex', 1)
            .having(
              (s) => s.imagePath,
              'imagePath',
              AppImages.homeBackground[1],
            ),
      ],
    );
  });

}
