import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jent_web/core/widgets/dock/dock_widget.dart';
import 'package:jent_web/gen/assets.gen.dart';
import 'package:jent_web/l10n/app_localizations.dart';
import 'package:jent_web/presentation/pages/home/home_bloc.dart';
import 'package:jent_web/presentation/pages/home/home_event.dart';
import 'package:jent_web/presentation/pages/home/home_state.dart';

class HomeDock extends StatelessWidget {
  const HomeDock({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final bloc = context.read<HomeBloc>();
    return BlocSelector<HomeBloc, HomeState, List<dynamic>>(
      selector: (state) {
        return [
          state.isShowWindow,
          state.isMinimizedWindow,
          state.isExpandedWindow,
          state.isShowMusicPlayer || state.isMusicMinimized,
        ];
      },
      builder: (context, state) {
        return DockWidget(
          icons: [
            Assets.icFinder.image(width: 28, height: 28),
            Assets.icEmail.image(width: 28, height: 28),
            Assets.icNotes.image(width: 28, height: 28),
            Assets.icMusic.image(width: 28, height: 28),
            Assets.icPhotos.image(width: 28, height: 28),
            Assets.icSpotLight.image(width: 28, height: 28),
          ],
          tooltips: [
            localizations.textFinder,
            localizations.textEmail,
            localizations.textNotes,
            localizations.textMusic,
            localizations.textPhotos,
            localizations.textSpotlight,
          ],
          listDockMinimized: [
            false,
            !(state[1] as bool),
            false,
            state[3] as bool,
            false,
            false,
          ],
          onIconTapped: (int p1) {
            if (p1 == 1) {
              if (state[0] as bool) {
                bloc.add(ToggleCloseEmailMenu());
              } else {
                bloc.add(ToggleOpenEmailMenu());
              }
            } else if (p1 == 3) {
              bloc.add(ToggleMusicPlayer());
            }
          },
        );
      },
    );
  }
}
