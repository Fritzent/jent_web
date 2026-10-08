import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jent_web/core/widgets/menu/adaptive_menu_bar.dart';
import 'package:jent_web/features/wallpaper/bloc/wallpaper_bloc.dart';
import 'package:jent_web/features/wallpaper/bloc/wallpaper_event.dart';
import 'package:jent_web/features/wallpaper/bloc/wallpaper_state.dart';
import 'package:jent_web/l10n/app_localizations.dart';

class HomeMenuBar extends StatelessWidget {
  const HomeMenuBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WallpaperBloc, WallpaperState, String>(
      selector: (state) => state.imagePath,
      builder: (context, imagePath) {
        return AdaptiveMenuBar(backgroundImage: AssetImage(imagePath));
      },
    );
  }
}

/// Preview root: `WallpaperBloc()` takes no deps, and rotation is never
/// started here so no 6s timer runs in the web previewer.
Widget _homeMenuBarPreviewRoot(WallpaperBloc wallpaperBloc) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: BlocProvider.value(
      value: wallpaperBloc,
      child: const Scaffold(
        body: Align(alignment: Alignment.topCenter, child: HomeMenuBar()),
      ),
    ),
  );
}

@Preview(
  name: 'HomeMenuBar - wallpaper 1',
  group: 'MenuBar',
  size: Size(900, 60),
)
Widget homeMenuBarPreview() {
  return _homeMenuBarPreviewRoot(WallpaperBloc());
}

@Preview(
  name: 'HomeMenuBar - wallpaper 2',
  group: 'MenuBar',
  size: Size(900, 60),
)
Widget homeMenuBarAlternatePreview() {
  return _homeMenuBarPreviewRoot(WallpaperBloc()..add(NextWallpaper()));
}
