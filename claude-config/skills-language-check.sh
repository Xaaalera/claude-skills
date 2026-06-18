#!/usr/bin/env bash
# PostToolUse(Write|Edit): warn when non-English (Cyrillic) text lands in a
# skill file under ~/.claude/skills/ or a project .claude/skills/.
# Replaces the meta_skills-language passive skill (no per-response Skill call).
f=$(jq -r '.tool_input.file_path // .tool_response.filePath // empty')
[ -n "$f" ] || exit 0
printf '%s' "$f" | grep -q '/\.claude/skills/' || exit 0
[ -f "$f" ] || exit 0
perl -CSD -ne '$x=1 if /\p{Cyrillic}/; END{exit($x?1:0)}' "$f" && exit 0
printf '{"systemMessage":"⚠️ skills-language: non-English (Cyrillic) text in %s — skill/docs files must be English only."}\n' "$f"
