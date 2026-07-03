# AGENTS.md — contributor contract for the xaaalera personal marketplace

Rules for any AI agent (or human) changing this repo. Read before editing.

## What this repo is
`~/.claude/skills` — my personal Claude Code plugin marketplace. Each `plugins/<domain>/` holds skills
(`skills/<name>/SKILL.md`), and optionally hooks/commands/agents. It mirrors the team `accountingseed`
marketplace as a personal safety net (survives leaving the org) plus personal-only plugins (`diogenes`).

## Hard rules
- **One problem per change.** A focused edit, not a grab-bag.
- **Prove the problem first.** Don't restructure tested skill content without evidence it improves behavior.
- **English only** in all artifacts (skills, docs, commit messages). Conversation language is the author's choice.
- **No `Co-Authored-By: Claude` / Anthropic attribution** trailers in commits or PR bodies.
- **`README.md` is hand-maintained** — update its "Skills" section by hand when you add/rename a skill.
- **Every `plugin.json` carries `name`, `description`, `version` (semver), `keywords`, `author`.**
- **Editing anything under `~/.claude/skills/` auto-commits + pushes** via the PostToolUse hook — no manual
  sync step. Keep each edit self-consistent because it ships immediately.

## SKILL.md authoring
- `description:` = **when to use only** (triggering conditions, ideally opening "Use when…"). Do NOT summarize
  the workflow in the description — agents that read the description skip the body (tested anti-pattern).
- **No `name:` frontmatter field** — the folder name is authoritative and the callable id is `<domain>:<folder>`
  (colon form is invalid in the field anyway). Frontmatter is just `description:`.
- Keep the body short; push deep tables/examples into a `references/` subfolder (progressive disclosure).

## Sync with accountingseed
This marketplace mirrors `accountingseed` (team SSOT). When pulling changes across, copy everything EXCEPT
marketplace-identity fields — `author` (`Xaaalera` here), the "Personal …" plugin descriptions, and the
`meta:new-skill` placement/push wording, which are intentionally repo-specific.
