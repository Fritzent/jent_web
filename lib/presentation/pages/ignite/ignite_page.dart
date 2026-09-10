import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:jent_web/di/injection.dart';
import 'package:jent_web/gen/assets.gen.dart';
import 'package:jent_web/l10n/app_localizations.dart';
import 'package:jent_web/presentation/base/base_page.dart';
import 'package:jent_web/presentation/pages/ignite/ignite_bloc.dart';
import 'package:jent_web/presentation/pages/ignite/ignite_event.dart';
import 'package:jent_web/presentation/pages/ignite/ignite_state.dart';
import 'package:jent_web/presentation/pages/ignite/widgets/hello_welcome.dart';
import 'package:jent_web/router/app_path.dart';
import 'package:jent_web/core/widgets/background/water_fill_logo.dart';
import 'package:jent_web/core/theme/app_colors.dart';

class IgnitePage extends BasePage {
  const IgnitePage({super.key});

  @override
  State<IgnitePage> createState() => _IgnitePageState();
}

class _IgnitePageState extends BasePageState<IgnitePage>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget buildPage(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<IgniteBloc>()..add(IgniteStarted()),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocSelector<IgniteBloc, IgniteState, double>(
          selector: (state) => state.progress,
          builder: (context, progress) {
            final strings = AppLocalizations.of(context)!;
            return Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (progress < 1.0)
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 2,
                      child: Column(
                        children: [
                          SizedBox(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                WaterFillLogo(
                                  progress: progress,
                                  waterColor:
                                      AppColors.loadingBarForegroundColor,
                                  backgroundColor:
                                      AppColors.loadingBarBackgroundColor,
                                  logo: Assets.icLogoTransparent.image(),
                                  size: 320,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (progress >= 1.0)
                    HelloWelcome(
                      text: strings.welcomeMessage,
                      onFinished: () {
                        if (context.mounted) {
                          context.pushReplacement(AppPath.home);
                        }
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
