import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jent_web/features/ignite/widgets/hello_handwritten.dart';

void main() {
  group('HelloHandwritten', () {
    testWidgets('reveals text then finishes exactly once', (tester) async {
      var finished = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HelloHandwritten(
              text: 'Hi',
              onFinished: () => finished++,
            ),
          ),
        ),
      );

      // Starts blank, pen still writing.
      expect(find.text('Hi'), findsNothing);

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Hi'), findsNothing);

      // 140ms per char + hold: settle through write-on, then advance
      // past the 1s hold timer (pumpAndSettle alone stops when no
      // frames are scheduled, stranding the delayed callback).
      await tester.pumpAndSettle();
      expect(find.text('Hi'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(finished, 1);

      // No repeat callbacks after settling.
      await tester.pump(const Duration(seconds: 2));
      expect(finished, 1);
    });
  });
}
