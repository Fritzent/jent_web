import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jent_web/core/theme/app_colors.dart';
import 'package:jent_web/core/theme/app_dimens.dart';
import 'package:jent_web/domain/entities/music_track.dart';
import 'package:jent_web/l10n/app_localizations.dart';
import 'package:jent_web/presentation/pages/home/home_bloc.dart';
import 'package:jent_web/presentation/pages/home/home_event.dart';
import 'package:jent_web/presentation/pages/home/home_state.dart';
import 'package:jent_web/presentation/pages/home/widgets/music_artwork.dart';
import 'package:jent_web/presentation/pages/home/widgets/music_controls.dart';
import 'package:jent_web/presentation/pages/home/widgets/music_variants.dart';
import 'package:jent_web/presentation/pages/home/widgets/music_window_chrome.dart';

class _MusicSnapshot {
  final bool isPlaying;
  final int trackIndex;
  final Duration position;
  final bool isExpanded;

  const _MusicSnapshot({
    required this.isPlaying,
    required this.trackIndex,
    required this.position,
    required this.isExpanded,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MusicSnapshot &&
          isPlaying == other.isPlaying &&
          trackIndex == other.trackIndex &&
          position == other.position &&
          isExpanded == other.isExpanded;

  @override
  int get hashCode =>
      Object.hash(isPlaying, trackIndex, position, isExpanded);
}

class _MusicVisibility {
  final bool show;
  final bool minimized;

  const _MusicVisibility({required this.show, required this.minimized});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MusicVisibility &&
          show == other.show &&
          minimized == other.minimized;

  @override
  int get hashCode => Object.hash(show, minimized);
}

class MusicPlayerOverlay extends StatefulWidget {
  const MusicPlayerOverlay({super.key});

  @override
  State<MusicPlayerOverlay> createState() => _MusicPlayerOverlayState();
}

class _MusicPlayerOverlayState extends State<MusicPlayerOverlay> {
  final ValueNotifier<Offset> _position = ValueNotifier(Offset.zero);
  bool _positioned = false;

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  void _ensurePosition(Size screen) {
    if (_positioned) return;
    _positioned = true;
    _position.value = Offset(
      screen.width - AppDimens.musicPlayerWidth - 24,
      screen.height - AppDimens.musicPlayerHeight - 160,
    );
  }

  void _onDrag(Offset delta, Size screen, double cardWidth) {
    final next = _position.value + delta;
    _position.value = Offset(
      next.dx.clamp(12.0, screen.width - cardWidth - 12),
      next.dy.clamp(AppDimens.dragMinY, screen.height - 120),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    _ensurePosition(screen);

    return BlocSelector<HomeBloc, HomeState, _MusicVisibility>(
      selector: (state) => _MusicVisibility(
        show: state.isShowMusicPlayer,
        minimized: state.isMusicMinimized,
      ),
      builder: (context, vis) {
        final expanded =
            context.select<HomeBloc, bool>((b) => b.state.isMusicExpanded);
        final cardWidth = expanded
            ? AppDimens.musicExpandedWidth
            : AppDimens.musicPlayerWidth;
        Widget? child;
        if (vis.show) {
          child = _MusicCard(
            key: const ValueKey('music-card'),
            onDrag: (d) => _onDrag(d, screen, cardWidth),
          );
        } else if (vis.minimized) {
          child = MusicMiniBar(
            key: const ValueKey('music-mini'),
            onDrag: (d) => _onDrag(d, screen, AppDimens.musicPlayerWidth),
          );
        }
        // Positioned must be a direct child of this explicit Stack so
        // StackParentData attaches correctly; the entrance animation
        // wraps only the card inside it.
        return SizedBox.expand(
          child: ValueListenableBuilder<Offset>(
            valueListenable: _position,
            builder: (context, pos, _) {
              return Stack(
                children: [
                  if (child != null)
                    Positioned(
                      left: pos.dx,
                      top: pos.dy,
                      child: _MusicEntrance(child: child),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// Entrance animation for the floating player, applied inside the
/// Positioned so it never interferes with StackParentData.
class _MusicEntrance extends StatefulWidget {
  final Widget child;

  const _MusicEntrance({required this.child});

  @override
  State<_MusicEntrance> createState() => _MusicEntranceState();
}

class _MusicEntranceState extends State<_MusicEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant _MusicEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child.key != widget.child.key) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
      alignment: Alignment.bottomRight,
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInCubic,
        ),
        child: widget.child,
      ),
    );
  }
}

class _MusicCard extends StatelessWidget {
  final ValueChanged<Offset> onDrag;

  const _MusicCard({super.key, required this.onDrag});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;

    return BlocSelector<HomeBloc, HomeState, _MusicSnapshot>(
      selector: (state) => _MusicSnapshot(
        isPlaying: state.isMusicPlaying,
        trackIndex: state.musicTrackIndex,
        position: state.musicPosition,
        isExpanded: state.isMusicExpanded,
      ),
      builder: (context, snap) {
        final bloc = context.read<HomeBloc>();
        final track = MusicPlaylist.tracks[snap.trackIndex];
        final width = snap.isExpanded
            ? AppDimens.musicExpandedWidth
            : AppDimens.musicPlayerWidth;

        return Material(
          elevation: 22,
          borderRadius: BorderRadius.circular(AppDimens.musicPlayerRadius),
          clipBehavior: Clip.antiAlias,
          color: AppColors.musicPlayerBackground,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) => onDrag(details.delta),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: width,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  AppDimens.musicPlayerRadius,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.musicPlayerPanel.withAlpha(235),
                    AppColors.musicPlayerBackground,
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withAlpha(22),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MusicWindowChrome(
                    isExpanded: snap.isExpanded,
                    onClose: () => bloc.add(CloseMusicPlayer()),
                    onMinimize: () => bloc.add(MinimizeMusicPlayer()),
                    onExpand: () => bloc.add(ExpandMusicPlayer()),
                    onPanUpdate: onDrag,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      MusicArtwork(isPlaying: snap.isPlaying),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MusicTrackHeader(
                              track: track,
                              statusLabel: snap.isPlaying
                                  ? strings.musicNowPlaying
                                  : strings.musicPaused,
                            ),
                            const SizedBox(height: 8),
                            MusicProgressBar(
                              position: snap.position,
                              duration: track.duration,
                            ),
                            const SizedBox(height: 10),
                            MusicTransportControls(
                              isPlaying: snap.isPlaying,
                              onPrevious: () =>
                                  bloc.add(PreviousMusicTrack()),
                              onToggle: () =>
                                  bloc.add(ToggleMusicPlayback()),
                              onNext: () => bloc.add(NextMusicTrack()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (snap.isExpanded) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Colors.white10),
                    const SizedBox(height: 6),
                    MusicExpandedView(
                      isPlaying: snap.isPlaying,
                      trackIndex: snap.trackIndex,
                      position: snap.position,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
