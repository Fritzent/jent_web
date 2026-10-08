import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jent_web/core/widgets/background/animated_background.dart';
import 'package:jent_web/features/wallpaper/bloc/wallpaper_bloc.dart';
import 'package:jent_web/features/wallpaper/bloc/wallpaper_event.dart';
import 'package:jent_web/features/wallpaper/bloc/wallpaper_state.dart';

class HomeBackground extends StatelessWidget {
  const HomeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final images = context.read<WallpaperBloc>().images;
    return BlocSelector<WallpaperBloc, WallpaperState, int>(
      selector: (state) => state.currentIndex,
      builder: (context, currentIndex) {
        return PremiumAnimatedBackground(
          imagePaths: images,
          currentIndex: currentIndex,
          child: const SizedBox(),
        );
      },
    );
  }
}

/// Preview root: `WallpaperBloc()` takes no deps, and rotation is never
/// started here so no 6s timer runs in the web previewer.
Widget _homeBackgroundPreviewRoot(WallpaperBloc bloc) {
  return MaterialApp(
    home: BlocProvider.value(
      value: bloc,
      child: const Scaffold(
        body: HomeBackground(),
      ),
    ),
  );
}

@Preview(
  name: 'HomeBackground - wallpaper 1',
  group: 'Wallpaper',
  size: Size(1200, 800),
)
Widget homeBackgroundPreview() {
  return _homeBackgroundPreviewRoot(WallpaperBloc());
}

@Preview(
  name: 'HomeBackground - wallpaper 2',
  group: 'Wallpaper',
  size: Size(1200, 800),
)
Widget homeBackgroundAlternatePreview() {
  return _homeBackgroundPreviewRoot(WallpaperBloc()..add(NextWallpaper()));
}
