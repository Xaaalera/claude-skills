#!/usr/bin/env bash
# Native statusLine: line 1 = context-window fill bar; line 2 = progress beacon
# (only while a background queue is fresh). Multi-line is officially supported —
# each printed line is a separate status row (docs: code.claude.com statusline).
# Plain text only, no ANSI, to avoid the documented multi-line rendering glitches.
# Receives session JSON on stdin (see `.context_window.*`). Zero model context.

input=$(cat)

# Line 2 — progress beacon. Long-running background queues write
# ~/.claude/progress/current.json ({task, step, total, item, eta, updated_epoch}).
# Shown as its own row while fresh (<15 min); a stale/absent beacon => no 2nd line.
beacon_line=""
BF="$HOME/.claude/progress/current.json"
if [ -f "$BF" ]; then
  b_upd=$(jq -r '.updated_epoch // 0' "$BF" 2>/dev/null)
  now=$(date +%s)
  if [ -n "$b_upd" ] && [ $(( now - b_upd )) -lt 900 ]; then
    beacon_line=$(jq -r '"⚙ \(.task) \(.step)/\(.total) · \(.item) · ETA \(.eta)"' "$BF" 2>/dev/null)
  fi
fi

pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
used=$(printf '%s' "$input" | jq -r '.context_window.total_input_tokens // empty')
total=$(printf '%s' "$input" | jq -r '.context_window.context_window_size // 200000')

if [ -z "$pct" ] || [ "$pct" = "null" ]; then
  printf '🧠 context: warming up…\n'
  [ -n "$beacon_line" ] && printf '%s\n' "$beacon_line"
  exit 0
fi

pct_rounded=$(printf '%.0f' "$pct")
used_k=$(( (used + 500) / 1000 ))
total_k=$(( total / 1000 ))
left_k=$(( (total - used + 500) / 1000 ))

marker=""
if [ "$pct_rounded" -ge 95 ]; then
  marker=" 🔴 /compact NOW"
elif [ "$pct_rounded" -ge 85 ]; then
  marker=" ⚠️ /compact soon"
elif [ "$pct_rounded" -ge 70 ]; then
  marker=" 💬 consider /compact"
fi

printf '🧠 %s%% · %sk/%sk · %sk left%s\n' "$pct_rounded" "$used_k" "$total_k" "$left_k" "$marker"
[ -n "$beacon_line" ] && printf '%s\n' "$beacon_line"
