import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jent_web/core/theme/app_dimens.dart';
import 'package:jent_web/presentation/pages/home/home_bloc.dart';
import 'package:jent_web/presentation/pages/home/home_event.dart';
import 'package:jent_web/presentation/pages/home/home_state.dart';
import 'package:jent_web/presentation/pages/home/widgets/mail_window.dart';

class MailOverlay extends StatefulWidget {
  final AnimationController controller;

  const MailOverlay({super.key, required this.controller});

  @override
  State<MailOverlay> createState() => _MailOverlayState();
}

class _MailOverlayState extends State<MailOverlay> {
  bool _mounted = false;
  final ValueNotifier<Offset> _position = ValueNotifier(Offset.zero);
  bool _positionInitialized = false;
  Size? _screenSize;

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  void _initPosition(Size screenSize, Size winSize) {
    if (!_positionInitialized) {
      _position.value = Offset(
        (screenSize.width - winSize.width) / 2,
        (screenSize.height - winSize.height) / 2,
      );
      _positionInitialized = true;
    }
  }

  void _onDragDelta(Offset delta, Size winSize) {
    final screenSize = _screenSize!;
    final next = _position.value + delta;
    _position.value = _clampOffset(next, screenSize, winSize);
  }

  Offset _clampOffset(Offset next, Size screenSize, Size winSize) {
    final minX = -(winSize.width - AppDimens.dragEdgeGrip);
    final maxX = screenSize.width - AppDimens.dragEdgeGrip;
    final maxY = screenSize.height - AppDimens.dragBottomMargin;
    return Offset(
      next.dx.clamp(minX, maxX),
      next.dy.clamp(AppDimens.dragMinY, maxY),
    );
  }

  void _clampPositionToBounds(Size screenSize, Size winSize) {
    _position.value = _clampOffset(_position.value, screenSize, winSize);
  }

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.sizeOf(context);
    final isExpanded = context.select<HomeBloc, bool>(
      (bloc) => bloc.state.isExpandedWindow,
    );
    final winSize = AppDimens.mailWindowSize(_screenSize!, isExpanded);
    _initPosition(_screenSize!, winSize);

    return BlocListener<HomeBloc, HomeState>(
      listenWhen: (prev, curr) =>
          prev.isShowWindow != curr.isShowWindow ||
          prev.isExpandedWindow != curr.isExpandedWindow ||
          prev.emailStatus != curr.emailStatus,
      listener: (context, state) {
        if (state.isShowWindow) {
          setState(() => _mounted = true);
          widget.controller.forward(from: 0);
        } else if (!state.isShowWindow) {
          widget.controller.reverse().whenComplete(() {
            if (mounted) setState(() => _mounted = false);
          });
        }
        if (state.emailStatus == EmailStatus.sent) {
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (context.mounted) {
              context.read<HomeBloc>().add(ToggleCloseEmailMenu());
            }
          });
        }
        final newSize = AppDimens.mailWindowSize(
          _screenSize!,
          state.isExpandedWindow,
        );
        _clampPositionToBounds(_screenSize!, newSize);
      },
      child: !_mounted
          ? const SizedBox.shrink()
          : AnimatedBuilder(
              animation: widget.controller,
              builder: (context, child) {
                final t = widget.controller.value;
                final scale =
                    Curves.easeOutBack.transform(t).clamp(0.0, 1.2);
                final opacity =
                    Curves.easeOut.transform(t).clamp(0.0, 1.0);
                final liftY =
                    (1 - Curves.easeOutCubic.transform(t)) * 140;
                return ValueListenableBuilder<Offset>(
                  valueListenable: _position,
                  builder: (context, pos, innerChild) {
                    return Positioned(
                      left: pos.dx,
                      top: pos.dy + liftY,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale == 0 ? 0.001 : scale,
                          alignment: Alignment.bottomCenter,
                          child: innerChild,
                        ),
                      ),
                    );
                  },
                  child: child,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: winSize.width,
                height: winSize.height,
                child: MailWindow(
                  size: winSize,
                  onClose: () =>
                      context.read<HomeBloc>().add(ToggleCloseEmailMenu()),
                  onExpand: () =>
                      context.read<HomeBloc>().add(ToggleExpandEmailMenu()),
                  onMinimize: () =>
                      context.read<HomeBloc>().add(ToggleMinimizeEmailMenu()),
                  onDragDelta: (d) => _onDragDelta(d, winSize),
                  onSend: (draft) => context.read<HomeBloc>().add(
                    SendEmail(
                      name: draft.name,
                      from: draft.from,
                      subject: draft.subject,
                      body: draft.body,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
