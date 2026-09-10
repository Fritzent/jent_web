import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jent_web/presentation/base/base_page.dart';
import 'package:jent_web/presentation/pages/home/home_bloc.dart';
import 'package:jent_web/presentation/pages/home/home_state.dart';
import 'package:jent_web/presentation/pages/home/widgets/home_background.dart';
import 'package:jent_web/presentation/pages/home/widgets/home_dock.dart';
import 'package:jent_web/presentation/pages/home/widgets/home_menu_bar.dart';
import 'package:jent_web/presentation/pages/home/widgets/mail_overlay.dart';
import 'package:jent_web/presentation/pages/home/widgets/music_player_overlay.dart';

class HomePage extends BasePage {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _windowController;

  @override
  void initState() {
    super.initState();
    _windowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
  }

  @override
  void dispose() {
    _windowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<HomeBloc, HomeState>(
        listenWhen: (prev, curr) => prev.isShowWindow != curr.isShowWindow,
        listener: (context, state) {
          if (state.isShowWindow) {
            _windowController.forward();
          } else {
            _windowController.reverse();
          }
        },
        child: Stack(
          children: [
            const HomeBackground(),
            Stack(
              fit: StackFit.expand,
              children: [
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: HomeMenuBar(),
                ),
                Positioned.fill(
                  top: kToolbarHeight,
                  bottom: 80,
                  child: MailOverlay(controller: _windowController),
                ),
                const MusicPlayerOverlay(),
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: HomeDock(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//--------- MUSIC ---------//

//--------------------------------//
