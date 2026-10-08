import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:jent_web/core/constants/vault_pin.dart';
import 'package:jent_web/data/datasources/notes_remote_datasource.dart';
import 'package:jent_web/domain/entities/note_item.dart';
import 'package:jent_web/features/notes/bloc/notes_event.dart';
import 'package:jent_web/features/notes/bloc/notes_state.dart';

@injectable
class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final NotesRemoteDataSource _notesRemote;
  Timer? _notesSaveTimer;

  NotesBloc(this._notesRemote)
      : super(
          NotesState(
            notes: _seedNotes(),
            selectedNoteId: 'welcome',
          ),
        ) {
    on<ToggleNotesWindow>(_onToggleNotesWindow);
    on<CloseNotesWindow>(_onCloseNotesWindow);
    on<MinimizeNotesWindow>(_onMinimizeNotesWindow);
    on<ToggleNotesExpanded>(_onToggleNotesExpanded);
    on<SelectNotesFolder>(_onSelectNotesFolder);
    on<SelectNote>(_onSelectNote);
    on<CreateNote>(_onCreateNote);
    on<DeleteNote>(_onDeleteNote);
    on<UpdateNoteBody>(_onUpdateNoteBody);
    on<UpdateNotesQuery>(_onUpdateNotesQuery);
    on<SubmitNotesPin>(_onSubmitNotesPin);
    on<DismissNotesPin>(_onDismissNotesPin);
    on<DismissNotesDenied>(_onDismissNotesDenied);
    on<NotesRemoteLoaded>(_onNotesRemoteLoaded);
    on<ViewGeneralNotes>(_onViewGeneralNotes);
  }

  /// Sample notes so the window never opens empty. IDs are stable so
  /// tests and the initial selection can rely on them. The 'general'
  /// folder is visible to everyone, no PIN needed.
  static List<NoteItem> _seedNotes() => [
        NoteItem(
          id: 'general-welcome',
          folder: 'general',
          body: 'Welcome!\n\nThese notes are visible to everyone.',
          updatedAt: DateTime(2026, 9, 29, 9, 0),
        ),
        NoteItem(
          id: 'welcome',
          folder: 'notes',
          body: 'Welcome to Notes\n\nIdeas, lists and reminders live here. '
              'Click the compose button to start a new note.',
          updatedAt: DateTime(2026, 9, 28, 9, 0),
        ),
        NoteItem(
          id: 'ideas',
          folder: 'work',
          body: 'Website ideas\n\n- Cute PIN gate for photos\n- macOS-style dock\n- Guest photo album',
          updatedAt: DateTime(2026, 9, 27, 15, 30),
        ),
      ];

  void _onToggleNotesWindow(
    ToggleNotesWindow event,
    Emitter<NotesState> emit,
  ) {
    // Window open: lock it again and hide it. Next open must go
    // through the PIN gate.
    if (state.isShowNotesWindow) {
      emit(
        state.copyWith(
          isShowNotesWindow: false,
          isNotesMinimized: false,
          isNotesExpanded: false,
          isNotesLocked: true,
          isNotesPinVisible: false,
          isNotesDeniedVisible: false,
          isNotesGeneralMode: false,
        ),
      );
      return;
    }
    // Restoring a minimized guest album needs no PIN: general notes
    // are public.
    if (state.isNotesMinimized && state.isNotesGeneralMode) {
      emit(
        state.copyWith(
          isShowNotesWindow: true,
          isNotesMinimized: false,
          isNotesExpanded: false,
          isNotesLocked: true,
          isNotesPinVisible: false,
          isNotesDeniedVisible: false,
          isNotesGeneralMode: true,
        ),
      );
      return;
    }
    // Opening (fresh or from minimize) always requires the PIN.
    emit(
      state.copyWith(
        isShowNotesWindow: false,
        isNotesLocked: true,
        isNotesPinVisible: true,
        isNotesDeniedVisible: false,
        isNotesGeneralMode: false,
      ),
    );
  }

  void _onSubmitNotesPin(
    SubmitNotesPin event,
    Emitter<NotesState> emit,
  ) {
    if (event.pin == vaultPin) {
      emit(
        state.copyWith(
          isNotesPinVisible: false,
          isNotesDeniedVisible: false,
          isNotesLocked: false,
          isShowNotesWindow: true,
          isNotesMinimized: false,
          isNotesExpanded: false,
        ),
      );
      unawaited(_refreshNotesFromRemote());
    } else {
      emit(
        state.copyWith(
          isNotesPinVisible: false,
          isNotesDeniedVisible: true,
          isNotesLocked: true,
        ),
      );
    }
  }

  void _onDismissNotesPin(DismissNotesPin event, Emitter<NotesState> emit) {
    emit(
      state.copyWith(
        isNotesPinVisible: false,
        isNotesLocked: true,
      ),
    );
  }

  void _onDismissNotesDenied(
    DismissNotesDenied event,
    Emitter<NotesState> emit,
  ) {
    // Return to the PIN prompt so the user can retry immediately.
    emit(
      state.copyWith(
        isNotesDeniedVisible: false,
        isNotesPinVisible: true,
        isNotesLocked: true,
      ),
    );
  }

  /// Pulls the shared notes after unlocking. Remote wins when it has
  /// rows; local seeds stay as the offline fallback.
  Future<void> _refreshNotesFromRemote() async {
    final remote = await _notesRemote.fetchNotes();
    if (remote == null || remote.isEmpty) return;
    add(NotesRemoteLoaded(remote));
  }

  void _onNotesRemoteLoaded(
    NotesRemoteLoaded event,
    Emitter<NotesState> emit,
  ) {
    final selectedStillThere =
        event.notes.any((note) => note.id == state.selectedNoteId);
    emit(
      state.copyWith(
        notes: event.notes,
        selectedNoteId: selectedStillThere
            ? state.selectedNoteId
            : _firstVisibleId(event.notes, state.selectedNotesFolder),
      ),
    );
  }

  void _onViewGeneralNotes(
    ViewGeneralNotes event,
    Emitter<NotesState> emit,
  ) {
    // Guest mode: show the general folder. Editing stays locked and
    // the private folders stay hidden.
    final general = state.notes
        .where((note) => note.folder == 'general')
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    emit(
      state.copyWith(
        isNotesDeniedVisible: false,
        isNotesPinVisible: false,
        isNotesLocked: true,
        isShowNotesWindow: true,
        isNotesMinimized: false,
        isNotesExpanded: false,
        isNotesGeneralMode: true,
        selectedNotesFolder: 'general',
        selectedNoteId: general.isEmpty ? '' : general.first.id,
      ),
    );
    unawaited(_refreshNotesFromRemote());
  }

  void _onCloseNotesWindow(
    CloseNotesWindow event,
    Emitter<NotesState> emit,
  ) {
    emit(
      state.copyWith(
        isShowNotesWindow: false,
        isNotesMinimized: false,
        isNotesExpanded: false,
        isNotesLocked: true,
        isNotesPinVisible: false,
        isNotesDeniedVisible: false,
        isNotesGeneralMode: false,
      ),
    );
  }

  void _onMinimizeNotesWindow(
    MinimizeNotesWindow event,
    Emitter<NotesState> emit,
  ) {
    emit(
      state.copyWith(
        isShowNotesWindow: false,
        isNotesMinimized: true,
        isNotesExpanded: false,
        isNotesLocked: true,
        isNotesPinVisible: false,
        isNotesDeniedVisible: false,
      ),
    );
  }

  void _onToggleNotesExpanded(
    ToggleNotesExpanded event,
    Emitter<NotesState> emit,
  ) {
    emit(state.copyWith(isNotesExpanded: !state.isNotesExpanded));
  }

  void _onSelectNotesFolder(
    SelectNotesFolder event,
    Emitter<NotesState> emit,
  ) {
    // Guests stay on the general folder.
    if (state.isNotesGeneralMode) return;
    emit(state.copyWith(selectedNotesFolder: event.folder));
  }

  void _onSelectNote(SelectNote event, Emitter<NotesState> emit) {
    if (!state.isShowNotesWindow) return;
    if (!state.notes.any((note) => note.id == event.id)) return;
    emit(state.copyWith(selectedNoteId: event.id));
  }

  void _onCreateNote(CreateNote event, Emitter<NotesState> emit) {
    // Editing requires the PIN unlock, even in guest mode.
    if (state.isNotesLocked) return;
    final note = NoteItem(
      id: 'note-${DateTime.now().microsecondsSinceEpoch}',
      folder: state.selectedNotesFolder == 'all'
          ? 'notes'
          : state.selectedNotesFolder,
      body: '',
      updatedAt: DateTime.now(),
    );
    emit(
      state.copyWith(
        notes: [note, ...state.notes],
        selectedNoteId: note.id,
        isShowNotesWindow: true,
        isNotesMinimized: false,
      ),
    );
    unawaited(_notesRemote.saveNote(note));
  }

  void _onDeleteNote(DeleteNote event, Emitter<NotesState> emit) {
    if (state.isNotesLocked) return;
    final deletedId = state.selectedNoteId;
    final remaining =
        state.notes.where((note) => note.id != deletedId).toList();
    emit(
      state.copyWith(
        notes: remaining,
        selectedNoteId:
            _firstVisibleId(remaining, state.selectedNotesFolder),
      ),
    );
    unawaited(_notesRemote.deleteNote(deletedId));
  }

  void _onUpdateNoteBody(UpdateNoteBody event, Emitter<NotesState> emit) {
    if (state.isNotesLocked) return;
    final updated = state.notes
        .map(
          (note) => note.id == state.selectedNoteId
              ? note.copyWith(body: event.body, updatedAt: DateTime.now())
              : note,
        )
        .toList();
    emit(state.copyWith(notes: updated));
    // Debounced write-through so every keystroke doesn't hit the API.
    _notesSaveTimer?.cancel();
    final selectedId = state.selectedNoteId;
    _notesSaveTimer = Timer(const Duration(milliseconds: 800), () {
      NoteItem? saved;
      for (final n in updated) {
        if (n.id == selectedId) {
          saved = n;
          break;
        }
      }
      if (saved != null) unawaited(_notesRemote.saveNote(saved));
    });
  }

  void _onUpdateNotesQuery(UpdateNotesQuery event, Emitter<NotesState> emit) {
    emit(state.copyWith(notesQuery: event.query));
  }

  String _firstVisibleId(List<NoteItem> notes, String folder) {
    final visible = notes
        .where((note) => folder == 'all' || note.folder == folder)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return visible.isEmpty ? '' : visible.first.id;
  }

  @override
  Future<void> close() {
    _notesSaveTimer?.cancel();
    return super.close();
  }
}
