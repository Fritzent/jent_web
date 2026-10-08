import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jent_web/core/base_page.dart';
import 'package:jent_web/l10n/app_localizations.dart';

class _TestPage extends BasePage {
  const _TestPage();

  @override
  State<_TestPage> createState() => TestPageState();
}

class TestPageState extends BasePageState<_TestPage> {
  @override
  Widget buildPage(BuildContext context) {
    return const Text('page-body');
  }
}

void main() {
  Future<void> pumpPage(WidgetTester tester) {
    return tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en')],
        home: _TestPage(),
      ),
    );
  }

  group('BasePage', () {
    testWidgets('shows a loading overlay only while loading', (tester) async {
      await pumpPage(tester);
      expect(find.text('page-body'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      final state = tester.state<TestPageState>(find.byType(_TestPage));
      state.showLoading();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      state.hideLoading();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('permission prompt resolves true and false', (tester) async {
      await pumpPage(tester);
      final state = tester.state<TestPageState>(find.byType(_TestPage));

      var result = state.showPermissionPrompt(
        title: 'Allow?',
        message: 'Please confirm',
      );
      await tester.pumpAndSettle();
      expect(find.text('Allow?'), findsOneWidget);
      await tester.tap(find.text('Allow'));
      expect(await result, isTrue);

      result = state.showPermissionPrompt(
        title: 'Allow?',
        message: 'Please confirm',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deny'));
      expect(await result, isFalse);
    });
  });
}
