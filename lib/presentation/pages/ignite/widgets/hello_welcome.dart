import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jent_web/core/theme/app_dimens.dart';

/// Models the macOS setup "hello": a large ultra-thin greeting that
/// rises out of a soft blur, cycles through several languages, and
/// finishes on the localized welcome string.
class HelloWelcome extends StatefulWidget {
  final String text;
  final VoidCallback? onFinished;

  const HelloWelcome({super.key, required this.text, this.onFinished});

  @override
  State<HelloWelcome> createState() => _HelloWelcomeState();
}

class _HelloWelcomeState extends State<HelloWelcome>
    with SingleTickerProviderStateMixin {
  /// Greetings shown before the localized welcome string, macOS style.
  static const _greetings = [
    'hello',
    'hola',
    'bonjour',
    'ciao',
    'hallo',
    'こんにちは',
    '你好',
    '안녕하세요',
  ];

  static const _enterDuration = Duration(milliseconds: 700);
  static const _holdDuration = Duration(milliseconds: 550);
  static const _exitDuration = Duration(milliseconds: 450);

  late final AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _rise;
  late Animation<double> _blur;

  int _index = 0;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _playEnter();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _playEnter() {
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _rise = Tween<double>(begin: AppDimens.helloRise, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _blur = Tween<double>(begin: 12, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller
      ..duration = _enterDuration
      ..forward(from: 0).whenComplete(_holdCurrent);
  }

  Future<void> _holdCurrent() async {
    if (!mounted) return;
    await Future.delayed(
      _index == _wordCount - 1
          ? const Duration(milliseconds: 900)
          : _holdDuration,
    );
    if (!mounted) return;
    if (_index == _wordCount - 1) {
      widget.onFinished?.call();
      return;
    }
    _playExit();
  }

  void _playExit() {
    if (!mounted) return;
    _leaving = true;
    _fade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInCubic),
    );
    _rise = Tween<double>(begin: 0, end: -AppDimens.helloExitLift).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInCubic),
    );
    _blur = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInCubic),
    );
    _controller
      ..duration = _exitDuration
      ..forward(from: 0).whenComplete(() {
        if (!mounted) return;
        _leaving = false;
        setState(() => _index++);
        _playEnter();
      });
  }

  int get _wordCount => _greetings.length + 1;

  String get _current =>
      _index < _greetings.length ? _greetings[_index] : widget.text;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          key: ValueKey('hello-$_index-${_leaving ? 'exit' : 'enter'}'),
          opacity: _fade.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, _rise.value),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: _blur.value,
                sigmaY: _blur.value,
              ),
              child: child,
            ),
          ),
        );
      },
      child: Text(
        _current,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: AppDimens.helloFontSize,
          fontWeight: FontWeight.w100,
          color: Colors.white,
          height: 1.1,
          letterSpacing: -2,
        ),
      ),
    );
  }
}
