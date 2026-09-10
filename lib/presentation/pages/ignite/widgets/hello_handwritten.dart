import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jent_web/core/theme/app_dimens.dart';

/// Handwritten "write-on" variant: the welcome string is revealed
/// character by character as if written by an invisible pen, with a
/// soft glowing pen tip leading the ink.
class HelloHandwritten extends StatefulWidget {
  final String text;
  final VoidCallback? onFinished;

  const HelloHandwritten({super.key, required this.text, this.onFinished});

  @override
  State<HelloHandwritten> createState() => _HelloHandwrittenState();
}

class _HelloHandwrittenState extends State<HelloHandwritten>
    with SingleTickerProviderStateMixin {
  static const _perChar = Duration(milliseconds: 140);
  static const _penSize = 14.0;
  static const _hold = Duration(milliseconds: 1000);

  late final AnimationController _controller;
  late final int _charCount;

  @override
  void initState() {
    super.initState();
    _charCount = widget.text.characters.length;
    _controller = AnimationController(
      vsync: this,
      duration: _perChar * _charCount + const Duration(milliseconds: 300),
    );
    _controller.forward(from: 0).whenComplete(_finish);
  }

  Future<void> _finish() async {
    if (!mounted) return;
    await Future.delayed(_hold);
    if (!mounted) return;
    widget.onFinished?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextStyle get _style => GoogleFonts.caveat(
        fontSize: AppDimens.helloHandFontSize,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.2,
      );

  Size _measure(String s) {
    final painter = TextPainter(
      text: TextSpan(text: s.isEmpty ? ' ' : s, style: _style),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.size;
  }

  @override
  Widget build(BuildContext context) {
    final full = _measure(widget.text);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value.clamp(0.0, 1.0);
        final shown = (t * _charCount).floor().clamp(0, _charCount);
        final revealed = widget.text.characters.take(shown).toString();
        final ink = _measure(revealed);
        final done = shown >= _charCount;
        final wobble = sin(t * _charCount * pi) * 3;

        return SizedBox(
          width: full.width + _penSize * 3,
          height: full.height + 8,
          child: Stack(
            children: [
              Positioned(
                left: _penSize,
                top: 0,
                child: Text(revealed, style: _style),
              ),
              if (!done)
                Positioned(
                  left: _penSize + ink.width + 4,
                  top: (full.height - _penSize) / 2 + wobble,
                  child: Container(
                    width: _penSize,
                    height: _penSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withAlpha(220),
                          blurRadius: 18,
                          spreadRadius: 5,
                        ),
                        BoxShadow(
                          color: Colors.lightBlueAccent.withAlpha(120),
                          blurRadius: 32,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
