import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jent_web/data/datasources/notes_remote_datasource.dart';
import 'package:jent_web/l10n/app_localizations.dart';
import 'package:jent_web/features/notes/bloc/notes_bloc.dart';
import 'package:jent_web/features/notes/bloc/notes_event.dart';
import 'package:jent_web/features/notes/bloc/notes_state.dart';

/// PIN gate for the Notes window: only someone holding the correct PIN
/// can open it and edit/add notes. Same bullets-only pattern as the
/// photos gate, with a warm notes-yellow accent.
class NotesPinOverlay extends StatefulWidget {
  const NotesPinOverlay({super.key});

  @override
  State<NotesPinOverlay> createState() => _NotesPinOverlayState();
}

class _NotesPinOverlayState extends State<NotesPinOverlay> {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<NotesBloc, NotesState, _NotesPinGateSnapshot>(
      selector: (state) => _NotesPinGateSnapshot(
        pinVisible: state.isNotesPinVisible,
        deniedVisible: state.isNotesDeniedVisible,
      ),
      builder: (context, snap) {
        return Stack(
          children: [
            if (snap.pinVisible)
              const _NotesPinCard(key: ValueKey('notes-pin-card')),
            if (snap.deniedVisible) const _NotesDeniedCard(),
          ],
        );
      },
    );
  }
}

class _NotesPinGateSnapshot {
  final bool pinVisible;
  final bool deniedVisible;

  const _NotesPinGateSnapshot({
    required this.pinVisible,
    required this.deniedVisible,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _NotesPinGateSnapshot &&
          pinVisible == other.pinVisible &&
          deniedVisible == other.deniedVisible;

  @override
  int get hashCode => Object.hash(pinVisible, deniedVisible);
}

/// Warm notes-yellow tokens matching the dove card of the photos gate.
class _NotesTokens {
  final bool dark;
  const _NotesTokens(this.dark);

  static _NotesTokens of(BuildContext context) =>
      _NotesTokens(Theme.of(context).brightness == Brightness.dark);

  Color get pageDim => const Color(0xFF000000).withValues(alpha: 0.45);
  Color get card => dark ? const Color(0xFF2B2926) : const Color(0xFFE9E4DA);
  Color get hairline =>
      dark ? Colors.white.withValues(alpha: 0.14) : const Color(0xFFC4BCAC);
  Color get title => dark ? const Color(0xFFEDE8DE) : const Color(0xFF2E2B26);
  Color get secondary =>
      dark ? const Color(0xFFA39C8C) : const Color(0xFF8A8474);
  Color get accent => dark ? const Color(0xFFFFC53D) : const Color(0xFFD99400);
  Color get secondaryButton =>
      dark ? const Color(0xFF3A3733) : const Color(0xFFD6CFC1);
  Color get secondaryButtonText =>
      dark ? const Color(0xFFEDE8DE) : const Color(0xFF2E2B26);
  Color get danger => dark ? const Color(0xFFF4709A) : const Color(0xFFE8447A);
}

class _NotesPinCard extends StatefulWidget {
  const _NotesPinCard({super.key});

  @override
  State<_NotesPinCard> createState() => _NotesPinCardState();
}

class _NotesPinCardState extends State<_NotesPinCard> {
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
    context.read<NotesBloc>().add(SubmitNotesPin(pin));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final bloc = context.read<NotesBloc>();
    final t = _NotesTokens.of(context);

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
                      Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: t.accent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        strings.notesPinTitle,
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
                        'Enter your 4-digit code to edit your notes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: t.secondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Bullets-only field; hidden TextField captures input.
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
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: t.accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                      SizedBox(
                        height: 48,
                        child: TextButton(
                          onPressed: () => bloc.add(DismissNotesPin()),
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

class _NotesDeniedCard extends StatelessWidget {
  const _NotesDeniedCard();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final bloc = context.read<NotesBloc>();
    final t = _NotesTokens.of(context);

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
                      Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: t.danger,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.gpp_bad_rounded,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        strings.notesAccessDenied,
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
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: TextButton.icon(
                          onPressed: () => bloc.add(ViewGeneralNotes()),
                          style: TextButton.styleFrom(
                            backgroundColor: t.secondaryButton,
                            foregroundColor: t.secondaryButtonText,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.notes_rounded,
                            size: 17,
                          ),
                          label: Text(
                            strings.notesViewGeneral,
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
                          onPressed: () => bloc.add(DismissNotesDenied()),
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

/// Preview root for the PIN gate on its own. `NotesRemoteDataSource()`
/// is inert offline (Supabase unconfigured → local seeds), so the
/// preview stays hermetic.
Widget _notesPinPreviewRoot(NotesBloc bloc) {
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
          children: [NotesPinOverlay()],
        ),
      ),
    ),
  );
}

@Preview(
  name: 'NotesPinOverlay - PIN entry',
  group: 'Notes',
  size: Size(900, 700),
)
Widget notesPinOverlayPreview() {
  return _notesPinPreviewRoot(
    NotesBloc(NotesRemoteDataSource())..add(ToggleNotesWindow()),
  );
}

@Preview(
  name: 'NotesPinOverlay - denied',
  group: 'Notes',
  size: Size(900, 700),
)
Widget notesPinOverlayDeniedPreview() {
  return _notesPinPreviewRoot(
    NotesBloc(NotesRemoteDataSource())
      ..add(ToggleNotesWindow())
      ..add(SubmitNotesPin('0000')),
  );
}
