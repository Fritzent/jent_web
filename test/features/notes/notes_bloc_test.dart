import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jent_web/data/datasources/notes_remote_datasource.dart';
import 'package:jent_web/domain/entities/note_item.dart';
import 'package:jent_web/features/notes/bloc/notes_bloc.dart';
import 'package:jent_web/features/notes/bloc/notes_event.dart';
import 'package:jent_web/features/notes/bloc/notes_state.dart';

void main() {
  // Unconfigured: Supabase is never initialized in tests, so the
  // datasource always takes the offline path (local notes only).
  NotesBloc buildBloc() => NotesBloc(NotesRemoteDataSource());

  group('notes window', () {
    List<NoteItem> demoNotes() => [
          NoteItem(
            id: 'a',
            folder: 'notes',
            body: 'Shopping\nmilk and eggs',
            updatedAt: DateTime(2026, 9, 27, 10, 0),
          ),
          NoteItem(
            id: 'b',
            folder: 'work',
            body: 'Sprint plan\ntickets first',
            updatedAt: DateTime(2026, 9, 28, 10, 0),
          ),
        ];

    blocTest<NotesBloc, NotesState>(
      'toggle shows the PIN gate; correct PIN unlocks and opens',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(ToggleNotesWindow());
        await Future<void>.delayed(Duration.zero);
        bloc.add(SubmitNotesPin('1234'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(ToggleNotesWindow());
      },
      expect: () => [
        isA<NotesState>()
            .having((s) => s.isNotesPinVisible, 'pin', true)
            .having((s) => s.isNotesLocked, 'locked', true)
            .having((s) => s.isShowNotesWindow, 'shown', false),
        isA<NotesState>()
            .having((s) => s.isShowNotesWindow, 'shown', true)
            .having((s) => s.isNotesLocked, 'locked', false)
            .having((s) => s.isNotesPinVisible, 'pin', false),
        isA<NotesState>()
            .having((s) => s.isShowNotesWindow, 'shown', false)
            .having((s) => s.isNotesLocked, 'locked', true),
      ],
    );

    blocTest<NotesBloc, NotesState>(
      'wrong notes PIN shows denied and dismiss returns to PIN',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(ToggleNotesWindow());
        await Future<void>.delayed(Duration.zero);
        bloc.add(SubmitNotesPin('9999'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(DismissNotesDenied());
      },
      expect: () => [
        isA<NotesState>().having((s) => s.isNotesPinVisible, 'pin', true),
        isA<NotesState>()
            .having((s) => s.isNotesDeniedVisible, 'denied', true)
            .having((s) => s.isNotesPinVisible, 'pin', false),
        isA<NotesState>()
            .having((s) => s.isNotesDeniedVisible, 'denied', false)
            .having((s) => s.isNotesPinVisible, 'pin', true),
      ],
    );

    blocTest<NotesBloc, NotesState>(
      'minimize hides the window but keeps the dock status',
      build: buildBloc,
      seed: () => NotesState(
        isShowNotesWindow: true,
      ),
      act: (bloc) => bloc.add(MinimizeNotesWindow()),
      expect: () => [
        isA<NotesState>()
            .having((s) => s.isShowNotesWindow, 'shown', false)
            .having((s) => s.isNotesMinimized, 'minimized', true),
      ],
    );

    blocTest<NotesBloc, NotesState>(
      'create adds a note in the current folder and selects it',
      build: buildBloc,
      seed: () => NotesState(
        isShowNotesWindow: true,
        isNotesLocked: false,
        notes: demoNotes(),
        selectedNoteId: 'a',
        selectedNotesFolder: 'work',
      ),
      act: (bloc) => bloc.add(CreateNote()),
      expect: () => [
        isA<NotesState>()
            .having((s) => s.notes.length, 'count', 3)
            .having((s) => s.notes.first.folder, 'folder', 'work')
            .having(
              (s) => s.selectedNoteId == 'a',
              'reselected',
              false,
            ),
      ],
    );

    blocTest<NotesBloc, NotesState>(
      'create in the General folder publishes to the guest album',
      build: buildBloc,
      seed: () => NotesState(
        isShowNotesWindow: true,
        isNotesLocked: false,
        notes: demoNotes(),
        selectedNoteId: 'a',
        selectedNotesFolder: 'general',
      ),
      act: (bloc) => bloc.add(CreateNote()),
      expect: () => [
        isA<NotesState>()
            .having((s) => s.notes.length, 'count', 3)
            .having((s) => s.notes.first.folder, 'folder', 'general'),
      ],
    );

    blocTest<NotesBloc, NotesState>(
      'update changes the selected note body',
      build: buildBloc,
      seed: () => NotesState(
        notes: demoNotes(),
        selectedNoteId: 'a',
        isNotesLocked: false,
      ),
      act: (bloc) => bloc.add(UpdateNoteBody('New title\nmore')),
      expect: () => [
        isA<NotesState>()
            .having(
              (s) => s.notes.singleWhere((n) => n.id == 'a').body,
              'body',
              'New title\nmore',
            )
            .having(
              (s) => s.notes.singleWhere((n) => n.id == 'a').title,
              'title',
              'New title',
            ),
      ],
    );

    blocTest<NotesBloc, NotesState>(
      'delete removes the selected note and selects a neighbor',
      build: buildBloc,
      seed: () => NotesState(
        notes: demoNotes(),
        selectedNoteId: 'a',
        isNotesLocked: false,
      ),
      act: (bloc) => bloc.add(DeleteNote()),
      expect: () => [
        isA<NotesState>()
            .having((s) => s.notes.length, 'count', 1)
            .having((s) => s.selectedNoteId, 'selected', 'b'),
      ],
    );

    blocTest<NotesBloc, NotesState>(
      'folder and query filter the visible notes',
      build: buildBloc,
      seed: () => NotesState(
        notes: demoNotes(),
        selectedNotesFolder: 'work',
        notesQuery: 'sprint',
      ),
      act: (bloc) => bloc.add(SelectNotesFolder('all')),
      expect: () => [
        isA<NotesState>().having(
          (s) => s.visibleNotes.map((n) => n.id).toList(),
          'visible',
          ['b'],
        ),
      ],
    );

    blocTest<NotesBloc, NotesState>(
      'viewing general notes opens guest mode while staying locked',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(ToggleNotesWindow());
        await Future<void>.delayed(Duration.zero);
        bloc.add(SubmitNotesPin('9999'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(ViewGeneralNotes());
      },
      expect: () => [
        isA<NotesState>().having((s) => s.isNotesPinVisible, 'pin', true),
        isA<NotesState>()
            .having((s) => s.isNotesDeniedVisible, 'denied', true)
            .having((s) => s.isNotesPinVisible, 'pin', false),
        isA<NotesState>()
            .having((s) => s.isShowNotesWindow, 'shown', true)
            .having((s) => s.isNotesDeniedVisible, 'denied', false)
            .having((s) => s.isNotesLocked, 'locked', true)
            .having((s) => s.isNotesGeneralMode, 'general', true)
            .having((s) => s.selectedNotesFolder, 'folder', 'general')
            .having((s) => s.selectedNoteId, 'selected', 'general-welcome'),
      ],
    );

    blocTest<NotesBloc, NotesState>(
      'guest mode shows only general notes',
      build: buildBloc,
      seed: () => NotesState(
        isShowNotesWindow: true,
        isNotesLocked: true,
        isNotesGeneralMode: true,
        selectedNotesFolder: 'general',
        notesQuery: 'welcome',
        notes: [
          NoteItem(
            id: 'general-welcome',
            folder: 'general',
            body: 'Welcome!\n\nEveryone can read this.',
            updatedAt: DateTime(2026, 9, 29, 9, 0),
          ),
          NoteItem(
            id: 'secret',
            folder: 'notes',
            body: 'Welcome to my diary',
            updatedAt: DateTime(2026, 9, 28, 9, 0),
          ),
        ],
      ),
      expect: () => [],
      verify: (bloc) {
        expect(
          bloc.state.visibleNotes.map((n) => n.id).toList(),
          ['general-welcome'],
        );
      },
    );

    blocTest<NotesBloc, NotesState>(
      'writes are ignored while locked',
      build: buildBloc,
      seed: () => NotesState(
        isShowNotesWindow: true,
        isNotesLocked: true,
        isNotesGeneralMode: true,
        selectedNotesFolder: 'general',
        selectedNoteId: 'general-welcome',
      ),
      act: (bloc) async {
        bloc.add(CreateNote());
        await Future<void>.delayed(Duration.zero);
        bloc.add(UpdateNoteBody('hacked'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(DeleteNote());
      },
      expect: () => [],
    );

    blocTest<NotesBloc, NotesState>(
      'toggle restores a minimized guest album without asking PIN',
      build: buildBloc,
      seed: () => NotesState(
        isNotesMinimized: true,
        isNotesLocked: true,
        isNotesGeneralMode: true,
      ),
      act: (bloc) => bloc.add(ToggleNotesWindow()),
      expect: () => [
        isA<NotesState>()
            .having((s) => s.isShowNotesWindow, 'shown', true)
            .having((s) => s.isNotesMinimized, 'minimized', false)
            .having((s) => s.isNotesPinVisible, 'pin', false)
            .having((s) => s.isNotesGeneralMode, 'general', true)
            .having((s) => s.isNotesLocked, 'locked', true),
      ],
    );

    blocTest<NotesBloc, NotesState>(
      'close exits guest mode so private notes stay gated',
      build: buildBloc,
      seed: () => NotesState(
        isShowNotesWindow: true,
        isNotesLocked: true,
        isNotesGeneralMode: true,
      ),
      act: (bloc) async {
        bloc.add(CloseNotesWindow());
        await Future<void>.delayed(Duration.zero);
        bloc.add(ToggleNotesWindow());
      },
      expect: () => [
        isA<NotesState>()
            .having((s) => s.isShowNotesWindow, 'shown', false)
            .having((s) => s.isNotesGeneralMode, 'general', false),
        isA<NotesState>()
            .having((s) => s.isNotesPinVisible, 'pin', true)
            .having((s) => s.isShowNotesWindow, 'shown', false),
      ],
    );
  });
}
