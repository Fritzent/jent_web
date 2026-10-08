import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jent_web/core/widgets/dock/dock_icon_widget.dart';
import 'package:jent_web/core/widgets/dock/dock_widget.dart';

void main() {
  group('DockIconWidget', () {
    testWidgets('renders the child icon at tile size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DockIconWidget(
              icon: Icon(Icons.email_rounded, key: ValueKey('dock-child')),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('dock-child')), findsOneWidget);
      expect(tester.getSize(find.byType(DockIconWidget)), const Size(52, 52));
    });
  });

  group('DockWidget', () {
    Future<void> pumpDock(
      WidgetTester tester, {
      required List<bool> dots,
      required void Function(int) onTap,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DockWidget(
              icons: const [
                Icon(Icons.email_rounded),
                Icon(Icons.music_note_rounded),
              ],
              tooltips: const ['Email', 'Music'],
              onIconTapped: onTap,
              listDockMinimized: dots,
            ),
          ),
        ),
      );
    }

    Finder dot() => find.byWidgetPredicate((w) {
          if (w is! Container) return false;
          final decoration = w.decoration;
          return decoration is BoxDecoration &&
              decoration.shape == BoxShape.circle;
        });

    testWidgets('taps report the icon index', (tester) async {
      final tapped = <int>[];
      await pumpDock(tester, dots: const [false, false], onTap: tapped.add);

      await tester.tap(find.byIcon(Icons.music_note_rounded));
      expect(tapped, [1]);
    });

    testWidgets('running dot follows listDockMinimized', (tester) async {
      await pumpDock(
        tester,
        dots: const [true, false],
        onTap: (_) {},
      );
      expect(dot(), findsOneWidget);

      await pumpDock(
        tester,
        dots: const [false, false],
        onTap: (_) {},
      );
      expect(dot(), findsNothing);
    });

    testWidgets('hovering an icon reveals its tooltip', (tester) async {
      await pumpDock(
        tester,
        dots: const [false, false],
        onTap: (_) {},
      );
      expect(find.text('Music'), findsNothing);

      final gesture =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(find.byIcon(Icons.music_note_rounded)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Music'), findsOneWidget);
      await gesture.removePointer();
    });
  });
}
