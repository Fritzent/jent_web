import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
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
  int _generation = 0;
  bool _finished = false;

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
    final gen = _generation;
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _rise = Tween<double>(
      begin: AppDimens.helloRise,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _blur = Tween<double>(
      begin: 12,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller
      ..duration = _enterDuration
      ..forward(from: 0).whenComplete(() {
        if (!mounted || gen != _generation || _finished) return;
        _holdCurrent(gen);
      });
  }

  Future<void> _holdCurrent(int gen) async {
    if (!mounted) return;
    await Future.delayed(
      _index == _wordCount - 1
          ? const Duration(milliseconds: 900)
          : _holdDuration,
    );
    if (!mounted || gen != _generation || _finished) return;
    if (_index == _wordCount - 1) {
      _finish();
      return;
    }
    _playExit();
  }

  void _playExit() {
    if (!mounted || _finished) return;
    final gen = _generation;
    _leaving = true;
    _fade = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInCubic));
    _rise = Tween<double>(
      begin: 0,
      end: -AppDimens.helloExitLift,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInCubic));
    _blur = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInCubic));
    _controller
      ..duration = _exitDuration
      ..forward(from: 0).whenComplete(() {
        if (!mounted || gen != _generation || _finished) return;
        _leaving = false;
        setState(() => _index++);
        _playEnter();
      });
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onFinished?.call();
  }

  /// Skips the current greeting and jumps to the next one. Tapping the
  /// final text finishes the sequence immediately.
  void _skip() {
    if (_finished || !mounted) return;
    if (_index == _wordCount - 1) {
      _finish();
      return;
    }
    _generation++;
    _controller.stop();
    _leaving = false;
    setState(() => _index++);
    _playEnter();
  }

  int get _wordCount => _greetings.length + 1;

  String get _current =>
      _index < _greetings.length ? _greetings[_index] : widget.text;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _skip,
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        // Generous hit area covering the full rise/exit travel so taps
        // on the visible (translated) text always land on this detector.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 72),
          child: AnimatedBuilder(
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
          ),
        ),
      ),
    );
  }
}

/// Black stage like [IgnitePage]: the ultra-thin white greeting is
/// invisible on the default light preview canvas otherwise.
Widget _helloWelcomePreviewRoot(String text) {
  return MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: HelloWelcome(text: text)),
    ),
  );
}

@Preview(name: 'HelloWelcome - English', group: 'Ignite', size: Size(900, 400))
Widget helloWelcomePreview() => _helloWelcomePreviewRoot('Welcome');

@Preview(
  name: 'HelloWelcome - Indonesian',
  group: 'Ignite',
  size: Size(900, 400),
)
Widget helloWelcomeIndonesianPreview() =>
    _helloWelcomePreviewRoot('Selamat datang');
