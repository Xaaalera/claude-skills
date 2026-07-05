#!/usr/bin/env bash
# PostToolUse(Write|Edit): enforce CICERO rule 12 — every written artifact is
# English. Cyrillic is allowed ONLY under a users-files/ directory (the one
# sanctioned zone for user-language spec duplicates). Everything else — skills,
# docs, code, evals, scratch, memory — must be English.
#
# Emits decision:block so the violation is fed straight back to the model for
# an immediate fix (a systemMessage warning alone was ignored once — the
# 2026-07-04 trigger-eval.json incident; this is the hardened version).
f=$(jq -r '.tool_input.file_path // .tool_response.filePath // empty')
[ -n "$f" ] || exit 0
[ -f "$f" ] || exit 0
case "$f" in
  *users-files/*) exit 0 ;;                 # sanctioned user-language zone (incl. hidden .users-files/)
esac
# text-ish files only — skip binaries
case "$f" in
  *.md|*.txt|*.json|*.yaml|*.yml|*.js|*.ts|*.tsx|*.jsx|*.py|*.sh|*.cls|*.xml|*.html|*.css|*.scss) ;;
  *) exit 0 ;;
esac
perl -CSD -ne '$x=1 if /\p{Cyrillic}/; END{exit($x?1:0)}' "$f" && exit 0
printf '{"decision":"block","reason":"language guard: Cyrillic text found in %s — CICERO rule 12: every artifact (code, docs, skills, evals, scratch) is English; user-language content belongs only under users-files/. Rewrite the Cyrillic parts in English NOW.","systemMessage":"⛔ language guard: Cyrillic in %s — must be English (users-files/ is the only exception)."}\n' "$f" "$f"
