# Conventions & Gotchas

Learned the hard way — read before writing code or tests.

## Code
- One bloc per feature (`features/<name>/bloc/`). Never reintroduce a
  god-bloc; features must not import each other (dock is the only
  exception).
- UI rules: flat design, NO glow effects (`BoxShadow` with color,
  `RadialGradient` accents, backdrop blur on cards). Neutral drop
  shadows for window elevation are fine.
- Shared window chrome lives in `core/widgets/window/` — reuse
  `WindowTitleBar` + `WindowResizeHandle`, don't rebuild them.
- Overlays keep window geometry in a local `ValueNotifier<Rect?>`
  (null = preset); bloc holds only open/minimized/expanded/locked.
- Reordered `Stack` children need stable keys, or Flutter remounts
  them and destroys their `State` on every reorder (see stacking
  order in `features.md`).
- `BlocSelector` with a `List` result rebuilds on EVERY emit (identity
  equality) — use records or `context.select` instead.
- Text changes need BOTH `app_en.arb` AND `app_id.arb` + regen.

## Tests (flutter_test + bloc_test + mocktail)
- After `bloc.add(...)`, pump TWICE (`pump()` + `pump(duration)`)
  before asserting: one pump rebuilds + starts implicit animations,
  the second settles them. Single-pump asserts read stale sizes.
- Quiesce timers before teardown or the test fails with "Timer is
  still pending": `CloseMusicPlayer` (sim timer), 1s pump (notes
  800ms debounce), music `ToggleMusicPlayback` off.
- Hidden PIN fields (`Opacity 0`) still accept `enterText`.
- `tester.drag` on a resize handle: deltas accumulate, then pump
  twice to measure.
- Hit-test warnings on taps are benign when an ancestor handles the
  tap (e.g. text inside a `GestureDetector`).
- Widget harnesses must include ALL overlays the flow touches
  (e.g. `NotesOverlay` + `NotesPinOverlay`), with l10n delegates +
  `Locale('en')`.
- New `@injectable` bloc needs its deps mocked in widget tests
  (`statusStream`/`playerState` → empty streams or they hang).
- Keep temp live-network tests OUT of the suite (flutter_test
  blocks real HTTP; suite must stay hermetic/offline).
