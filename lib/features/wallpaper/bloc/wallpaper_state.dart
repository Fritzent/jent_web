import 'package:jent_web/core/constants/app_images.dart';

class WallpaperState {
  final int currentIndex;
  final String imagePath;

  const WallpaperState({
    required this.currentIndex,
    required this.imagePath,
  });

  factory WallpaperState.initial() => WallpaperState(
        currentIndex: 0,
        imagePath: AppImages.homeBackground[0],
      );

  WallpaperState copyWith({
    int? currentIndex,
    String? imagePath,
  }) {
    return WallpaperState(
      currentIndex: currentIndex ?? this.currentIndex,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
