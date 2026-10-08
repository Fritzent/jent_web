import 'package:jent_web/domain/entities/note_item.dart';

abstract class NotesEvent {}

class ToggleNotesWindow extends NotesEvent {}

class CloseNotesWindow extends NotesEvent {}

class MinimizeNotesWindow extends NotesEvent {}

class ToggleNotesExpanded extends NotesEvent {}

class SelectNotesFolder extends NotesEvent {
  final String folder;

  SelectNotesFolder(this.folder);
}

class SelectNote extends NotesEvent {
  final String id;

  SelectNote(this.id);
}

class CreateNote extends NotesEvent {}

class DeleteNote extends NotesEvent {}

class UpdateNoteBody extends NotesEvent {
  final String body;

  UpdateNoteBody(this.body);
}

class UpdateNotesQuery extends NotesEvent {
  final String query;

  UpdateNotesQuery(this.query);
}

class SubmitNotesPin extends NotesEvent {
  final String pin;

  SubmitNotesPin(this.pin);
}

class DismissNotesPin extends NotesEvent {}

class DismissNotesDenied extends NotesEvent {}

class NotesRemoteLoaded extends NotesEvent {
  final List<NoteItem> notes;

  NotesRemoteLoaded(this.notes);
}

/// Opens the Notes window with the general folder after a wrong PIN.
/// Viewing is allowed; editing stays locked.
class ViewGeneralNotes extends NotesEvent {}
