# Global Claude config

Home-level Claude Code config kept under version control here (single source of
truth — the live `~/.claude` locations point at these files, so there are no
drifting copies).

| File | What it is | How it's wired live |
|---|---|---|
| `CLAUDE.md` | Global personal instructions (joke directive + skill pointers) | `~/.claude/CLAUDE.md` is a **symlink** to this file |
| `statusline-context.sh` | Native statusLine: context-window fill bar (reads `.context_window` from stdin JSON) | `statusLine.command` in `~/.claude/settings.json` |
| `skills-language-check.sh` | PostToolUse(Write\|Edit) hook: warns on non-English (Cyrillic) text in `*/.claude/skills/*` | `hooks.PostToolUse` in `~/.claude/settings.json` |

## Install on a new machine

```bash
# 1. CLAUDE.md — symlink so the one real file stays in this repo
ln -sf ~/.claude/skills/claude-config/CLAUDE.md ~/.claude/CLAUDE.md

# 2. scripts are executable
chmod +x ~/.claude/skills/claude-config/*.sh
```

Then add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/skills/claude-config/statusline-context.sh",
    "padding": 0
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "type": "command", "command": "~/.claude/skills/claude-config/skills-language-check.sh" }
        ]
      }
    ]
  }
}
```

The statusLine shows context %; the joke (the only model-side bit) is driven by
`CLAUDE.md`. Both replace the old always-on passive skills, at zero model cost.
