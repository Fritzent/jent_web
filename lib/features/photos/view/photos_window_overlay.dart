import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jent_web/core/constants/app_images.dart';
import 'package:jent_web/core/constants/vault_pin.dart';
import 'package:jent_web/core/theme/app_dimens.dart';
import 'package:jent_web/core/widgets/window/window_resize_handles.dart';
import 'package:jent_web/core/widgets/window/window_title_bar.dart';
import 'package:jent_web/l10n/app_localizations.dart';
import 'package:jent_web/features/photos/bloc/photos_bloc.dart';
import 'package:jent_web/features/photos/bloc/photos_event.dart';
import 'package:jent_web/features/photos/bloc/photos_state.dart';
import 'package:jent_web/features/photos/view/photos_pin_overlay.dart';

/// Floating macOS-Photos-style gallery window: light chrome, grid of
/// thumbnails, and an in-window fullscreen viewer with prev/next.
class PhotosWindowOverlay extends StatefulWidget {
  const PhotosWindowOverlay({super.key});

  @override
  State<PhotosWindowOverlay> createState() => _PhotosWindowOverlayState();
}

class _PhotosWindowOverlayState extends State<PhotosWindowOverlay> {
  /// Local window frame. Null means "use the preset size, centered".
  /// Cleared whenever the window closes or the expand toggle changes,
  /// so the window snaps back to its preset size.
  final ValueNotifier<Rect?> _frame = ValueNotifier(null);
  bool? _lastExpanded;
  bool _resizing = false;

  /// macOS-like resize limits.
  static const _minWinSize = Size(340, 260);
  static const _edgeGrip = 10.0;
  static const _cornerGrip = 18.0;

  @override
  void dispose() {
    _frame.dispose();
    super.dispose();
  }

  Size _baseSize(bool expanded) => expanded
      ? const Size(
          AppDimens.photosExpandedWidth,
          AppDimens.photosExpandedHeight,
        )
      : const Size(AppDimens.photosWindowWidth, AppDimens.photosWindowHeight);

  Rect _defaultFrame(Size screen, Size base) => Rect.fromLTWH(
        (screen.width - base.width) / 2,
        (screen.height - base.height) / 2 - 40,
        base.width,
        base.height,
      );

  Rect _clampFrame(Rect frame, Size screen) {
    final maxX = math.max(12.0, screen.width - frame.width - 12);
    final maxY = math.max(AppDimens.dragMinY, screen.height - 120);
    final left = frame.left.clamp(12.0, maxX);
    final top = frame.top.clamp(AppDimens.dragMinY, maxY);
    return Rect.fromLTWH(left, top, frame.width, frame.height);
  }

  void _onDrag(Offset delta, Size screen) {
    final base = _baseSize(context.read<PhotosBloc>().state.isPhotosExpanded);
    final current = _frame.value ?? _defaultFrame(screen, base);
    final next = current.topLeft + delta;
    final maxX = math.max(12.0, screen.width - current.width - 12);
    final maxY = math.max(AppDimens.dragMinY, screen.height - 120);
    final clamped = Offset(
      next.dx.clamp(12.0, maxX),
      next.dy.clamp(AppDimens.dragMinY, maxY),
    );
    _frame.value = Rect.fromLTWH(
      clamped.dx,
      clamped.dy,
      current.width,
      current.height,
    );
  }

  void _onResize(WindowResizeEdges edges, Offset delta, Size screen) {
    final base = _baseSize(context.read<PhotosBloc>().state.isPhotosExpanded);
    final current = _frame.value ?? _defaultFrame(screen, base);
    var left = current.left;
    var top = current.top;
    var right = current.right;
    var bottom = current.bottom;
    if (edges.left) left += delta.dx;
    if (edges.right) right += delta.dx;
    if (edges.top) top += delta.dy;
    if (edges.bottom) bottom += delta.dy;
    // Enforce the minimum size, pushing the dragged edge back.
    if (right - left < _minWinSize.width) {
      if (edges.left) {
        left = right - _minWinSize.width;
      } else {
        right = left + _minWinSize.width;
      }
    }
    if (bottom - top < _minWinSize.height) {
      if (edges.top) {
        top = bottom - _minWinSize.height;
      } else {
        bottom = top + _minWinSize.height;
      }
    }
    // Keep the window on screen (guarded for tiny screens).
    left = left.clamp(0.0, math.max(0.0, screen.width - _minWinSize.width));
    right = right.clamp(_minWinSize.width, math.max(_minWinSize.width, screen.width));
    top = top.clamp(0.0, math.max(0.0, screen.height - _minWinSize.height));
    bottom = bottom.clamp(
      _minWinSize.height,
      math.max(_minWinSize.height, screen.height - 24),
    );
    _frame.value = Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);

    return BlocSelector<PhotosBloc, PhotosState, _PhotosVisibility>(
      selector: (state) => _PhotosVisibility(
        show: state.isShowPhotosWindow,
        minimized: state.isPhotosMinimized,
        expanded: state.isPhotosExpanded,
      ),
      builder: (context, vis) {
        // Minimized (or closed) hides the window entirely and forgets
        // any manual resize; the dock dot is the only reminder.
        if (!vis.show) {
          _frame.value = null;
          _lastExpanded = null;
          return const SizedBox.shrink();
        }
        // The expand toggle snaps back to the preset size.
        if (_lastExpanded != vis.expanded) {
          _lastExpanded = vis.expanded;
          _frame.value = null;
        }
        return SizedBox.expand(
          child: ValueListenableBuilder<Rect?>(
            valueListenable: _frame,
            builder: (context, custom, _) {
              final frame = _clampFrame(
                custom ?? _defaultFrame(screen, _baseSize(vis.expanded)),
                screen,
              );
              return Stack(
                children: [
                  Positioned(
                    left: frame.left,
                    top: frame.top,
                    child: SizedBox(
                      width: frame.width,
                      height: frame.height,
                      child: Stack(
                        children: [
                          Material(
                            elevation: 22,
                            borderRadius: BorderRadius.circular(
                              AppDimens.windowRadius,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate: (details) =>
                                  _onDrag(details.delta, screen),
                              child: AnimatedContainer(
                                // Follow the pointer live while resizing;
                                // animate preset changes (expand toggle).
                                duration: _resizing
                                    ? Duration.zero
                                    : const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                width: frame.width,
                                height: frame.height,
                                color: Colors.white,
                                child: Column(
                                  children: [
                                    WindowTitleBar(
                                      onClose: () =>
                                          bloc.add(ClosePhotosWindow()),
                                      onMinimize: () =>
                                          bloc.add(MinimizePhotosWindow()),
                                      onExpand: () =>
                                          bloc.add(TogglePhotosExpanded()),
                                      onPanUpdate: (offset) =>
                                          _onDrag(offset, screen),
                                    ),
                                    const Expanded(
                                      child: _PhotosBody(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // macOS-style resize zones above the content so
                          // they win hit tests against the move-drag area.
                          WindowResizeHandle(
                            key: const ValueKey('photos-resize-left'),
                            cursor: SystemMouseCursors.resizeLeftRight,
                            left: 0,
                            top: _cornerGrip,
                            bottom: _cornerGrip,
                            width: _edgeGrip,
                            onResize: (delta) =>
                                _onResize(WindowResizeEdges.onLeft, delta, screen),
                            onResizeStart: () =>
                                setState(() => _resizing = true),
                            onResizeEnd: () =>
                                setState(() => _resizing = false),
                          ),
                          WindowResizeHandle(
                            key: const ValueKey('photos-resize-right'),
                            cursor: SystemMouseCursors.resizeLeftRight,
                            right: 0,
                            top: _cornerGrip,
                            bottom: _cornerGrip,
                            width: _edgeGrip,
                            onResize: (delta) =>
                                _onResize(WindowResizeEdges.onRight, delta, screen),
                            onResizeStart: () =>
                                setState(() => _resizing = true),
                            onResizeEnd: () =>
                                setState(() => _resizing = false),
                          ),
                          WindowResizeHandle(
                            key: const ValueKey('photos-resize-top'),
                            cursor: SystemMouseCursors.resizeUpDown,
                            left: _cornerGrip,
                            right: _cornerGrip,
                            top: 0,
                            height: 8,
                            onResize: (delta) =>
                                _onResize(WindowResizeEdges.onTop, delta, screen),
                            onResizeStart: () =>
                                setState(() => _resizing = true),
                            onResizeEnd: () =>
                                setState(() => _resizing = false),
                          ),
                          WindowResizeHandle(
                            key: const ValueKey('photos-resize-bottom'),
                            cursor: SystemMouseCursors.resizeUpDown,
                            left: _cornerGrip,
                            right: _cornerGrip,
                            bottom: 0,
                            height: _edgeGrip,
                            onResize: (delta) =>
                                _onResize(WindowResizeEdges.onBottom, delta, screen),
                            onResizeStart: () =>
                                setState(() => _resizing = true),
                            onResizeEnd: () =>
                                setState(() => _resizing = false),
                          ),
                          WindowResizeHandle(
                            key: const ValueKey('photos-resize-topLeft'),
                            cursor:
                                SystemMouseCursors.resizeUpLeftDownRight,
                            left: 0,
                            top: 0,
                            width: _cornerGrip,
                            height: _cornerGrip,
                            onResize: (delta) => _onResize(
                              WindowResizeEdges.onTopLeft,
                              delta,
                              screen,
                            ),
                            onResizeStart: () =>
                                setState(() => _resizing = true),
                            onResizeEnd: () =>
                                setState(() => _resizing = false),
                          ),
                          WindowResizeHandle(
                            key: const ValueKey('photos-resize-topRight'),
                            cursor:
                                SystemMouseCursors.resizeUpRightDownLeft,
                            right: 0,
                            top: 0,
                            width: _cornerGrip,
                            height: _cornerGrip,
                            onResize: (delta) => _onResize(
                              WindowResizeEdges.onTopRight,
                              delta,
                              screen,
                            ),
                            onResizeStart: () =>
                                setState(() => _resizing = true),
                            onResizeEnd: () =>
                                setState(() => _resizing = false),
                          ),
                          WindowResizeHandle(
                            key: const ValueKey('photos-resize-bottomLeft'),
                            cursor:
                                SystemMouseCursors.resizeUpRightDownLeft,
                            left: 0,
                            bottom: 0,
                            width: _cornerGrip,
                            height: _cornerGrip,
                            onResize: (delta) => _onResize(
                              WindowResizeEdges.onBottomLeft,
                              delta,
                              screen,
                            ),
                            onResizeStart: () =>
                                setState(() => _resizing = true),
                            onResizeEnd: () =>
                                setState(() => _resizing = false),
                          ),
                          WindowResizeHandle(
                            key: const ValueKey('photos-resize-bottomRight'),
                            cursor:
                                SystemMouseCursors.resizeUpLeftDownRight,
                            right: 0,
                            bottom: 0,
                            width: _cornerGrip,
                            height: _cornerGrip,
                            onResize: (delta) => _onResize(
                              WindowResizeEdges.onBottomRight,
                              delta,
                              screen,
                            ),
                            onResizeStart: () =>
                                setState(() => _resizing = true),
                            onResizeEnd: () =>
                                setState(() => _resizing = false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  PhotosBloc get bloc => context.read<PhotosBloc>();
}

class _PhotosVisibility {
  final bool show;
  final bool minimized;
  final bool expanded;

  const _PhotosVisibility({
    required this.show,
    required this.minimized,
    required this.expanded,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PhotosVisibility &&
          show == other.show &&
          minimized == other.minimized &&
          expanded == other.expanded;

  @override
  int get hashCode => Object.hash(show, minimized, expanded);
}

/// Grid of thumbnails, or the fullscreen viewer when a photo is
/// selected. Reads viewer + album state from the bloc.
class _PhotosBody extends StatelessWidget {
  const _PhotosBody();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PhotosBloc, PhotosState, ({int viewer, bool general})>(
      selector: (state) => (
        viewer: state.photosViewerIndex,
        general: state.isPhotosGeneralMode,
      ),
      builder: (context, snap) {
        final photos = snap.general
            ? AppImages.generalPhotos
            : AppImages.privatePhotos;
        if (snap.viewer >= 0) {
          return _PhotoViewer(index: snap.viewer, photos: photos);
        }
        // Column count follows the live window width so resized
        // windows keep well-proportioned thumbnails.
        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = (constraints.maxWidth / 150)
                .floor()
                .clamp(2, 6);
            return GridView.builder(
              padding: const EdgeInsets.all(AppDimens.photosGridSpacing),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: AppDimens.photosGridSpacing,
                crossAxisSpacing: AppDimens.photosGridSpacing,
              ),
              itemCount: photos.length,
              itemBuilder: (context, i) {
                return GestureDetector(
                  key: ValueKey('photo-cell-$i'),
                  onTap: () => context.read<PhotosBloc>().add(SelectPhoto(i)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppDimens.photosThumbRadius,
                    ),
                    child: Image.asset(
                      photos[i],
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _PhotoViewer extends StatefulWidget {
  final int index;
  final List<String> photos;

  const _PhotoViewer({required this.index, required this.photos});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  /// Huge page count, multiple of the photo count, so the viewer can
  /// swipe endlessly in both directions and page % count stays
  /// aligned with the real photo index.
  static const int _pageLoop = 100000 * 1000;

  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.index;
    _controller = PageController(initialPage: _pageLoop + widget.index);
  }

  @override
  void didUpdateWidget(covariant _PhotoViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index &&
        identical(oldWidget.photos, widget.photos)) {
      return;
    }
    _index = widget.index;
    // Keep the page in sync when the index changes from outside the
    // swipe (grid tap), taking the shortest wrap direction.
    final count = widget.photos.length;
    final page = _controller.hasClients
        ? _controller.page!.round()
        : _pageLoop + oldWidget.index;
    var delta = (widget.index - (page % count)) % count;
    if (delta > count / 2) delta -= count;
    if (delta < -count / 2) delta += count;
    if (delta != 0) {
      _controller.animateToPage(
        page + delta,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PhotosBloc>();
    final strings = AppLocalizations.of(context)!;
    final photos = widget.photos;
    final count = photos.length;

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _controller,
              itemCount: null,
              onPageChanged: (page) {
                final newIndex = page % count;
                if (newIndex == _index) return;
                setState(() => _index = newIndex);
                bloc.add(SelectPhoto(newIndex));
              },
              itemBuilder: (context, page) {
                final photoIndex = page % count;
                return InteractiveViewer(
                  maxScale: 4,
                  panEnabled: false,
                  child: Center(
                    child: Image.asset(
                      photos[photoIndex],
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: IconButton(
              onPressed: () => bloc.add(ClosePhotoViewer()),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
              ),
              tooltip: strings.photosBackToGallery,
            ),
          ),
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                onPressed: () => bloc.add(
                  SelectPhoto((_index - 1 + count) % count),
                ),
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                onPressed: () => bloc.add(
                  SelectPhoto((_index + 1) % count),
                ),
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Preview root with both photos overlays, like the real home page and
/// the widget-test harness. `PhotosBloc()` takes no deps and the grid
/// uses bundled `Image.asset` photos, so the preview stays hermetic.
Widget _photosPreviewRoot(PhotosBloc bloc) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: BlocProvider.value(
      value: bloc,
      child: const Scaffold(
        body: Stack(
          children: [PhotosWindowOverlay(), PhotosPinOverlay()],
        ),
      ),
    ),
  );
}

@Preview(
  name: 'PhotosWindowOverlay - private',
  group: 'Photos',
  size: Size(1200, 800),
)
Widget photosWindowOverlayPreview() {
  return _photosPreviewRoot(
    PhotosBloc()
      ..add(TogglePhotosWindow())
      ..add(SubmitPhotosPin(vaultPin)),
  );
}

@Preview(
  name: 'PhotosWindowOverlay - general',
  group: 'Photos',
  size: Size(1200, 800),
)
Widget photosWindowOverlayGuestPreview() {
  return _photosPreviewRoot(
    PhotosBloc()
      ..add(TogglePhotosWindow())
      ..add(ViewGeneralPhotos()),
  );
}

