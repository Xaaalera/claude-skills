#!/usr/bin/env bash
# CICERO SessionStart hook — shows a one-time banner to the user and injects the
# always-on house voice (cicero.md) into the model's context for the session.
# Also resolves the house-voice LANGUAGE: on first run (no config) it asks the model
# to have the user choose one; once chosen it reminds the user they can grow the
# personal jargon dictionary.
#
# Heredocs are read via `read -r -d ''` rather than $(cat <<EOF): macOS ships bash 3.2,
# which mis-parses a heredoc nested inside $(...) when the body contains quotes/apostrophes.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTENT="$ROOT/cicero.md"

CFG="$HOME/.claude/cicero/config.json"
LANG_CHOSEN=""
if [ -f "$CFG" ]; then
  LANG_CHOSEN="$(jq -r '.language // empty' "$CFG" 2>/dev/null || true)"
fi

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

RULES=$(cat "$CONTENT")

if [ -n "$LANG_CHOSEN" ]; then
  SYSMSG="$BANNER
voice language: $LANG_CHOSEN · say \"add <word>\" to grow the dictionary"
  CONTEXT="$RULES$DICT_HOWTO"
else
  SYSMSG="$BANNER
no voice language set yet — I'll ask you to pick one"
  CONTEXT="$RULES$DICT_HOWTO$FIRSTRUN"
fi

# systemMessage -> shown to the user once at session start.
# additionalContext -> the house-voice rules (+ dictionary mechanic), injected into model context.
jq -n --arg banner "$SYSMSG" --arg content "$CONTEXT" \
  '{systemMessage: $banner, hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $content}}'
