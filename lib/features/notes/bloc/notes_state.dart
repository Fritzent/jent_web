import 'package:jent_web/domain/entities/note_item.dart';

class NotesState {
  final bool isShowNotesWindow;
  final bool isNotesMinimized;
  final bool isNotesExpanded;
  final List<NoteItem> notes;
  final String selectedNoteId;
  final String selectedNotesFolder;
  final String notesQuery;
  final bool isNotesLocked;
  final bool isNotesPinVisible;
  final bool isNotesDeniedVisible;

  /// When true, the Notes window shows the general folder without
  /// unlocking (opened from the access-denied card). Editing stays
  /// locked; the private folders stay hidden.
  final bool isNotesGeneralMode;

  const NotesState({
    this.isShowNotesWindow = false,
    this.isNotesMinimized = false,
    this.isNotesExpanded = false,
    this.notes = const [],
    this.selectedNoteId = '',
    this.selectedNotesFolder = 'all',
    this.notesQuery = '',
    this.isNotesLocked = true,
    this.isNotesPinVisible = false,
    this.isNotesDeniedVisible = false,
    this.isNotesGeneralMode = false,
  });

  NotesState copyWith({
    bool? isShowNotesWindow,
    bool? isNotesMinimized,
    bool? isNotesExpanded,
    List<NoteItem>? notes,
    String? selectedNoteId,
    String? selectedNotesFolder,
    String? notesQuery,
    bool? isNotesLocked,
    bool? isNotesPinVisible,
    bool? isNotesDeniedVisible,
    bool? isNotesGeneralMode,
  }) {
    return NotesState(
      isShowNotesWindow: isShowNotesWindow ?? this.isShowNotesWindow,
      isNotesMinimized: isNotesMinimized ?? this.isNotesMinimized,
      isNotesExpanded: isNotesExpanded ?? this.isNotesExpanded,
      notes: notes ?? this.notes,
      selectedNoteId: selectedNoteId ?? this.selectedNoteId,
      selectedNotesFolder:
          selectedNotesFolder ?? this.selectedNotesFolder,
      notesQuery: notesQuery ?? this.notesQuery,
      isNotesLocked: isNotesLocked ?? this.isNotesLocked,
      isNotesPinVisible: isNotesPinVisible ?? this.isNotesPinVisible,
      isNotesDeniedVisible:
          isNotesDeniedVisible ?? this.isNotesDeniedVisible,
      isNotesGeneralMode:
          isNotesGeneralMode ?? this.isNotesGeneralMode,
    );
  }

  /// Notes visible in the list pane after folder + search filtering,
  /// newest first. In guest (general) mode only the general folder
  /// is visible, so private notes never leak.
  List<NoteItem> get visibleNotes {
    final query = notesQuery.trim().toLowerCase();
    final filtered = notes.where((note) {
      if (isNotesGeneralMode) {
        if (note.folder != 'general') return false;
      } else if (selectedNotesFolder != 'all' &&
          note.folder != selectedNotesFolder) {
        return false;
      }
      if (query.isEmpty) return true;
      return note.title.toLowerCase().contains(query) ||
          note.body.toLowerCase().contains(query);
    }).toList();
    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return filtered;
  }

  /// Number of notes in a folder (ignores the search query).
  int notesInFolder(String folder) {
    if (folder == 'all') return notes.length;
    return notes.where((note) => note.folder == folder).length;
  }
}
