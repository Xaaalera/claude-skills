#!/usr/bin/env bash
# PostToolUse (Write|Edit) reminder. When a PROJECT skill's SKILL.md is added or
# edited, warn if that project's CLAUDE.md doesn't reference the skill yet, so the
# curated Skills index stays in sync. Curation stays MANUAL — this only nudges;
# it never edits CLAUDE.md.
#
# Silent when: the file isn't a skill's SKILL.md; the skill is already referenced;
# or there's no governing CLAUDE.md at the project root (e.g. personal
# ~/.claude/skills, whose root has no CLAUDE.md). Zero model context on the happy path.

input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_response.filePath // empty')

case "$file" in
  */.claude/skills/*/SKILL.md) ;;
  *) exit 0 ;;
esac

skill=$(basename "$(dirname "$file")")
root=${file%/.claude/skills/*}
claudemd="$root/CLAUDE.md"

[ -f "$claudemd" ] || exit 0
grep -q "$skill" "$claudemd" && exit 0

msg="Skill '$skill' is not referenced in $claudemd — add a one-line entry to the Skills section (short description + the correct callable name: bare for project-local skills, plugin:skill for marketplace skills)."
jq -n --arg m "$msg" \
  '{systemMessage: ("📋 " + $m), hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $m}}'
