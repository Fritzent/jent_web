import 'package:injectable/injectable.dart';
import 'package:jent_web/core/supabase/supabase_config.dart';
import 'package:jent_web/domain/entities/note_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote storage for notes on the public `notes` table.
/// Registered as a lazy singleton via injectable.
///
/// All methods are offline-safe: when Supabase isn't configured or the
/// network fails they return a fallback (`null`/`false`) instead of
/// throwing, so the app keeps working with local notes.
///
/// Table SQL (run once in the Supabase SQL editor):
///
/// ```sql
/// create table notes (
///   id text primary key,
///   folder text not null default 'notes',
///   body text not null default '',
///   updated_at timestamptz not null default now()
/// );
/// alter table notes enable row level security;
/// -- Demo policy: anyone with the anon key can read/write.
/// -- Tighten this (e.g. require Supabase Auth) before real use.
/// create policy "anon all" on notes
///   for all to anon using (true) with check (true);
/// ```
@lazySingleton
class NotesRemoteDataSource {
  static const _table = 'notes';

  SupabaseClient? get _client {
    try {
      if (!SupabaseConfig.isConfigured) return null;
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Returns remote notes newest-first, or `null` when unavailable.
  Future<List<NoteItem>?> fetchNotes() async {
    final client = _client;
    if (client == null) return null;
    try {
      final rows = await client
          .from(_table)
          .select()
          .order('updated_at', ascending: false);
      return (rows as List)
          .map((row) => NoteItem.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Inserts or updates one note. Returns false when unavailable.
  Future<bool> saveNote(NoteItem note) async {
    final client = _client;
    if (client == null) return false;
    try {
      await client.from(_table).upsert(note.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Deletes one note. Returns false when unavailable.
  Future<bool> deleteNote(String id) async {
    final client = _client;
    if (client == null) return false;
    try {
      await client.from(_table).delete().eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }
}
