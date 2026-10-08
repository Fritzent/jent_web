import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jent_web/core/widgets/background/animated_background.dart';
import 'package:jent_web/core/widgets/background/water_fill_logo.dart';
import 'package:jent_web/core/widgets/menu/adaptive_menu_bar.dart';
import 'package:jent_web/features/desktop/widgets/home_menu_bar.dart';
import 'package:jent_web/features/wallpaper/bloc/wallpaper_bloc.dart';
import 'package:jent_web/features/wallpaper/bloc/wallpaper_event.dart';
import 'package:jent_web/features/wallpaper/widgets/home_background.dart';
import 'package:jent_web/l10n/app_localizations.dart';

Widget l10nWrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: Scaffold(body: child),
  );
}

void main() {
  group('AdaptiveMenuBar', () {
    testWidgets('shows brand and menu entries', (tester) async {
      await tester.pumpWidget(
        l10nWrap(
          const AdaptiveMenuBar(
            backgroundImage: AssetImage('assets/il_home_1.jpg'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pritjent'), findsOneWidget);
      expect(find.text('File'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);
    });
  });

  group('HomeMenuBar', () {
    testWidgets('renders the adaptive bar from wallpaper state', (
      tester,
    ) async {
      final bloc = WallpaperBloc();
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: BlocProvider.value(
            value: bloc,
            child: const Scaffold(body: HomeMenuBar()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdaptiveMenuBar), findsOneWidget);
      expect(find.text('Pritjent'), findsOneWidget);
    });
  });

  group('HomeBackground', () {
    testWidgets('cycles wallpapers on next event', (tester) async {
      final bloc = WallpaperBloc();
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const Scaffold(body: HomeBackground()),
          ),
        ),
      );

      checkWallpaper(tester, expectedIndex: 0);

      bloc.add(NextWallpaper());
      await tester.pump();
      checkWallpaper(tester, expectedIndex: 1);
    });
  });

  group('WaterFillLogo', () {
    testWidgets('renders at the requested size and animates', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WaterFillLogo(
              progress: 0.5,
              logo: FlutterLogo(),
              waterColor: Colors.blue,
              backgroundColor: Colors.grey,
              size: 200,
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(WaterFillLogo)), const Size(200, 200));
      expect(find.byType(FlutterLogo), findsWidgets);

      // Wave animation ticks without errors.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(WaterFillLogo), findsOneWidget);
    });

    testWidgets('empty and full progress both render', (tester) async {
      for (final progress in [0.0, 1.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WaterFillLogo(
                progress: progress,
                logo: const FlutterLogo(),
                waterColor: Colors.blue,
                backgroundColor: Colors.grey,
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(WaterFillLogo), findsOneWidget);
      }
    });
  });
}

/// Reads the wallpaper index currently shown by the animated background.
void checkWallpaper(WidgetTester tester, {required int expectedIndex}) {
  final bg = tester.widget<PremiumAnimatedBackground>(
    find.byType(PremiumAnimatedBackground),
  );
  expect(bg.imagePaths, hasLength(5));
  expect(bg.currentIndex, expectedIndex);
}
