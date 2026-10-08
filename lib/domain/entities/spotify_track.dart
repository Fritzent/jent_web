class SpotifyTrack {
  final String id;
  final String title;
  final String artist;
  final String artworkUrl;
  final Duration duration;

  const SpotifyTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    required this.duration,
  });

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    final artists = (json['artists'] as List? ?? [])
        .whereType<Map>()
        .map((a) => a['name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .join(', ');
    return SpotifyTrack(
      id: json['id'] as String? ?? '',
      title: json['name'] as String? ?? '',
      artist: artists,
      artworkUrl: pickArtwork(json['album'] as Map?),
      duration: Duration(
        milliseconds: (json['duration_ms'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  /// Parses one entry of a playlist items array. Handles the
  /// `GET /v1/playlists/{id}` envelope (`items[].item`), the legacy
  /// `/tracks` envelope (`items[].track`), and bare track objects.
  /// Returns null for unplayable entries (local files, removed tracks).
  static SpotifyTrack? fromPlaylistEntry(Map entry) {
    final dynamic raw =
        entry['item'] ?? entry['track'] ?? entry;
    if (raw is! Map) return null;
    if (raw['is_local'] == true) return null;
    if (raw['id'] == null ||
        (raw['id'] as String?).toString().isEmpty) {
      return null;
    }
    return SpotifyTrack.fromJson(raw.cast<String, dynamic>());
  }

  /// Smallest image at least [minWidth] wide, else the largest
  /// available. Tolerates null dimensions and missing urls.
  static String pickArtwork(Map? album, {int minWidth = 300}) {
    final images = (album?['images'] as List? ?? [])
        .whereType<Map>()
        .map(
          (e) => (
            url: e['url'] as String? ?? '',
            width: (e['width'] as num?)?.toInt() ?? 0,
          ),
        )
        .where((e) => e.url.isNotEmpty)
        .toList();
    if (images.isEmpty) return '';
    images.sort((a, b) => a.width.compareTo(b.width));
    return images
        .firstWhere(
          (e) => e.width >= minWidth,
          orElse: () => images.last,
        )
        .url;
  }
}
