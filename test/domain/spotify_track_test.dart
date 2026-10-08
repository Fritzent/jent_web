import 'package:flutter_test/flutter_test.dart';
import 'package:jent_web/domain/entities/spotify_track.dart';

void main() {
  group('SpotifyTrack.fromPlaylistEntry', () {
    test('parses the items/item envelope (GET /v1/playlists/{id})', () {
      final track = SpotifyTrack.fromPlaylistEntry({
        'added_at': '2026-09-10T18:58:20Z',
        'is_local': false,
        'item': {
          'id': '1fXHTDYsJiFOjVWITaFp1j',
          'name': 'Ride Home',
          'artists': [
            {'name': 'Ben&Ben'},
          ],
          'album': {
            'images': [
              {
                'url': 'https://i.scdn.co/image/640',
                'height': 640,
                'width': 640,
              },
              {
                'url': 'https://i.scdn.co/image/300',
                'height': 300,
                'width': 300,
              },
              {
                'url': 'https://i.scdn.co/image/64',
                'height': 64,
                'width': 64,
              },
            ],
          },
          'duration_ms': 326885,
        },
      });

      expect(track, isNotNull);
      expect(track!.id, '1fXHTDYsJiFOjVWITaFp1j');
      expect(track.title, 'Ride Home');
      expect(track.artist, 'Ben&Ben');
      expect(track.duration, const Duration(milliseconds: 326885));
      // 300px preferred over the 64px thumbnail.
      expect(track.artworkUrl, 'https://i.scdn.co/image/300');
    });

    test('parses the legacy items/track envelope', () {
      final track = SpotifyTrack.fromPlaylistEntry({
        'track': {
          'id': 'xyz',
          'name': 'Legacy',
          'artists': [
            {'name': 'A'},
            {'name': 'B'},
          ],
          'album': {
            'images': [
              {'url': 'https://img/big.jpg', 'width': 640, 'height': 640},
            ],
          },
          'duration_ms': 120000,
        },
      });

      expect(track, isNotNull);
      expect(track!.id, 'xyz');
      expect(track.artist, 'A, B');
      expect(track.artworkUrl, 'https://img/big.jpg');
    });

    test('skips local files, null ids and non-maps', () {
      expect(
        SpotifyTrack.fromPlaylistEntry({
          'item': {'id': 'a', 'is_local': true},
        }),
        isNull,
      );
      expect(
        SpotifyTrack.fromPlaylistEntry({
          'item': {'name': 'No id'},
        }),
        isNull,
      );
      expect(SpotifyTrack.fromPlaylistEntry({'item': 'nope'}), isNull);
    });
  });

  group('SpotifyTrack.pickArtwork', () {
    test('tolerates null dimensions and missing urls', () {
      expect(
        SpotifyTrack.pickArtwork({
          'images': [
            {'url': null, 'width': null, 'height': null},
            {'url': 'https://img/only.jpg'},
          ],
        }),
        'https://img/only.jpg',
      );
      expect(SpotifyTrack.pickArtwork(null), isEmpty);
      expect(SpotifyTrack.pickArtwork({'images': []}), isEmpty);
    });
  });
}
