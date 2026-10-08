/// A single note in the Notes window.
class NoteItem {
  final String id;
  final String folder;
  final String body;
  final DateTime updatedAt;

  const NoteItem({
    required this.id,
    required this.folder,
    required this.body,
    required this.updatedAt,
  });

  /// First non-empty line, used as the list title.
  String get title {
    for (final line in body.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return 'New Note';
  }

  /// Preview line under the title: second non-empty line, if any.
  String get snippet {
    var seenFirst = false;
    for (final line in body.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (!seenFirst) {
        seenFirst = true;
        continue;
      }
      return trimmed;
    }
    return '';
  }

  NoteItem copyWith({
    String? folder,
    String? body,
    DateTime? updatedAt,
  }) {
    return NoteItem(
      id: id,
      folder: folder ?? this.folder,
      body: body ?? this.body,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Row shape of the public `notes` table (see table SQL in the
  /// Supabase dashboard setup notes).
  Map<String, dynamic> toMap() => {
        'id': id,
        'folder': folder,
        'body': body,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory NoteItem.fromMap(Map<String, dynamic> map) => NoteItem(
        id: map['id'] as String,
        folder: (map['folder'] as String?) ?? 'notes',
        body: (map['body'] as String?) ?? '',
        updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteItem &&
          id == other.id &&
          folder == other.folder &&
          body == other.body &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(id, folder, body, updatedAt);
}
