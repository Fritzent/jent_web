import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jent_web/core/widgets/menu/adaptive_menu_bar.dart';
import 'package:jent_web/presentation/pages/home/home_bloc.dart';
import 'package:jent_web/presentation/pages/home/home_state.dart';

class HomeMenuBar extends StatelessWidget {
  const HomeMenuBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeBloc, HomeState, String>(
      selector: (state) => state.imagePath,
      builder: (context, imagePath) {
        return AdaptiveMenuBar(backgroundImage: AssetImage(imagePath));
      },
    );
  }
}
