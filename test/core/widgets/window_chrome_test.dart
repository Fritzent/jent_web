import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jent_web/core/widgets/window/traffic_light_button.dart';
import 'package:jent_web/core/widgets/window/window_drag_area.dart';
import 'package:jent_web/core/widgets/window/window_resize_handles.dart';
import 'package:jent_web/core/widgets/window/window_title_bar.dart';

Future<TestGesture> hoverAt(WidgetTester tester, Finder finder) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: tester.getCenter(finder));
  await tester.pump();
  return gesture;
}

void main() {
  group('TrafficLightButton', () {
    testWidgets('taps the callback, hides glyph until hover', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrafficLightButton(
              color: const Color(0xFFFF5F57),
              onTap: () => tapped++,
              glyph: Icons.close_rounded,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close_rounded), findsNothing);

      final gesture = await hoverAt(tester, find.byType(TrafficLightButton));
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      await gesture.removePointer();

      await tester.tap(find.byType(TrafficLightButton));
      expect(tapped, 1);
    });
  });

  group('WindowTitleBar', () {
    testWidgets('routes the three lights to their callbacks', (tester) async {
      var closed = 0;
      var minimized = 0;
      var expanded = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WindowTitleBar(
              onClose: () => closed++,
              onMinimize: () => minimized++,
              onExpand: () => expanded++,
              onPanUpdate: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byWidgetPredicate(
        (w) => w is TrafficLightButton && w.color == const Color(0xFFFF5F57),
      ));
      await tester.tap(find.byWidgetPredicate(
        (w) => w is TrafficLightButton && w.color == const Color(0xFFFEBC2E),
      ));
      await tester.tap(find.byWidgetPredicate(
        (w) => w is TrafficLightButton && w.color == const Color(0xFF28C840),
      ));

      expect(closed, 1);
      expect(minimized, 1);
      expect(expanded, 1);
    });

    testWidgets('dragging the bar reports pointer deltas', (tester) async {
      var total = Offset.zero;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 44,
              child: WindowTitleBar(
                onClose: () {},
                onMinimize: () {},
                onExpand: () {},
                onPanUpdate: (d) => total += d,
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.byType(WindowDragArea), const Offset(30, 12));
      await tester.pump();
      expect(total.dx, greaterThan(0));
      expect(total.dy, greaterThan(0));
    });
  });

  group('WindowResizeHandle', () {
    testWidgets('exposes the matching resize cursor', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                WindowResizeHandle(
                  key: ValueKey('h-edge'),
                  cursor: SystemMouseCursors.resizeLeftRight,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 10,
                  onResize: _noop,
                  onResizeStart: _noopVoid,
                  onResizeEnd: _noopVoid,
                ),
                WindowResizeHandle(
                  key: ValueKey('h-corner'),
                  cursor: SystemMouseCursors.resizeUpLeftDownRight,
                  right: 0,
                  bottom: 0,
                  width: 18,
                  height: 18,
                  onResize: _noop,
                  onResizeStart: _noopVoid,
                  onResizeEnd: _noopVoid,
                ),
              ],
            ),
          ),
        ),
      );

      MouseCursor cursorOf(String key) {
        final region = tester.widget<MouseRegion>(
          find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(MouseRegion),
          ),
        );
        return region.cursor;
      }

      expect(cursorOf('h-edge'), SystemMouseCursors.resizeLeftRight);
      expect(cursorOf('h-corner'), SystemMouseCursors.resizeUpLeftDownRight);
    });

    testWidgets('drag reports deltas and start/end lifecycle', (tester) async {
      var started = 0;
      var ended = 0;
      var total = Offset.zero;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SizedBox(
                  width: 400,
                  height: 300,
                  child: Stack(
                    children: [
                      WindowResizeHandle(
                        key: const ValueKey('h-drag'),
                        cursor: SystemMouseCursors.resizeUpDown,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 10,
                        onResize: (d) => total += d,
                        onResizeStart: () => started++,
                        onResizeEnd: () => ended++,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.drag(
        find.byKey(const ValueKey('h-drag')),
        const Offset(25, 40),
      );
      await tester.pump();

      expect(started, 1);
      expect(ended, 1);
      expect(total, const Offset(25, 40));
    });
  });
}

void _noop(Offset _) {}

void _noopVoid() {}
