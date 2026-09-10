import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jent_web/core/widgets/background/animated_background.dart';
import 'package:jent_web/presentation/pages/home/home_bloc.dart';
import 'package:jent_web/presentation/pages/home/home_state.dart';

class HomeBackground extends StatelessWidget {
  const HomeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final images = context.read<HomeBloc>().images;
    return BlocSelector<HomeBloc, HomeState, int>(
      selector: (state) => state.currentIndex,
      builder: (context, currentIndex) {
        return PremiumAnimatedBackground(
          imagePaths: images,
          currentIndex: currentIndex,
          child: const SizedBox(),
        );
      },
    );
  }
}
