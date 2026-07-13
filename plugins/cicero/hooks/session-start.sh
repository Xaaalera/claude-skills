#!/usr/bin/env bash
# CICERO SessionStart hook — shows a one-time banner and injects the DYNAMIC voice context:
# the personal-dictionary mechanic and, on first run, the language-pick prompt. The static
# voice RULES (Rule 0-14) do NOT live here anymore — they ship as the force-for-plugin output
# style output-styles/cicero.md, applied at the system-prompt level whenever the plugin is on.
# This hook only carries what needs runtime logic (config check, language, dictionary).
#
# Heredocs are read via `read -r -d ''` rather than $(cat <<EOF): macOS ships bash 3.2,
# which mis-parses a heredoc nested inside $(...) when the body contains quotes/apostrophes.
set -euo pipefail

CFG="$HOME/.claude/cicero/config.json"
LANG_CHOSEN=""
if [ -f "$CFG" ]; then
  LANG_CHOSEN="$(jq -r '.language // empty' "$CFG" 2>/dev/null || true)"
fi

# Loaded plugin version — printed in the banner so it's obvious at a glance whether
# this session runs a fresh build or a stale cached one. Read from the running copy's
# own plugin.json (CLAUDE_PLUGIN_ROOT is the installed/cached dir the hook executes from).
VER="$(jq -r '.version // empty' "${CLAUDE_PLUGIN_ROOT:-}/.claude-plugin/plugin.json" 2>/dev/null || true)"
[ -z "$VER" ] && VER="?"

read -r -d '' BANNER <<'EOF' || true
═══════════════════════════════════
C I C E R O — the house voice
"Speak so the point lands first."
bottom line·concise·honest·in scope
═══════════════════════════════════
EOF

# The dictionary mechanic — injected every session so the model knows how to act on
# "add <word>" and where the user's growing dictionary lives.
read -r -d '' DICT_HOWTO <<'EOF' || true

## Personal jargon dictionary

The Stop-hook language guard (plugins/cicero/hooks/plain-language-guard.py) reads per-language
dictionaries. The shipped half is English-only (which words to flag + how); the user's own
translations grow in ~/.claude/cicero/dicts/<lang>.json — OUTSIDE this repo, so its non-English
content is allowed there and nowhere else.

When the user says "add <word>" (or when the guard blocks on a reusable foreign word), ASK how to
handle it, then record it in ~/.claude/cicero/dicts/<lang>.json under "terms":
  - translate : {"action":"translate","value":"<their word>"}  — always use the translation.
  - gloss     : {"action":"gloss","value":"<gloss>"}           — keep English, explain in (parens) on first use.
  - allow     : {"action":"allow"}                              — foreign word is fine as-is.
Why the user cares: the dictionary teaches the house voice their exact wording and silences the
guard on terms they have approved — it gets more accurate and less naggy over time.
EOF

read -r -d '' FIRSTRUN <<'EOF' || true

## First run — pick a voice language

No house-voice language is configured yet. Early in this session, ask the user which language the
house voice should converse in. Then persist it, in two steps:
  1. Write {"language":"<code>"} to ~/.claude/cicero/config.json (create the dir).
  2. SEED the dictionary — do NOT leave it empty. Read the shipped dict
     plugins/cicero/hooks/dicts/<code>.json for its term list, then write
     ~/.claude/cicero/dicts/<code>.json as {"script":"<writing-system>","terms":{...}} giving each
     shipped term a sensible default in the chosen language: translate → the native word, gloss → a
     short native gloss, allow → leave as {"action":"allow"}. This is a starter set the user
     refines later via "add <word>".
If no shipped dict exists for that language, create it as {"script":"<writing-system>","terms":{}}
and grow it from scratch. Do this once; after that the choice sticks.
EOF

if [ -n "$LANG_CHOSEN" ]; then
  SYSMSG="$BANNER
cicero v$VER · voice language: $LANG_CHOSEN · say \"add <word>\" to grow the dictionary"
  CONTEXT="$DICT_HOWTO"
else
  SYSMSG="$BANNER
cicero v$VER · no voice language set yet — I'll ask you to pick one"
  CONTEXT="$DICT_HOWTO$FIRSTRUN"
fi

# One-time notice: the voice now ships as a force-for-plugin output style. We CANNOT detect
# from a hook whether it actually applied (no documented "active output style" field in the
# SessionStart input), so this is informational, shown once, then silenced via a marker file.
NOTICE_MARK="$HOME/.claude/cicero/.voice-style-notice-seen"
if [ ! -f "$NOTICE_MARK" ]; then
  SYSMSG="$SYSMSG
──────────────────────────────────
note (shown once): CICERO is a force-for-plugin OUTPUT STYLE — while this plugin is enabled it is
injected into the system prompt and OVERRIDES your own outputStyle setting. You do not select it.
  heads-up: /config keeps showing YOUR saved style (often \"default\") — the plugin overrides that
  slot without changing what it displays, so \"default\" there does NOT mean the voice is off.
  confirm it is live → send me this exact line:
      Quote Rule 0 and Rule 14 of your active output style, verbatim.
    active   = I reply with the real rules (Rule 0 \"Readable first…\", Rule 14 \"end with a joke\").
    NOT active = I don't know them, or answer in generic terms.
  truly missing (older Claude Code, or a stale plugin)? run in order:
    /reload-plugins         — reload plugins in this session
    /plugin update cicero   — pull the latest plugin version
    update Claude Code       — if still missing, upgrade the CLI to the latest"
  mkdir -p "$HOME/.claude/cicero" && : > "$NOTICE_MARK" || true
fi

# systemMessage -> shown to the user once at session start.
# additionalContext -> the DYNAMIC voice context (dictionary mechanic + first-run language pick).
# The static rules are the output style, not this injection.
jq -n --arg banner "$SYSMSG" --arg content "$CONTEXT" \
  '{systemMessage: $banner, hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $content}}'
