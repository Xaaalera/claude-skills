#!/usr/bin/env bash
# CI-only scout-gate. Maps the PR diff (origin/main..HEAD ONLY — no stdin, no
# pre-push refs path) to changed skill dirs, runs scout_validate.py on each,
# blocks on fail, records self-asserted (non-blocking), and blocks on
# cross-file staleness (SKILL.md or a bundled .sh/.py changed without a
# matching metadata.yaml change). Bash 3.2 compatible.
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
VALIDATE="$ROOT/scripts/scout_validate.py"
EMPTY_TREE="$(git hash-object -t tree /dev/null)"

# --- 1. collect changed files: origin/main..HEAD fallback ONLY --------------
base="$(git merge-base origin/main HEAD 2>/dev/null || echo "$EMPTY_TREE")"
changed="$(git diff --name-only "$base" HEAD 2>/dev/null)"

# --- 2. map changed files -> unique skill dirs, RETAINING the raw file list -
skilldir_of() {
  local d; d="$(dirname "$1")"
  while [ "$d" != "." ] && [ "$d" != "/" ]; do
    [ -f "$d/SKILL.md" ] && { echo "$d"; return 0; }
    d="$(dirname "$d")"
  done
  return 1
}
skills=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  sd="$(skilldir_of "$f")" || continue
  [ -f "$sd/SKILL.md" ] || continue     # skill fully deleted: not a gate concern
  skills="$skills
$sd"
done <<EOF
$changed
EOF
skills="$(printf '%s\n' "$skills" | sed '/^$/d' | sort -u)"

if [ -z "$skills" ]; then
  echo "scout-gate: no skills touched — nothing to check."
  exit 0
fi

# --- 3. validate each touched skill + cross-file staleness -------------------
blocks=""; self_asserted=""; passes=""; nskills=0
sg_err="$(mktemp)"; trap 'rm -f "$sg_err"' EXIT
while IFS= read -r sd; do
  [ -z "$sd" ] && continue
  nskills=$((nskills + 1))

  if ! out="$(python3 "$VALIDATE" "$sd" 2>"$sg_err")"; then
    blocks="$blocks
     • $(cat "$sg_err")"
    continue
  fi

  skill_block=0
  case "$out" in
    self-asserted:*)
      self_asserted="$self_asserted
     • ${out#self-asserted: }"
      ;;
  esac

  # --- cross-file staleness: SKILL.md or a bundled .sh/.py under $sd changed
  #     but metadata.yaml under $sd did NOT change.
  skill_md_changed=0
  script_changed=""
  meta_changed=0
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    case "$f" in
      "$sd"/*) ;;
      *) continue ;;
    esac
    case "$f" in
      "$sd/SKILL.md") skill_md_changed=1 ;;
      "$sd/metadata.yaml") meta_changed=1 ;;
      *.sh|*.py) script_changed="$script_changed $f" ;;
    esac
  done <<EOF2
$changed
EOF2

  if [ "$meta_changed" -eq 0 ] && { [ "$skill_md_changed" -eq 1 ] || [ -n "$script_changed" ]; }; then
    blocks="$blocks
     • $sd :: cross-file staleness — SKILL.md or a bundled script changed without a matching metadata.yaml change"
    skill_block=1
  fi

  [ "$skill_block" -eq 0 ] && passes="$passes
  ✓ $sd :: ok"
done <<EOF
$skills
EOF

# --- 4. report ----------------------------------------------------------------
[ -n "$passes" ] && printf '%s\n' "$passes"
if [ -n "$self_asserted" ]; then
  echo ""
  echo "  ⚠  self-asserted (author-declared, unverified — not blocked):"
  printf '%s\n' "$self_asserted"
fi
if [ -n "$blocks" ]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  ✖  PR BLOCKED by scout-gate"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  printf '%s\n' "$blocks"
  echo ""
  exit 1
fi
echo "scout-gate: $nskills skill(s) checked, no blockers."
exit 0
