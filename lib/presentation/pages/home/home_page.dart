import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jent_web/gen/assets.gen.dart';
import 'package:jent_web/l10n/app_localizations.dart';
import 'package:jent_web/presentation/base/base_page.dart';
import 'package:jent_web/presentation/pages/home/home_bloc.dart';
import 'package:jent_web/presentation/pages/home/home_event.dart';
import 'package:jent_web/presentation/pages/home/home_state.dart';
import 'package:jent_web/source/animation/adaptive_menu_bar.dart';
import 'package:jent_web/source/animation/animated_background.dart';
import 'package:jent_web/source/colors.dart';
import 'package:jent_web/source/widget/dock/dock_widget.dart';

class HomePage extends BasePage {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final AnimationController _windowController;
  late AppLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    _windowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _localizations = AppLocalizations.of(context)!;
  }

  @override
  void dispose() {
    _windowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return BlocProvider(
      create: (context) => HomeBloc()..add(StartWallpaperRotation()),
      child: Scaffold(

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
              const _Background(),
              Stack(
                fit: StackFit.expand,
                children: [
                  const Positioned(top: 0, left: 0, right: 0, child: _MenuBar()),
                  Positioned.fill(top: kToolbarHeight,bottom: 80, child: _MailOverlay(controller: _windowController, localizations: _localizations)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _Dock(localizations: _localizations),
                    ),
                  ),
                ],
              ),
            ]
          ),
        ),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();

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

class _MenuBar extends StatelessWidget {
  const _MenuBar();

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

class _Dock extends StatelessWidget {
  final AppLocalizations localizations;
  const _Dock({required this.localizations});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<HomeBloc>();
    return BlocSelector<HomeBloc, HomeState, List<bool>>(
      selector: (state) {
        return [
          state.isShowWindow,
          state.isMinimizedWindow,
          state.isExpandedWindow,
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
          tooltips: [localizations.textFinder, localizations.textEmail, localizations.textNotes, localizations.textMusic, localizations.textPhotos, localizations.textSpotlight],
          listDockMinimized: [false, !state[1], false, false, false, false],
          onIconTapped: (int p1) {
            if (p1 == 1) {
              if (state[0]) {
                bloc.add(ToggleCloseEmailMenu());
              } else {
                bloc.add(ToggleOpenEmailMenu());
              }
            }
          },
        );
      },
    );
  }
}

class _MailOverlay extends StatefulWidget {
  final AnimationController controller;
  final AppLocalizations localizations;
  const _MailOverlay({required this.controller, required this.localizations});

  @override
  State<_MailOverlay> createState() => _MailOverlayState();
}

class _MailOverlayState extends State<_MailOverlay> {
  bool _mounted = false;
  final ValueNotifier<Offset> _position = ValueNotifier(Offset.zero);
  bool _positionInitialized = false;
  Size? _screenSize;

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  Size _computeWindowSize(Size screenSize, bool expanded) {
    if (expanded) {
      final w = (screenSize.width * 0.85).clamp(500.0, 1200.0);
      final h = (screenSize.height * 0.78).clamp(800.0, 1200.0);
      return Size(w, h);
    }
    final w = (screenSize.width * 0.85).clamp(360.0, 920.0);
    final h = (screenSize.height * 0.78).clamp(420.0, 640.0);
    return Size(w, h);
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
    final minX = -(winSize.width - 80);
    final maxX = screenSize.width - 80;
    const minY = 38.0;
    final maxY = screenSize.height - 44;
    _position.value = Offset(
      next.dx.clamp(minX, maxX),
      next.dy.clamp(minY, maxY),
    );
  }

  void _clampPositionToBounds(Size screenSize, Size winSize) {
    final next = _position.value;
    final minX = -(winSize.width - 80);
    final maxX = screenSize.width - 80;
    const minY = 38.0;
    final maxY = screenSize.height - 44;
    _position.value = Offset(
      next.dx.clamp(minX, maxX),
      next.dy.clamp(minY, maxY),
    );
  }

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.sizeOf(context);
    final isExpanded = context.select<HomeBloc, bool>(
      (bloc) => bloc.state.isExpandedWindow,
    );
    final winSize = _computeWindowSize(_screenSize!, isExpanded);
    _initPosition(_screenSize!, winSize);

    return BlocListener<HomeBloc, HomeState>(
      listenWhen: (prev, curr) =>
          prev.isShowWindow != curr.isShowWindow ||
          prev.isExpandedWindow != curr.isExpandedWindow,
      listener: (context, state) {
        if (state.isShowWindow) {
          setState(() => _mounted = true);
          widget.controller.forward(from: 0);
        } else if (!state.isShowWindow) {
          widget.controller.reverse().whenComplete(() {
            if (mounted) setState(() => _mounted = false);
          });
        }
        final newSize = _computeWindowSize(_screenSize!, state.isExpandedWindow);
        _clampPositionToBounds(_screenSize!, newSize);
      },
      child: !_mounted
          ? const SizedBox.shrink()
          : AnimatedBuilder(
              animation: widget.controller,
              builder: (context, child) {
                final t = widget.controller.value;
                final scale = Curves.easeOutBack.transform(t).clamp(0.0, 1.2);
                final opacity = Curves.easeOut.transform(t).clamp(0.0, 1.0);
                final liftY = (1 - Curves.easeOutCubic.transform(t)) * 140;
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
                child: _MailWindow(
                  width: winSize.width,
                  height: winSize.height,
                  onClose: () =>
                      context.read<HomeBloc>().add(ToggleCloseEmailMenu()),
                  onExpand: () =>
                      context.read<HomeBloc>().add(ToggleExpandEmailMenu()),
                  onMinimize: () => context.read<HomeBloc>().add(ToggleMinimizeEmailMenu()),
                  onDragDelta: (d) => _onDragDelta(d, winSize),
                  localizations: widget.localizations,
                ),
              ),
            ),
    );
  }
}

class _MailWindow extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final VoidCallback onExpand;
  final double width;
  final double height;
  final ValueChanged<Offset> onDragDelta;
  final AppLocalizations localizations;
  const _MailWindow({
    required this.onClose,
    required this.width,
    required this.height,
    required this.onDragDelta,
    required this.localizations,
    required this.onExpand,
    required this.onMinimize,
  });

  @override
  State<_MailWindow> createState() => _MailWindowState();
}

class _MailWindowState extends State<_MailWindow> {
  final _nameController = TextEditingController();
  final _fromController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _sent = false;

  bool get _canSend =>
      _subjectController.text.trim().isNotEmpty ||
      _bodyController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _nameController,
      _fromController,
      _subjectController,
      _bodyController,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fromController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (!_canSend) return;
    setState(() => _sent = true);
    Future.delayed(const Duration(milliseconds: 700), widget.onClose);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = (size.width * 0.85).clamp(360.0, 920.0);
    final height = (size.height * 0.78).clamp(420.0, 640.0);

    return Material(
      elevation: 24,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      color: AppColors.deepWaterColor,
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            _TitleBar(
              onClose: widget.onClose,
              onMinimize: widget.onMinimize,
              onExpand: widget.onExpand,
              onPanUpdate: widget.onDragDelta,
            ),
            const Divider(height: 1),
            _FormRow(
              label: '${widget.localizations.textName}:',
              controller: _nameController,
              hint: widget.localizations.textNameHint,
            ),
            const Divider(height: 1, indent: 16),
            _FormRow(
              label: '${widget.localizations.textFrom}:',
              controller: _fromController,
              hint: widget.localizations.textFromHint,
            ),
            const Divider(height: 1, indent: 16),
            _FormRow(
              label: '${widget.localizations.textSubject}:',
              controller: _subjectController,
              hint: widget.localizations.textSubjectHint,
            ),
            const Divider(height: 1, indent: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _bodyController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: widget.localizations.textWriteYourMessageHint,
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _sent
                        ? Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Text(
                              widget.localizations.textSentWithIcon,
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: _canSend
                          ? const Color(0xFF1E88E5)
                          : const Color(0xFFBDBDBD),
                    ),
                    child: TextButton(
                      onPressed: _canSend ? _handleSend : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        widget.localizations.textSend,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  const _FormRow({
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  final VoidCallback onClose;
  final ValueChanged<Offset> onPanUpdate;
  final VoidCallback onExpand;
  final VoidCallback onMinimize;
  const _TitleBar({required this.onClose, required this.onPanUpdate, required this.onExpand, required this.onMinimize});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          _TrafficLight(color: const Color(0xFFFF5F57), onTap: onClose, glyph: Icons.close_rounded),
          const SizedBox(width: 8),
          _TrafficLight(color: const Color(0xFFFEBC2E), onTap: onMinimize, glyph: Icons.remove_circle),
          const SizedBox(width: 8),
          _TrafficLight(color: const Color(0xFF28C840), onTap: onExpand, glyph: Icons.expand_circle_down),
          Expanded(
            child: _DragArea(
              onPanUpdate: (details) => onPanUpdate(details.delta),
            ),
          ),
        ],
      ),
    );
  }
}

class _DragArea extends StatefulWidget {
  final GestureDragUpdateCallback onPanUpdate;
  const _DragArea({required this.onPanUpdate});

  @override
  State<_DragArea> createState() => _DragAreaState();
}

class _DragAreaState extends State<_DragArea> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _dragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => setState(() => _dragging = true),
        onPanUpdate: widget.onPanUpdate,
        onPanEnd: (_) => setState(() => _dragging = false),
        onPanCancel: () => setState(() => _dragging = false),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

class _TrafficLight extends StatefulWidget {
  final Color color;
  final VoidCallback onTap;
  final IconData glyph;
  const _TrafficLight({
    required this.color,
    required this.onTap,
    required this.glyph,
  });

  @override
  State<_TrafficLight> createState() => _TrafficLightState();
}

class _TrafficLightState extends State<_TrafficLight> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: _hovering
              ? Icon(widget.glyph, size: 9, color: Colors.black.withAlpha(140))
              : null,
        ),
      ),
    );
  }
}
