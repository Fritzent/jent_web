import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jent_web/domain/usecases/send_email_usecase.dart';
import 'package:jent_web/l10n/app_localizations.dart';
import 'package:jent_web/presentation/pages/home/home_bloc.dart';
import 'package:jent_web/presentation/pages/home/home_event.dart';
import 'package:jent_web/presentation/pages/home/widgets/music_player_overlay.dart';
import 'package:jent_web/presentation/pages/home/widgets/music_window_chrome.dart';
import 'package:mocktail/mocktail.dart';

class _MockSendEmail extends Mock implements SendEmailUseCase {}

void main() {
  testWidgets('dragging the chrome strip moves the music card', (
    tester,
  ) async {
    final bloc = HomeBloc(_MockSendEmail());
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
            body: Stack(children: [MusicPlayerOverlay()]),
          ),
        ),
      ),
    );

    bloc.add(ToggleMusicPlayer());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(MusicWindowChrome), findsOneWidget);

    Offset cardPos() {
      final positioned = tester.widget<Positioned>(
        find
            .ancestor(
              of: find.byType(MusicWindowChrome),
              matching: find.byType(Positioned),
            )
            .first,
      );
      return Offset(positioned.left!, positioned.top!);
    }

    final before = cardPos();
    await tester.timedDrag(
      find.byType(MusicWindowChrome),
      const Offset(-100, 60),
      const Duration(milliseconds: 300),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final after = cardPos();
    expect(after.dx, lessThan(before.dx));
    expect(after.dy, greaterThan(before.dy));

    bloc.add(ToggleMusicPlayback());
    await tester.pump();
  });
}
