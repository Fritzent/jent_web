# Features

Shared window behavior (all overlays): local frame state (`Rect?`
notifier, null = preset size centered), macOS-style invisible resize
zones (`core/widgets/window/window_resize_handles.dart`), shared
`WindowTitleBar` (traffic lights + drag area), min sizes, snap-back to
preset on close/expand-toggle. Drag limits: fully on-screen, 12px
margins (`_clampFrame` in each overlay).

## wallpaper (`WallpaperBloc`)
Rotates `AppImages.homeBackground` every 6s. `HomeBackground` reads
`images` + `currentIndex`; `HomeMenuBar` reads `imagePath`. Started via
`StartWallpaperRotation` in `HomePage` providers.

## mail (`MailBloc`, needs `SendEmailUseCase`)
Window flags: open/close/minimize/expand + `EmailStatus`
(idle/sending/sent/error). `MailOverlay` mounts/unmounts on
`isShowWindow` with scale animation. Submit → use case → SMTP on
native, Web3Forms POST on web (see `backend-and-secrets.md`).
Dock dot = open OR minimized; dock tap toggles close/open.

## music (`MusicBloc`, needs `SpotifyRepository`, `SearchTracks`,
## `PlaySpotifyTrack`)
Toggle opens player + connects Spotify; falls back to local
`MusicPlaylist` simulation (1s timer) when Spotify unavailable.
States: show/minimize/expand, play/pause, track index, position,
`spotifyStatus`, search results. Views: player overlay (card + mini
bar), chrome, artwork, controls, search, expanded playlist.
Quiesce timers in tests via `CloseMusicPlayer` (cancels the sim timer).

## photos (`PhotosBloc`, shared `vaultPin`, default `1234`)
PIN gate on EVERY open (correct PIN → private album; wrong PIN →
denied card). Denied card offers **View general photos** → guest mode
(`isPhotosGeneralMode`, stays locked): minimized guest restores
without PIN; close exits guest mode. `visiblePhotos` getter picks the
album. Viewer: endless `PageView` + grid; grid columns adapt to live
width. `SelectPhoto` blocked unless window open AND
(unlocked OR guest).

## notes (`NotesBloc`, needs `NotesRemoteDataSource`, shared `vaultPin`)
Same PIN-gate + guest pattern as photos, but the guest folder is
`General` and guests are read-only (editor `readOnly`, no
create/delete buttons, bloc rejects `Create/Delete/UpdateNoteBody`
while locked). Folders: all/notes/work/general (+ general visible in
owner sidebar for publishing). Unlock pulls Supabase (remote wins if
non-empty); create/delete sync immediately, typing syncs debounced
800ms (`_notesSaveTimer`, cancelled in `close()`). Seeds (offline
fallback): `general-welcome`, `welcome`, `ideas`.

## dock (`HomeDock`, no own bloc)
Reads `MailBloc`, `NotesBloc`, `MusicBloc`, `PhotosBloc` via
`context.select` for running dots (`show || minimized`). Taps dispatch
each feature's toggle event. Dot widget = 8x8 grey circle (tests find
it by `BoxDecoration(shape: circle)`).

## stacking order (`WindowZOrder`, owned by `HomePage`)
Overlays paint in open order: the latest opened window sorts last in
the desktop `Stack`, so it lands in front. Clicking or dragging
anywhere inside a behind window moves it to the front via a `Listener`
focus wrapper (`onPointerDown` → `moveToFront`); already-front and
hidden windows are no-ops, keeping background rebuilds quiet.
Visibility listeners (one per window bloc, `listenWhen` on
show/minimized flags only) feed the same order: hidden ids are
dropped, so closing always removes and reopening appends to the front.
PIN gates and the dock always paint above windows. Reordered `Stack`
children MUST keep stable `ValueKey`s (`window-mail` etc.) or every
reorder remounts the overlays and wipes local state (mount flags, drag
frames, editors).
