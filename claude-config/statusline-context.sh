#!/usr/bin/env bash
# Native statusLine: context-window fill bar.
# Receives session JSON on stdin (see `.context_window.*`). Zero model context.
# Replaces the old meta_context-monitor passive skill's status line.
# The joke is intentionally NOT here — it lives as a one-line CLAUDE.md
# directive so the model generates a fresh, language-aware joke each turn.

input=$(cat)

# Active skills invoked this session. The PostToolUse "Skill" hook appends each
# invoked skill name to /tmp/claude-skills-<session_id>.log; SessionStart truncates it.
# Deduped + length-capped so the bar stays readable. Zero model context.
skills_line=""
sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
if [ -n "$sid" ] && [ -f "/tmp/claude-skills-$sid.log" ]; then
  skills=$(awk 'NF && !seen[$0]++' "/tmp/claude-skills-$sid.log")
  if [ -n "$skills" ]; then
    count=$(printf '%s\n' "$skills" | wc -l | tr -d ' ')
    list=$(printf '%s\n' "$skills" | paste -sd ',' -)
    if [ "${#list}" -gt 60 ]; then list="${list:0:57}…"; fi
    skills_line=" · 🛠 ${count}: ${list}"
  fi
fi

pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
used=$(printf '%s' "$input" | jq -r '.context_window.total_input_tokens // empty')
total=$(printf '%s' "$input" | jq -r '.context_window.context_window_size // 200000')

if [ -z "$pct" ] || [ "$pct" = "null" ]; then
  printf '🧠 context: warming up…%s' "$skills_line"
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

printf '🧠 %s%% · %sk/%sk · %sk left%s' "$pct_rounded" "$used_k" "$total_k" "$left_k" "$marker"
