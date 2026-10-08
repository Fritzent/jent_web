import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jent_web/l10n/app_localizations.dart';
import 'package:jent_web/features/photos/bloc/photos_bloc.dart';
import 'package:jent_web/features/photos/bloc/photos_event.dart';
import 'package:jent_web/features/photos/bloc/photos_state.dart';

/// PIN gate for the Photos window, styled after Apple's Human Interface
/// Guidelines (iOS/macOS Settings): grouped cards, list-style rows with
/// hairline dividers, SF-style hierarchy and Apple blue accents.
/// Rendered above the desktop when the dock opens Photos while locked.
/// Wrong PIN swaps this card for the access-denied popup.
class PhotosPinOverlay extends StatefulWidget {
  const PhotosPinOverlay({super.key});

  @override
  State<PhotosPinOverlay> createState() => _PhotosPinOverlayState();
}

class _PhotosPinOverlayState extends State<PhotosPinOverlay> {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<PhotosBloc, PhotosState, _PinGateSnapshot>(
      selector: (state) => _PinGateSnapshot(
        pinVisible: state.isPhotosPinVisible,
        deniedVisible: state.isPhotosDeniedVisible,
      ),
      builder: (context, snap) {
        return Stack(
          children: [
            if (snap.pinVisible)
              const _PinCard(key: ValueKey('photos-pin-card')),
            if (snap.deniedVisible) const _DeniedCard(),
          ],
        );
      },
    );
  }
}

class _PinGateSnapshot {
  final bool pinVisible;
  final bool deniedVisible;

  const _PinGateSnapshot({
    required this.pinVisible,
    required this.deniedVisible,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PinGateSnapshot &&
          pinVisible == other.pinVisible &&
          deniedVisible == other.deniedVisible;

  @override
  int get hashCode => Object.hash(pinVisible, deniedVisible);
}

/// Apple palette tokens used by this overlay.
class _AppleTokens {
  final bool dark;
  const _AppleTokens(this.dark);

  static _AppleTokens of(BuildContext context) =>
      _AppleTokens(Theme.of(context).brightness == Brightness.dark);

  Color get pageDim => const Color(0xFF000000).withValues(alpha: 0.45);
  // Soft "dove" neutrals: warm gray-beige surfaces.
  Color get card => dark ? const Color(0xFF2B2926) : const Color(0xFFE9E4DA);
  Color get group => dark ? const Color(0xFF3A3733) : const Color(0xFFDBD4C6);
  Color get hairline =>
      dark ? Colors.white.withValues(alpha: 0.14) : const Color(0xFFC4BCAC);
  Color get title => dark ? const Color(0xFFEDE8DE) : const Color(0xFF2E2B26);
  Color get body => dark ? const Color(0xFFD6D0C2) : const Color(0xFF57534A);
  Color get secondary =>
      dark ? const Color(0xFFA39C8C) : const Color(0xFF8A8474);
  Color get accent => dark ? const Color(0xFFF472B4) : const Color(0xFFEC4899);
  Color get accentOnWhite => Colors.white;
  Color get secondaryButton =>
      dark ? const Color(0xFF3A3733) : const Color(0xFFD6CFC1);
  Color get secondaryButtonText =>
      dark ? const Color(0xFFEDE8DE) : const Color(0xFF2E2B26);
  Color get danger => dark ? const Color(0xFFF4709A) : const Color(0xFFE8447A);
}

class _PinCard extends StatefulWidget {
  const _PinCard({super.key});

  @override
  State<_PinCard> createState() => _PinCardState();
}

class _PinCardState extends State<_PinCard> {
  final _pinController = TextEditingController();
  final _pinFocus = FocusNode();

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) return;
    context.read<PhotosBloc>().add(SubmitPhotosPin(pin));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final bloc = context.read<PhotosBloc>();
    final t = _AppleTokens.of(context);

    return Positioned.fill(
      child: Container(
        color: t.pageDim,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.97, end: 1),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: t.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: t.hairline, width: 0.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cute Kirby-inspired mascot (drawn in code, no assets).
                      const Center(child: _CuteIcon()),
                      const SizedBox(height: 14),
                      Text(
                        strings.photosPinTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily:
                              '-apple-system, San Francisco, Helvetica Neue, sans-serif',
                          fontFamilyFallback: const [
                            'San Francisco',
                            'Helvetica Neue',
                            'sans-serif',
                          ],
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          color: t.title,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter your 4-digit code to view the gallery.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: t.secondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Bullets-only passcode field. The hidden TextField
                      // below captures keyboard input; only the bullets
                      // are visible. Tapping the bullets focuses input.
                      GestureDetector(
                        onTap: () => _pinFocus.requestFocus(),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _pinController,
                            builder: (context, value, _) {
                              final len = value.text
                                  .trim()
                                  .length
                                  .clamp(0, 4);
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(4, (i) {
                                  final filled = i < len;
                                  return AnimatedContainer(
                                    duration: const Duration(
                                      milliseconds: 160,
                                    ),
                                    curve: Curves.easeOutCubic,
                                    width: 20,
                                    height: 20,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: filled
                                          ? t.accent
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: filled
                                            ? t.accent
                                            : t.secondary.withValues(
                                                alpha: 0.6,
                                              ),
                                        width: 1.6,
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ),
                      ),
                      // Hidden input: invisible but focusable, keeps
                      // autofocus, keyboard entry and tests working.
                      Opacity(
                        opacity: 0.0,
                        child: SizedBox(
                          height: 1,
                          child: TextField(
                            controller: _pinController,
                            focusNode: _pinFocus,
                            autofocus: true,
                            obscureText: true,
                            obscuringCharacter: '•',
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            textAlign: TextAlign.center,
                            cursorColor: Colors.transparent,
                            style: const TextStyle(
                              fontSize: 1,
                              color: Colors.transparent,
                            ),
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Primary action.
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style:
                              ElevatedButton.styleFrom(
                                backgroundColor: t.accent,
                                foregroundColor: t.accentOnWhite,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ).copyWith(
                                backgroundColor:
                                    WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(
                                        WidgetState.pressed,
                                      )) {
                                        return t.accent.withValues(alpha: 0.85);
                                      }
                                      if (states.contains(
                                        WidgetState.hovered,
                                      )) {
                                        return t.accent.withValues(alpha: 0.92);
                                      }
                                      return t.accent;
                                    }),
                              ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                strings.photosPinUnlock,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.lock_open_rounded,
                                size: 17,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Secondary action.
                      SizedBox(
                        height: 48,
                        child: TextButton(
                          onPressed: () => bloc.add(DismissPhotosPin()),
                          style: TextButton.styleFrom(
                            backgroundColor: t.secondaryButton,
                            foregroundColor: t.secondaryButtonText,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            strings.photosPinCancel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kirby-inspired kawaii blob drawn with flat shapes (no image assets):
/// pink round body, stubby arms, red feet and a happy/sad face.
class _CuteIcon extends StatelessWidget {
  final bool sad;

  const _CuteIcon({this.sad = false});

  static const _body = Color(0xFFFFA8C5);
  static const _limb = Color(0xFFFF8FB3);
  static const _feet = Color(0xFFE14D7A);
  static const _ink = Color(0xFF3A2B33);
  static const _cheek = Color(0xFFF9708F);
  static const _tear = Color(0xFF9CD3FF);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Stubby arms behind the body.
          Positioned(
            left: 6,
            top: 32,
            child: Transform.rotate(
              angle: 0.45,
              child: Container(
                width: 17,
                height: 30,
                decoration: BoxDecoration(
                  color: _limb,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
          Positioned(
            right: 6,
            top: 32,
            child: Transform.rotate(
              angle: -0.45,
              child: Container(
                width: 17,
                height: 30,
                decoration: BoxDecoration(
                  color: _limb,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
          // Little feet peeking out below.
          Positioned(
            bottom: 1,
            left: 18,
            child: Container(
              width: 22,
              height: 13,
              decoration: BoxDecoration(
                color: _feet,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
          Positioned(
            bottom: 1,
            right: 18,
            child: Container(
              width: 22,
              height: 13,
              decoration: BoxDecoration(
                color: _feet,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
          // Round body with the face on it.
          Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              color: _body,
              shape: BoxShape.circle,
            ),
            child: Stack(
              children: [
                const Positioned(left: 18, top: 19, child: _Eye()),
                const Positioned(right: 18, top: 19, child: _Eye()),
                Positioned(
                  left: 8,
                  top: 35,
                  child: Container(
                    width: 13,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _cheek.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 35,
                  child: Container(
                    width: 13,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _cheek.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                // Smile (happy) or frown (sad).
                Positioned(
                  left: 0,
                  right: 0,
                  top: 36,
                  child: Center(
                    child: Container(
                      width: 16,
                      height: 9,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: sad
                              ? BorderSide.none
                              : const BorderSide(color: _ink, width: 2.2),
                          top: sad
                              ? const BorderSide(color: _ink, width: 2.2)
                              : BorderSide.none,
                        ),
                        borderRadius: BorderRadius.vertical(
                          bottom: sad
                              ? Radius.zero
                              : const Radius.circular(8),
                          top: sad ? const Radius.circular(8) : Radius.zero,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sweat drop when sad.
          if (sad)
            Positioned(
              right: 12,
              top: 16,
              child: Transform.rotate(
                angle: 0.3,
                child: Container(
                  width: 9,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _tear,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Eye extends StatelessWidget {
  const _Eye();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 11,
      height: 15,
      child: Stack(
        children: [
          Container(
            width: 11,
            height: 15,
            decoration: BoxDecoration(
              color: _CuteIcon._ink,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          Positioned(
            left: 2,
            top: 2,
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeniedCard extends StatelessWidget {
  const _DeniedCard();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final bloc = context.read<PhotosBloc>();
    final t = _AppleTokens.of(context);

    return Positioned.fill(
      child: Container(
        color: t.pageDim,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.97, end: 1),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: t.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: t.hairline, width: 0.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: _CuteIcon(sad: true)),
                      const SizedBox(height: 14),
                      Text(
                        strings.photosAccessDenied,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          color: t.title,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'The PIN you entered is incorrect.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: t.secondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'NOTICE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.6,
                          color: t.secondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: t.group,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 17,
                                color: t.secondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Wrong PIN. Please try again.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: t.body,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: TextButton.icon(
                          onPressed: () => bloc.add(ViewGeneralPhotos()),
                          style: TextButton.styleFrom(
                            backgroundColor: t.secondaryButton,
                            foregroundColor: t.secondaryButtonText,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.photo_library_rounded,
                            size: 17,
                          ),
                          label: Text(
                            strings.photosViewGeneral,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => bloc.add(DismissPhotosDenied()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: t.danger,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            strings.dialogClose,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Preview root for the PIN gate on its own. `PhotosBloc()` takes no
/// deps, so the preview stays hermetic.
Widget _photosPinPreviewRoot(PhotosBloc bloc) {
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
          children: [PhotosPinOverlay()],
        ),
      ),
    ),
  );
}

@Preview(
  name: 'PhotosPinOverlay - PIN entry',
  group: 'Photos',
  size: Size(900, 700),
)
Widget photosPinOverlayPreview() {
  return _photosPinPreviewRoot(
    PhotosBloc()..add(TogglePhotosWindow()),
  );
}

@Preview(
  name: 'PhotosPinOverlay - denied',
  group: 'Photos',
  size: Size(900, 700),
)
Widget photosPinOverlayDeniedPreview() {
  return _photosPinPreviewRoot(
    PhotosBloc()
      ..add(TogglePhotosWindow())
      ..add(SubmitPhotosPin('9999')),
  );
}
