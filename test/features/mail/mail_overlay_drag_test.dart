import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jent_web/domain/usecases/send_email_usecase.dart';
import 'package:jent_web/l10n/app_localizations.dart';
import 'package:jent_web/features/mail/bloc/mail_bloc.dart';
import 'package:jent_web/features/mail/bloc/mail_event.dart';
import 'package:jent_web/core/widgets/window/window_drag_area.dart';
import 'package:jent_web/features/mail/view/mail_overlay.dart';
import 'package:jent_web/features/mail/view/mail_window.dart';
import 'package:mocktail/mocktail.dart';

class _MockSendEmail extends Mock implements SendEmailUseCase {}

void main() {
  testWidgets(
    'mail window mounts without competing Positioned and drags',
    (tester) async {
      final bloc = MailBloc(
        _MockSendEmail(),
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(
        _MailHarness(bloc: bloc),
      );

      // Closed: no window, no crash.
      expect(find.byType(MailWindow), findsNothing);

      // Open: mounts inside the page-like Positioned.fill wrapper,
      // the exact nesting that used to throw competing-Positioned.
      bloc.add(ToggleOpenEmailMenu());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(MailWindow), findsOneWidget);

      Offset windowPos() {
        final positioned = tester.widget<Positioned>(
          find
              .ancestor(
                of: find.byType(MailWindow),
                matching: find.byType(Positioned),
              )
              .first,
        );
        return Offset(positioned.left!, positioned.top!);
      }

      final before = windowPos();
      await tester.timedDrag(
        find.byType(WindowDragArea),
        const Offset(-80, 50),
        const Duration(milliseconds: 300),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final after = windowPos();
      expect(after.dx, lessThan(before.dx));
      expect(after.dy, greaterThan(before.dy));
    },
  );

  testWidgets('mail window can be resized from the right edge', (
    tester,
  ) async {
    final bloc = MailBloc(
      _MockSendEmail(),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      _MailHarness(bloc: bloc),
    );

    bloc.add(ToggleOpenEmailMenu());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    Size windowSize() => tester.getSize(find.byType(AnimatedContainer).first);
    final before = windowSize();

    await tester.drag(
      find.byKey(const ValueKey('mail-resize-right')),
      const Offset(80, 0),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final after = windowSize();
    expect(after.width, before.width + 80);
    expect(after.height, before.height);
  });
}

/// Mirrors home_page.dart: MailOverlay inside Positioned.fill
/// inside a Stack. Catches competing-ParentData regressions.
class _MailHarness extends StatefulWidget {
  final MailBloc bloc;

  const _MailHarness({required this.bloc});

  @override
  State<_MailHarness> createState() => _MailHarnessState();
}

class _MailHarnessState extends State<_MailHarness>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: BlocProvider.value(
        value: widget.bloc,
        child: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                top: kToolbarHeight,
                bottom: 80,
                child: MailOverlay(controller: controller),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
