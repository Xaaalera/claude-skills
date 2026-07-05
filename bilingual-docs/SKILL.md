---
description: >
  Use whenever writing or updating a spec, plan, design doc, brainstorming summary, feature list,
  or report in ANY repository — decide the language and where the file goes. The canonical document
  is ENGLISH and git-tracked (plans/, specs/, next to a BACKLOG, wherever the repo keeps docs); the
  user's Russian copy goes ONLY in a gitignored users-files/ (or hidden .users-files/) zone. Activate
  before creating any such file, or when the user asks (in any language) to place a plan/spec/report,
  wants a Russian version, or asks where a document should live.
---

# Bilingual docs — English canonical (git), Russian in users-files (gitignored)

The user works in Russian but ships English. Two homes, never mixed:

| Home | Language | Git | Holds |
|---|---|---|---|
| the repo's normal doc location (`docs/…/plans`, `specs`, next to `BACKLOG.md`, `README`, etc.) | **English** | tracked | the canonical document — what the team and future sessions read |
| `users-files/` or hidden `.users-files/` | **Russian** (user's language) | **gitignored** | the user's personal copy to read/edit |

## Rules

- **Canonical doc = English, git-tracked, in the repo's real doc location.** Never Cyrillic there.
- **`users-files/` is Russian-only and gitignored.** A Russian copy lives there when the user wants
  one. Never put an English doc in `users-files/`; never put a Russian doc outside it.
- **The working document itself does NOT live in `users-files/`** — that folder holds *translations
  for the user*, not the plans/specs/reports themselves. (Past mistake: a plan dropped into
  `users-files/` instead of `plans/`.)
- If a repo has no `users-files/` yet and the user wants a Russian copy, create `.users-files/` and add
  it to that repo's `.gitignore`.
- A language-guard hook blocks Cyrillic in tracked files; the `users-files/` zone is the one exception.

## Default flow

1. Write the doc in English at the repo's real, git-tracked doc location.
2. If the user wants to read/edit it in Russian, ALSO write a Russian copy in `users-files/`
   (same basename, mirrored content).
3. Keep them in sync; on conflict the English one wins (it is the git artifact).

## Checklist

- [ ] Canonical doc is English and in a git-tracked location (not `users-files/`)
- [ ] Any Russian copy is in `users-files/` / `.users-files/` only (gitignored)
- [ ] No Cyrillic in the tracked English doc
