# Workflows

## Local dev (all features live)
```sh
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080 \
  "--dart-define=SPOTIFY_CLIENT_ID=..." \
  "--dart-define=SPOTIFY_REFRESH_TOKEN=..." \
  "--dart-define=SPOTIFY_PLAYLIST_ID=..." \
  "--dart-define=WEB3FORMS_KEY=..." \
  "--dart-define=SUPABASE_URL=..." \
  "--dart-define=SUPABASE_ANON_KEY=..."
```

## Tests & analysis
```sh
flutter test                    # full suite (~105 tests)
flutter test test/features/<name>/
flutter analyze
```

## Integration tests (real app on headless web)
```sh
# One-time setup: chromedriver matching the installed Chrome must
# serve on :4444 (macOS cannot run this app: dart:js_interop in the
# Spotify player impl is web-only).
chromedriver --port=4444
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_journey_test.dart -d web-server
```
Journey covers: ignite -> home, mail compose (expects the no-key
error state), photos PIN -> gallery -> viewer, notes wrong-PIN ->
guest album, music offline player. No secrets needed; external calls
fail gracefully by design. Never assert hardcoded UI strings here —
the runner inherits the machine locale (use keys/types/icons).

## Codegen (after adding `@injectable`/`@lazySingleton`/l10n keys)
```sh
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```
`flutter gen-l10n` reads `l10n.yaml`; template file is `app_id.arb`
— add keys to BOTH `app_en.arb` and `app_id.arb` first.

## Release deploy (Firebase Hosting, project `me-jent`)
```sh
flutter build web --release --base-href / --dart-define=... (same six)
firebase deploy --only hosting --project me-jent
```
Live at `https://me-jent.web.app`. CI (`.github/workflows/`) builds
WITHOUT secrets — re-enable the commented secret lines there for a
fully-featured deploy.

## Assets
`pubspec.yaml` lists `assets/` BUT subdirectories need explicit
entries (`assets/photos_general/`, `assets/photos_private/`).
New photo folders: create dir + pubspec entry + paths in
`core/constants/app_images.dart` (see folder READMEs).
