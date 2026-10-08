import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:jent_web/data/datasources/spotify_auth.dart';
import 'package:jent_web/domain/entities/spotify_track.dart';

/// Spotify Web API calls using the owner's access token.
@injectable
class SpotifyApiDatasource {
  static const _apiBase = 'https://api.spotify.com/v1';

  final SpotifyAuth _auth;
  final http.Client _client;

  SpotifyApiDatasource(this._auth) : _client = http.Client();

  Future<Map<String, String>> _headers() async => {
    'Authorization': 'Bearer ${await _auth.accessToken()}',
    'Content-Type': 'application/json',
  };

  Future<List<SpotifyTrack>> searchTracks(String query) async {
    final uri = Uri.parse(
      '$_apiBase/search',
    ).replace(queryParameters: {'q': query, 'type': 'track', 'limit': '20'});
    final response = await _client.get(uri, headers: await _headers());
    _throwIfError(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (json['tracks'] as Map?)?['items'] as List? ?? const [];
    return items
        .map((e) => SpotifyTrack.fromJson(e as Map<String, dynamic>))
        .where((t) => t.id.isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>> currentUser() async {
    final response = await _client.get(
      Uri.parse('$_apiBase/me'),
      headers: await _headers(),
    );
    _throwIfError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<SpotifyTrack>> playlistTracks(String playlistId) async {
    // No `fields` filter: the item envelope key differs per endpoint
    // shape (`item` vs `track`) and a wrong selector yields `200 {}`.
    // fromPlaylistEntry tolerates both shapes.
    final uri = Uri.parse('$_apiBase/playlists/$playlistId');
    final response = await _client.get(uri, headers: await _headers());
    _throwIfError(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (json['tracks'] as Map?)?['items'] as List? ?? const [];
    return items
        .whereType<Map>()
        .map(SpotifyTrack.fromPlaylistEntry)
        .whereType<SpotifyTrack>()
        .toList();
  }

  Future<void> transferPlayback(String deviceId, {bool play = true}) async {
    final response = await _client.put(
      Uri.parse('$_apiBase/me/player'),
      headers: await _headers(),
      body: jsonEncode({
        'device_ids': [deviceId],
        'play': play,
      }),
    );
    // ignore: avoid_print
    print('[Spotify] transferPlayback -> ${response.statusCode}');
    if (response.statusCode != 204) {
      throw SpotifyApiException(
        'Transfer failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<void> playOnDevice(String deviceId, String trackId) async {
    final response = await _client.put(
      Uri.parse('$_apiBase/me/player/play?device_id=$deviceId'),
      headers: await _headers(),
      body: jsonEncode({
        'uris': ['spotify:track:$trackId'],
      }),
    );
    // ignore: avoid_print
    print('[Spotify] playOnDevice -> ${response.statusCode}');
    if (response.statusCode != 204 && response.statusCode != 202) {
      throw SpotifyApiException(
        'Play failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  void _throwIfError(http.Response response) {
    // ignore: avoid_print
    print('[Spotify] api ${response.statusCode}: ${response.body}');
    if (response.statusCode == 401) {
      _auth.invalidateToken();
      throw SpotifyAuthException(
        'Access token rejected (401): ${response.body}',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SpotifyApiException(
        'API error (${response.statusCode}): ${response.body}',
      );
    }
  }
}

class SpotifyApiException implements Exception {
  final String message;
  SpotifyApiException(this.message);

  @override
  String toString() => 'SpotifyApiException: $message';
}
