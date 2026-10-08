import 'dart:convert';
import 'dart:js_interop';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:jent_web/data/datasources/spotify_auth.dart';
import 'package:jent_web/router/app_path.dart';
import 'package:url_launcher/url_launcher.dart';

/// DEV-ONLY one-time setup: connects the owner's Spotify account and
/// reveals the refresh token to bake into --dart-define.
/// Remove this route before production.
class SpotifySetupPage extends StatefulWidget {
  const SpotifySetupPage({super.key});

  @override
  State<SpotifySetupPage> createState() => _SpotifySetupPageState();
}

class _SpotifySetupPageState extends State<SpotifySetupPage> {
  String? _refreshToken;
  String? _error;
  bool _busy = false;

  String get _clientId => const String.fromEnvironment('SPOTIFY_CLIENT_ID');
  String get _redirectUri => '${Uri.base.origin}/callback';

  String _randomString(int bytes) {
    final random = Random.secure();
    return base64UrlEncode(
      List<int>.generate(bytes, (_) => random.nextInt(256)),
    ).replaceAll('=', '');
  }

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    // Full-page redirect wipes memory: persist verifier across it.
    final verifier = _randomString(64);
    final state = _randomString(16);
    sessionStorage.setItem('spotify_verifier', verifier);
    sessionStorage.setItem('spotify_state', state);
    final challenge = base64UrlEncode(
      sha256.convert(utf8.encode(verifier)).bytes,
    ).replaceAll('=', '');
    final url = spotifyAuthorizeUrl(
      clientId: _clientId,
      redirectUri: _redirectUri,
      codeChallenge: challenge,
      state: state,
    );
    if (!await launchUrl(Uri.parse(url), webOnlyWindowName: '_self')) {
      setState(() {
        _busy = false;
        _error = 'Could not open Spotify';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Spotify setup (dev only)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '1. Add this redirect URI in your Spotify dashboard.\n'
                '2. Click Connect and approve.\n'
                '3. Copy the refresh token into --dart-define.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              SelectableText(
                _redirectUri,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              if (_clientId.isEmpty)
                const Text(
                  'SPOTIFY_CLIENT_ID is missing. '
                  'Run with --dart-define=SPOTIFY_CLIENT_ID=...',
                  style: TextStyle(color: Colors.redAccent),
                )
              else
                ElevatedButton(
                  onPressed: _busy ? null : _connect,
                  child: Text(_busy ? 'Working…' : 'Connect Spotify'),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              if (_refreshToken != null) ...[
                const SizedBox(height: 20),
                const Text(
                  'Your refresh token (copy now, never commit):',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _refreshToken!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => Clipboard.setData(
                    ClipboardData(text: _refreshToken!),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

@JS('window.sessionStorage')
// ignore: library_private_types_in_public_api
external _SessionStorageJs get sessionStorage;

@JS()
@anonymous
extension type _SessionStorageJs._(JSObject _) implements JSObject {
  external void setItem(String key, String value);
  external String? getItem(String key);
}

/// OAuth redirect landing: exchanges ?code= for tokens using the
/// verifier saved in sessionStorage, then shows the refresh token.
class SpotifyCallbackPage extends StatefulWidget {
  final String? code;
  final String? state;
  final String? error;

  const SpotifyCallbackPage({super.key, this.code, this.state, this.error});

  @override
  State<SpotifyCallbackPage> createState() => _SpotifyCallbackPageState();
}

class _SpotifyCallbackPageState extends State<SpotifyCallbackPage> {
  String? _refreshToken;
  String? _error;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _exchange();
  }

  Future<void> _exchange() async {
    if (widget.error != null) {
      setState(() {
        _error = 'Spotify error: ${widget.error}';
        _done = true;
      });
      return;
    }
    if (widget.code == null) {
      setState(() {
        _error = 'Missing authorization code.';
        _done = true;
      });
      return;
    }
    final verifier = sessionStorage.getItem('spotify_verifier');
    final savedState = sessionStorage.getItem('spotify_state');
    if (verifier == null || savedState != widget.state) {
      setState(() {
        _error = 'Session expired or state mismatch. Start over.';
        _done = true;
      });
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': widget.code!,
          'redirect_uri': '${Uri.base.origin}/callback',
          'client_id': const String.fromEnvironment('SPOTIFY_CLIENT_ID'),
          'code_verifier': verifier,
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Token exchange failed (${response.statusCode})');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      setState(() {
        _refreshToken = json['refresh_token'] as String?;
        _done = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _done = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Spotify setup (dev only)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (!_done)
                const Text(
                  'Exchanging code…',
                  style: TextStyle(color: Colors.white70),
                ),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              if (_refreshToken != null) ...[
                const Text(
                  'Your refresh token (copy now, never commit):',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _refreshToken!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => Clipboard.setData(
                    ClipboardData(text: _refreshToken!),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy'),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(AppPath.spotifySetup),
                child: const Text('Back to setup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
