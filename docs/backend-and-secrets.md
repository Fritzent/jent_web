# Backend & Secrets

No secret is ever committed. Web build/run takes everything via
`--dart-define`. CI sources them from GitHub Actions secrets.

## `--dart-define` variables

| Var | Used by | Notes |
|---|---|---|
| `VAULT_PIN` | photos + notes gates | default `1234` (`core/constants/vault_pin.dart`) |
| `SUPABASE_URL` | `core/supabase/supabase_config.dart` | e.g. `https://xyz.supabase.co` |
| `SUPABASE_ANON_KEY` | same | publishable/anon key (public by design) |
| `WEB3FORMS_KEY` | contact form on web | free key from web3forms.com |
| `SPOTIFY_CLIENT_ID` | Spotify auth | owner account |
| `SPOTIFY_REFRESH_TOKEN` | Spotify auth | owner account, rotate if leaked |
| `SPOTIFY_PLAYLIST_ID` | Spotify auth | owner playlist |
| `EMAIL_USERNAME/PASSWORD/RECIPIENT` | SMTP path (native only) | App Password, not login password |

Missing defines = safe fallback: Supabase skipped (local seeds),
Web3Forms throws a clear `StateError` surfaced as the form's error
state, Spotify falls back to the local playlist.

## Email sending (contact form)
- **Web**: `EmailDatasource` POSTs JSON to Web3Forms. Visitor address
  goes in the `email` field → shows as reply-to in your inbox. Gmail
  may spam-filter first messages: mark "not spam" + filter
  `never send to spam`.
- **Native**: Gmail SMTP via `mailer` (`gmail(username, password)`),
  sender = your account, visitor in `Reply-To` + body. Browsers block
  SMTP sockets, so this path can never run on web.
- Deploy needs `WEB3FORMS_KEY` in the build (see `workflows.md`).

## Supabase (`notes` table)
```sql
create table notes (
  id text primary key,
  folder text not null default 'notes',
  body text not null default '',
  updated_at timestamptz not null default now()
);
alter table notes enable row level security;
create policy "anon all" on notes
  for all to anon using (true) with check (true);
```
Code: `NotesRemoteDataSource` (offline-safe: returns `null`/`false`
when unconfigured/offline). PIN gate is UI-level only — anon-key
holders could technically write; tighten RLS / add Auth before
sensitive use. Folder `general` = guest-visible; other folders private.
