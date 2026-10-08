import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jent_web/l10n/app_localizations.dart';
import 'package:jent_web/features/photos/bloc/photos_bloc.dart';
import 'package:jent_web/features/photos/bloc/photos_event.dart';
import 'package:jent_web/features/photos/view/photos_pin_overlay.dart';
import 'package:jent_web/features/photos/view/photos_window_overlay.dart';


void main() {
  testWidgets('photos window opens, views a photo, and returns to grid', (
    tester,
  ) async {
    final bloc = PhotosBloc();
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
          child: const Scaffold(
            body: Stack(
              children: [PhotosWindowOverlay(), PhotosPinOverlay()],
            ),
          ),
        ),
      ),
    );

    // Closed: no grid.
    expect(find.byType(GridView), findsNothing);

    // Locked: dock toggle opens the PIN prompt, not the gallery.
    bloc.add(TogglePhotosWindow());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(GridView), findsNothing);
    expect(find.text('Enter PIN to open Photos'), findsOneWidget);

    // Wrong PIN: access-denied popup instead of the gallery.
    await tester.enterText(find.byType(TextField), '9999');
    await tester.tap(find.text('Unlock'));
    await tester.pump();
    expect(find.text("You don't have access to see the photos"),
        findsOneWidget);
    expect(find.byType(GridView), findsNothing);

    // Dismiss the popup, then unlock with the correct PIN.
    await tester.tap(find.text('Close'));
    await tester.pump();
    bloc.add(TogglePhotosWindow());
    await tester.pump();
    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Unlock'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(bloc.state.isPhotosLocked, isFalse);
    expect(find.byType(GridView), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is Image && w.image is AssetImage),
      findsNWidgets(5),
    );

    // Tap the first photo: viewer opens on it.
    await tester.tap(find.byKey(const ValueKey('photo-cell-0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(bloc.state.photosViewerIndex, 0);
    // Chevrons are always enabled: the viewer wraps endlessly.
    final leftChevron = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_left_rounded),
    );
    final rightChevron = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
    );
    expect(leftChevron.onPressed, isNotNull);
    expect(rightChevron.onPressed, isNotNull);

    // Wrap backwards: left from the first photo lands on the last.
    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.chevron_left_rounded),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(bloc.state.photosViewerIndex, 4);

    // Swiping right-to-left advances with wrap-around: 4 -> 0.
    await tester.fling(
      find.byType(PageView),
      const Offset(-400, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(bloc.state.photosViewerIndex, 0);

    // Back to grid.
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();
    expect(bloc.state.photosViewerIndex, -1);
    expect(find.byType(GridView), findsOneWidget);

    // Close the window entirely.
    bloc.add(ClosePhotosWindow());
    await tester.pump();
    expect(find.byType(GridView), findsNothing);
  });

  testWidgets('wrong PIN offers the general album without unlocking', (
    tester,
  ) async {
    final bloc = PhotosBloc();
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
          child: const Scaffold(
            body: Stack(
              children: [PhotosWindowOverlay(), PhotosPinOverlay()],
            ),
          ),
        ),
      ),
    );

    // Wrong PIN shows the denied card with a guest entry point.
    bloc.add(TogglePhotosWindow());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), '9999');
    await tester.tap(find.text('Unlock'));
    await tester.pump();
    expect(find.text('View general photos'), findsOneWidget);

    // Guest album opens without unlocking the private one.
    await tester.tap(find.text('View general photos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(bloc.state.isShowPhotosWindow, isTrue);
    expect(bloc.state.isPhotosLocked, isTrue);
    expect(bloc.state.isPhotosGeneralMode, isTrue);
    expect(find.byType(GridView), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is Image && w.image is AssetImage),
      findsNWidgets(2),
    );

    // Viewer works on the general album too.
    await tester.tap(find.byKey(const ValueKey('photo-cell-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(bloc.state.photosViewerIndex, 1);
    expect(find.byType(InteractiveViewer), findsOneWidget);

    // Closing exits guest mode; the dock asks for the PIN again.
    bloc.add(ClosePhotosWindow());
    await tester.pump();
    expect(find.byType(GridView), findsNothing);
    bloc.add(TogglePhotosWindow());
    await tester.pump();
    expect(find.text('Enter PIN to open Photos'), findsOneWidget);
  });

  testWidgets('minimize hides the window; expand grows it', (tester) async {
    // Room for the expanded window.
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final bloc = PhotosBloc();
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
          child: const Scaffold(
            body: Stack(
              children: [PhotosWindowOverlay(), PhotosPinOverlay()],
            ),
          ),
        ),
      ),
    );

    bloc.add(SubmitPhotosPin('1234'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    Size windowSize() => tester.getSize(find.byType(AnimatedContainer).first);
    expect(windowSize(), const Size(560, 420));

    // Expand: grows to the expanded size and stays on-screen.
    bloc.add(TogglePhotosExpanded());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final rect = tester.getRect(find.byType(AnimatedContainer).first);
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(1400));
    expect(rect.bottom, lessThanOrEqualTo(1000));

    // Shrink back.
    bloc.add(TogglePhotosExpanded());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(windowSize(), const Size(560, 420));

    // Minimize: overlay hidden even though minimized flag is set.
    bloc.add(MinimizePhotosWindow());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(GridView), findsNothing);
    expect(find.byType(AnimatedContainer), findsNothing);

    // Dock toggle after minimize always asks for the PIN again.
    bloc.add(TogglePhotosWindow());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(bloc.state.isShowPhotosWindow, isFalse);
    expect(bloc.state.isPhotosPinVisible, isTrue);
    expect(find.text('Enter PIN to open Photos'), findsOneWidget);
    expect(find.byType(GridView), findsNothing);

    // Correct PIN restores the gallery.
    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Unlock'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(bloc.state.isShowPhotosWindow, isTrue);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('window can be resized from edges and corners', (tester) async {
    final bloc = PhotosBloc();
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
          child: const Scaffold(
            body: Stack(
              children: [PhotosWindowOverlay(), PhotosPinOverlay()],
            ),
          ),
        ),
      ),
    );

    bloc.add(SubmitPhotosPin('1234'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    Size windowSize() => tester.getSize(find.byType(AnimatedContainer).first);
    expect(windowSize(), const Size(560, 420));

    // Drag the right edge outward: only the width grows.
    await tester.drag(
      find.byKey(const ValueKey('photos-resize-right')),
      const Offset(80, 0),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(windowSize(), const Size(640, 420));

    // Drag the bottom edge downward: only the height grows.
    await tester.drag(
      find.byKey(const ValueKey('photos-resize-bottom')),
      const Offset(0, 60),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(windowSize(), const Size(640, 480));

    // Drag the left edge far inward: width clamps to the minimum.
    await tester.drag(
      find.byKey(const ValueKey('photos-resize-left')),
      const Offset(500, 0),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(windowSize().width, 340);

    // The gallery still works after resizing.
    await tester.tap(find.byKey(const ValueKey('photo-cell-0')));
    await tester.pump();
    expect(bloc.state.photosViewerIndex, 0);
  });
}
