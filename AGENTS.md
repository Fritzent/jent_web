# AGENTS.md — instructions for AI coding agents

## Mandatory first step (no exceptions)

Before doing anything else — before exploring code, before answering,
before writing a single line — read these files IN ORDER:

1. `docs/README.md` — the doc index (tells you what to read next)
2. `docs/architecture.md` — where everything lives and why
3. `docs/conventions-and-gotchas.md` — rules that prevent repeat mistakes

Then read the task-specific doc:
- Feature work (mail/music/photos/notes/dock/wallpaper) → `docs/features.md`
- Email, Supabase, env vars, deploy → `docs/backend-and-secrets.md`
- Build/test/analyze/codegen/deploy commands → `docs/workflows.md`

Do NOT rely on memory of this repo. Its structure and rules change;
the docs are the source of truth. If the docs and the code disagree,
follow the code, then update the doc to match.

## Standing rules

- One bloc per feature. Never merge feature logic into a shared bloc.
- Features never import each other (`desktop`/dock is the only
  cross-feature reader).
- No secrets in code, ever. All credentials come from `--dart-define`.
- Verify with execution: run the relevant tests and `flutter analyze`
  after every change. Full suite (`flutter test`) before finishing.
- Keep `docs/` in sync: any behavior change must update the matching
  doc in the same pass.
