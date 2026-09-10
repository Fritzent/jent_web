import 'package:flutter/material.dart';

class PremiumAnimatedBackground extends StatelessWidget {
  final List<String> imagePaths;
  final int currentIndex;
  final Duration transitionDuration;
  final Widget child;

  const PremiumAnimatedBackground({
    super.key,
    required this.imagePaths,
    required this.currentIndex,
    required this.child,
    this.transitionDuration = const Duration(milliseconds: 2400),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: transitionDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            final scale = Tween<double>(
              begin: 1.08,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );

            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: scale,
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey(currentIndex),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(imagePaths[currentIndex]),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),

        child,
      ],
    );
  }
}