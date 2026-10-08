import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

/// Owner-account OAuth: exchanges the baked-in refresh token for
/// short-lived access tokens. No client secret needed (PKCE flow).
@injectable
class SpotifyAuth {
  static const _tokenUrl = 'https://accounts.spotify.com/api/token';

  final String _clientId;
  final String _refreshToken;

  String? _accessToken;
  DateTime? _expiresAt;

  SpotifyAuth(
    @Named('spotifyClientId') this._clientId,
    @Named('spotifyRefreshToken') this._refreshToken,
  );

  bool get isConfigured =>
      _clientId.isNotEmpty && _refreshToken.isNotEmpty;

  /// Drops the cached access token so the next call refreshes.
  /// Used before surfacing auth errors and on manual retry.
  void invalidateToken() {
    _accessToken = null;
    _expiresAt = null;
  }

  Future<String> accessToken() async {
    if (_accessToken != null &&
        _expiresAt != null &&
        DateTime.now().isBefore(_expiresAt!.subtract(_skew))) {
      return _accessToken!;
    }
    // ignore: avoid_print
    print(
      '[Spotify] refresh: clientId=${_fingerprint(_clientId)} '
      'tokenLen=${_refreshToken.length}',
    );
    final response = await http.post(
      Uri.parse(_tokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': _refreshToken,
        'client_id': _clientId,
      },
    );
    if (response.statusCode != 200) {
      // ignore: avoid_print
      print('[Spotify] refresh failed: ${response.body}');
      throw SpotifyAuthException(
        'Token refresh failed (${response.statusCode}): ${response.body}',
      );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    _accessToken = json['access_token'] as String;
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 3600;
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    return _accessToken!;
  }

  static const _skew = Duration(minutes: 2);

  /// First 4 + length only: enough to compare values across runs
  /// without ever printing a secret.
  static String _fingerprint(String value) =>
      value.isEmpty ? '<empty>' : '${value.substring(0, 4)}…(len=${value.length})';
}

class SpotifyAuthException implements Exception {
  final String message;
  SpotifyAuthException(this.message);

  @override
  String toString() => 'SpotifyAuthException: $message';
}

/// Builds the PKCE authorize URL for the one-time dev setup page.
String spotifyAuthorizeUrl({
  required String clientId,
  required String redirectUri,
  required String codeChallenge,
  required String state,
}) {
  const scopes = [
    'streaming',
    'user-read-email',
    'user-read-private',
    'user-read-playback-state',
    'user-modify-playback-state',
    'playlist-read-private',
  ];
  final params = {
    'client_id': clientId,
    'response_type': 'code',
    'redirect_uri': redirectUri,
    'code_challenge_method': 'S256',
    'code_challenge': codeChallenge,
    'scope': scopes.join(' '),
    'state': state,
  };
  return Uri.https(
    'accounts.spotify.com',
    '/authorize',
    params,
  ).toString();
}
