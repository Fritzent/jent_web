import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jent_web/features/ignite/widgets/hello_welcome.dart';

void main() {
  testWidgets('tapping skips greetings and finishes once on the last text', (
    tester,
  ) async {
    var finished = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HelloWelcome(
            text: 'Welcome',
            onFinished: () => finished++,
          ),
        ),
      ),
    );

    expect(find.text('hello'), findsOneWidget);

    // Each tap skips straight to the next greeting.
    for (final word in [
      'hello',
      'hola',
      'bonjour',
      'ciao',
      'hallo',
      'こんにちは',
      '你好',
      '안녕하세요',
    ]) {
      await tester.tap(find.text(word));
      await tester.pump();
    }

    expect(find.text('Welcome'), findsOneWidget);

    // Tapping the final text finishes immediately.
    await tester.tap(find.text('Welcome'));
    await tester.pump();
    expect(finished, 1);

    // Stale timers must not fire onFinished again.
    await tester.pump(const Duration(seconds: 5));
    expect(finished, 1);
  });
}
