import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jent_web/core/constants/vault_pin.dart';
import 'package:jent_web/core/theme/app_dimens.dart';
import 'package:jent_web/core/widgets/window/window_resize_handles.dart';
import 'package:jent_web/core/widgets/window/window_title_bar.dart';
import 'package:jent_web/data/datasources/notes_remote_datasource.dart';
import 'package:jent_web/domain/entities/note_item.dart';
import 'package:jent_web/l10n/app_localizations.dart';
import 'package:jent_web/features/notes/bloc/notes_bloc.dart';
import 'package:jent_web/features/notes/bloc/notes_event.dart';
import 'package:jent_web/features/notes/bloc/notes_state.dart';
import 'package:jent_web/features/notes/view/notes_pin_overlay.dart';

/// Floating macOS-Notes-style window: folders sidebar, notes list and
/// editor. Uses the shared [WindowTitleBar] (traffic lights + drag
/// area) and [WindowResizeHandle]s, like the photo window.
class NotesOverlay extends StatefulWidget {
  const NotesOverlay({super.key});

  @override
  State<NotesOverlay> createState() => _NotesOverlayState();
}

class _NotesOverlayState extends State<NotesOverlay> {
  /// Local window frame. Null means "use the preset size, centered".
  final ValueNotifier<Rect?> _frame = ValueNotifier(null);
  bool? _lastExpanded;
  bool _resizing = false;

  static const _minWinSize = Size(
    AppDimens.notesMinWidth,
    AppDimens.notesMinHeight,
  );
  static const _edgeGrip = 10.0;
  static const _cornerGrip = 18.0;

  /// One editing controller per note so typing never fights rebuilds.
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _frame.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  TextEditingController _controllerFor(NoteItem note) {
    return _controllers.putIfAbsent(
      note.id,
      () => TextEditingController(text: note.body),
    );
  }

  Size _baseSize(bool expanded) => expanded
      ? const Size(
          AppDimens.notesExpandedWidth,
          AppDimens.notesExpandedHeight,
        )
      : const Size(AppDimens.notesWindowWidth, AppDimens.notesWindowHeight);

  Rect _defaultFrame(Size screen, Size base) => Rect.fromLTWH(
        (screen.width - base.width) / 2,
        (screen.height - base.height) / 2 - 20,
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
    final base = _baseSize(context.read<NotesBloc>().state.isNotesExpanded);
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
    final base = _baseSize(context.read<NotesBloc>().state.isNotesExpanded);
    final current = _frame.value ?? _defaultFrame(screen, base);
    var left = current.left;
    var top = current.top;
    var right = current.right;
    var bottom = current.bottom;
    if (edges.left) left += delta.dx;
    if (edges.right) right += delta.dx;
    if (edges.top) top += delta.dy;
    if (edges.bottom) bottom += delta.dy;
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
    left = left.clamp(0.0, math.max(0.0, screen.width - _minWinSize.width));
    right = right.clamp(
      _minWinSize.width,
      math.max(_minWinSize.width, screen.width),
    );
    top = top.clamp(0.0, math.max(0.0, screen.height - _minWinSize.height));
    bottom = bottom.clamp(
      _minWinSize.height,
      math.max(_minWinSize.height, screen.height - 24),
    );
    _frame.value = Rect.fromLTRB(left, top, right, bottom);
  }

  void _discardController(String id) {
    _controllers.remove(id)?.dispose();
  }

  @override  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);

    return BlocSelector<NotesBloc, NotesState, _NotesVisibility>(
      selector: (state) => _NotesVisibility(
        show: state.isShowNotesWindow,
        minimized: state.isNotesMinimized,
        expanded: state.isNotesExpanded,
      ),
      builder: (context, vis) {
        if (!vis.show) {
          _frame.value = null;
          _lastExpanded = null;
          return const SizedBox.shrink();
        }
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
                                          bloc.add(CloseNotesWindow()),
                                      onMinimize: () =>
                                          bloc.add(MinimizeNotesWindow()),
                                      onExpand: () =>
                                          bloc.add(ToggleNotesExpanded()),
                                      onPanUpdate: (offset) =>
                                          _onDrag(offset, screen),
                                    ),
                                    _NotesToolbar(
                                      searchController: _searchController,
                                      onDelete: () {
                                        _discardController(
                                          bloc.state.selectedNoteId,
                                        );
                                        bloc.add(DeleteNote());
                                      },
                                    ),
                                    Expanded(
                                      child: _NotesBody(
                                        controllerFor: _controllerFor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          WindowResizeHandle(
                            key: const ValueKey('notes-resize-left'),
                            cursor: SystemMouseCursors.resizeLeftRight,
                            left: 0,
                            top: _cornerGrip,
                            bottom: _cornerGrip,
                            width: _edgeGrip,
                            onResize: (delta) => _onResize(
                              WindowResizeEdges.onLeft,
                              delta,
                              screen,
                            ),
                            onResizeStart: () =>
                                setState(() => _resizing = true),
                            onResizeEnd: () =>
                                setState(() => _resizing = false),
                          ),
                          WindowResizeHandle(
                            key: const ValueKey('notes-resize-right'),
                            cursor: SystemMouseCursors.resizeLeftRight,
                            right: 0,
                            top: _cornerGrip,
                            bottom: _cornerGrip,
                            width: _edgeGrip,
                            onResize: (delta) => _onResize(
                              WindowResizeEdges.onRight,
                              delta,
                              screen,
                            ),
                            onResizeStart: () =>
                                setState(() => _resizing = true),
                            onResizeEnd: () =>
                                setState(() => _resizing = false),
                          ),
                          WindowResizeHandle(
                            key: const ValueKey('notes-resize-top'),
                            cursor: SystemMouseCursors.resizeUpDown,
                            left: _cornerGrip,
                            right: _cornerGrip,
                            top: 0,
                            height: 8,
                            onResize: (delta) => _onResize(
                              WindowResizeEdges.onTop,
                              delta,
                              screen,
                            ),
                            onResizeStart: () =>
                                setState(() => _resizing = true),
                            onResizeEnd: () =>
                                setState(() => _resizing = false),
                          ),
                          WindowResizeHandle(
                            key: const ValueKey('notes-resize-bottom'),
                            cursor: SystemMouseCursors.resizeUpDown,
                            left: _cornerGrip,
                            right: _cornerGrip,
                            bottom: 0,
                            height: _edgeGrip,
                            onResize: (delta) => _onResize(
                              WindowResizeEdges.onBottom,
                              delta,
                              screen,
                            ),
                            onResizeStart: () =>
                                setState(() => _resizing = true),
                            onResizeEnd: () =>
                                setState(() => _resizing = false),
                          ),
                          WindowResizeHandle(
                            key: const ValueKey('notes-resize-topLeft'),
                            cursor: SystemMouseCursors
                                .resizeUpLeftDownRight,
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
                            key: const ValueKey('notes-resize-topRight'),
                            cursor: SystemMouseCursors
                                .resizeUpRightDownLeft,
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
                            key: const ValueKey('notes-resize-bottomLeft'),
                            cursor: SystemMouseCursors
                                .resizeUpRightDownLeft,
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
                            key: const ValueKey(
                              'notes-resize-bottomRight',
                            ),
                            cursor: SystemMouseCursors
                                .resizeUpLeftDownRight,
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

  NotesBloc get bloc => context.read<NotesBloc>();
}

class _NotesVisibility {
  final bool show;
  final bool minimized;
  final bool expanded;

  const _NotesVisibility({
    required this.show,
    required this.minimized,
    required this.expanded,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _NotesVisibility &&
          show == other.show &&
          minimized == other.minimized &&
          expanded == other.expanded;

  @override
  int get hashCode => Object.hash(show, minimized, expanded);
}

/// Toolbar under the title bar: search on the left, delete + compose
/// actions on the right, like macOS Notes.
class _NotesToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onDelete;

  const _NotesToolbar({
    required this.searchController,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final bloc = context.read<NotesBloc>();
    final canDelete = context.select<NotesBloc, bool>(
      (b) => b.state.selectedNoteId.isNotEmpty,
    );
    // Guests can search but not edit: hide the edit actions.
    final guest = context.select<NotesBloc, bool>(
      (b) => b.state.isNotesGeneralMode,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F7),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E2E6))),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 32,
              child: TextField(
                controller: searchController,
                onChanged: (value) => bloc.add(UpdateNotesQuery(value)),
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: strings.notesSearchHint,
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E8E93),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: Color(0xFF8E8E93),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 0,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFE3E3E8),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (!guest) ...[
            IconButton(
              onPressed: canDelete ? onDelete : null,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: strings.notesDeleteNote,
              color: const Color(0xFF3A3A3C),
              disabledColor: const Color(0xFFC7C7CC),
            ),
            IconButton(
              onPressed: () => bloc.add(CreateNote()),
              icon: const Icon(Icons.edit_square),
              tooltip: strings.notesNewNote,
              color: const Color(0xFF3A3A3C),
            ),
          ],
        ],
      ),
    );
  }
}

/// Folders sidebar + notes list + editor.
class _NotesBody extends StatelessWidget {
  final TextEditingController Function(NoteItem note) controllerFor;

  const _NotesBody({
    required this.controllerFor,
  });

  static const _folders = ['all', 'notes', 'work', 'general'];

  static const _folderIcons = {
    'all': Icons.cloud_outlined,
    'notes': Icons.folder_outlined,
    'work': Icons.folder_outlined,
    'general': Icons.people_outline_rounded,
  };

  static const _folderNames = {
    'all': 'All',
    'notes': 'Notes',
    'work': 'Work',
    'general': 'General',
  };

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return BlocSelector<NotesBloc, NotesState, _NotesSnapshot>(
      selector: (state) => _NotesSnapshot(
        notes: state.notes,
        visible: state.visibleNotes,
        selectedId: state.selectedNoteId,
        folder: state.selectedNotesFolder,
        query: state.notesQuery,
        general: state.isNotesGeneralMode,
      ),
      builder: (context, snap) {
        final bloc = context.read<NotesBloc>();
        NoteItem? selected;
        for (final note in snap.notes) {
          if (note.id == snap.selectedId) {
            selected = note;
            break;
          }
        }
        // Guests only ever see the general folder.
        final folders = snap.general ? const ['general'] : _NotesBody._folders;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Folders sidebar.
            Container(
              width: 168,
              color: const Color(0xFFF5F5F7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                    child: Text(
                      strings.notesFolders,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                  ...folders.map(
                    (folder) => _FolderTile(
                      name: _folderNames[folder]!,
                      icon: _folderIcons[folder]!,
                      count: snap.folderCount(folder, snap.notes),
                      selected: snap.general || snap.folder == folder,
                      onTap: () => bloc.add(SelectNotesFolder(folder)),
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            // Notes list.
            SizedBox(
              width: 216,
              child: snap.visible.isEmpty
                  ? Center(
                      child: Text(
                        strings.notesEmpty,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: snap.visible.length,
                      separatorBuilder: (_, _) => const Padding(
                        padding: EdgeInsets.only(left: 14),
                        child: Divider(height: 1, thickness: 0.5),
                      ),
                      itemBuilder: (context, i) {
                        final note = snap.visible[i];
                        final isSelected = note.id == snap.selectedId;
                        return _NoteTile(
                          note: note,
                          selected: isSelected,
                          onTap: () => bloc.add(SelectNote(note.id)),
                        );
                      },
                    ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            // Editor.
            Expanded(
              child: selected == null
                  ? Center(
                      child: Text(
                        strings.notesEmpty,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    )
                  : _NotesEditor(
                      key: ValueKey('notes-editor-${selected.id}'),
                      note: selected,
                      controller: controllerFor(selected),
                      readOnly: snap.general,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _NotesSnapshot {
  final List<NoteItem> notes;
  final List<NoteItem> visible;
  final String selectedId;
  final String folder;
  final String query;
  final bool general;

  const _NotesSnapshot({
    required this.notes,
    required this.visible,
    required this.selectedId,
    required this.folder,
    required this.query,
    required this.general,
  });

  int folderCount(String folder, List<NoteItem> all) {
    if (folder == 'all') return all.length;
    return all.where((note) => note.folder == folder).length;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _NotesSnapshot &&
          identical(notes, other.notes) &&
          identical(visible, other.visible) &&
          selectedId == other.selectedId &&
          folder == other.folder &&
          query == other.query &&
          general == other.general;

  @override
  int get hashCode =>
      Object.hash(notes, visible, selectedId, folder, query, general);
}

class _FolderTile extends StatelessWidget {
  final String name;
  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FolderTile({
    required this.name,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: selected
            ? const Color(0xFFDCDCE0)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Icon(icon, size: 17, color: const Color(0xFF007AFF)),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final NoteItem note;
  final bool selected;
  final VoidCallback onTap;

  const _NoteTile({
    required this.note,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          selected ? const Color(0xFFE8F0FE) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    _formatListDate(note.updatedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF3A3A3C),
                    ),
                  ),
                  if (note.snippet.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        note.snippet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full editor: centered date header plus the expanding body field.
class _NotesEditor extends StatelessWidget {
  final NoteItem note;
  final TextEditingController controller;
  final bool readOnly;

  const _NotesEditor({
    super.key,
    required this.note,
    required this.controller,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<NotesBloc>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _formatEditorDate(note.updatedAt),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF1C1C1E),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: false,
              ),
              onChanged: (value) => bloc.add(UpdateNoteBody(value)),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatListDate(DateTime date) =>
    '${date.day}/${date.month}/${date.year}';

String _formatEditorDate(DateTime date) =>
    '${date.day}/${date.month}/${date.year} at '
    '${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}';

/// Preview root with both notes overlays, like the real home page and
/// the widget-test harness. `NotesRemoteDataSource()` is inert offline
/// (Supabase unconfigured → local seeds), so the preview stays hermetic.
Widget _notesPreviewRoot(NotesBloc bloc) {
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
          children: [NotesOverlay(), NotesPinOverlay()],
        ),
      ),
    ),
  );
}

@Preview(name: 'NotesOverlay - open', group: 'Notes', size: Size(1200, 800))
Widget notesOverlayPreview() {
  return _notesPreviewRoot(
    NotesBloc(NotesRemoteDataSource())
      ..add(ToggleNotesWindow())
      ..add(SubmitNotesPin(vaultPin)),
  );
}

@Preview(name: 'NotesOverlay - guest', group: 'Notes', size: Size(1200, 800))
Widget notesOverlayGuestPreview() {
  return _notesPreviewRoot(
    NotesBloc(NotesRemoteDataSource())
      ..add(ToggleNotesWindow())
      ..add(ViewGeneralNotes()),
  );
}
