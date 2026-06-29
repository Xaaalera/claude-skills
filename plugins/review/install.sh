#!/usr/bin/env bash
set -euo pipefail

# Self-locating installer for the review framework. Run from a target repo, or pass the repo path.
#   bash install.sh [TARGET_REPO]    (TARGET_REPO defaults to $PWD)
# Vendors the harness + git hook + CI workflow + config schema into the target; seeds a config if none.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$PWD}"

mkdir -p "$TARGET/scripts/review" "$TARGET/.husky" "$TARGET/.github/workflows" "$TARGET/.claude"

# Harness (vendored) — *.ts + package.json, never node_modules.
for f in "$SCRIPT_DIR"/scripts/review/*.ts; do
  cp "$f" "$TARGET/scripts/review/"
done
cp "$SCRIPT_DIR/scripts/review/package.json" "$TARGET/scripts/review/package.json"

# Git hook + CI workflow + config schema.
cp "$SCRIPT_DIR/templates/husky-pre-push" "$TARGET/.husky/pre-push"
chmod +x "$TARGET/.husky/pre-push"
cp "$SCRIPT_DIR/templates/review-gate.yml" "$TARGET/.github/workflows/review-gate.yml"
cp "$SCRIPT_DIR/review.config.schema.json" "$TARGET/.claude/review.config.schema.json"

# Seed config only if absent (idempotent — never clobber the project's own config).
if [ ! -f "$TARGET/.claude/review.config.json" ]; then
  cp "$SCRIPT_DIR/templates/starter.review.config.json" "$TARGET/.claude/review.config.json"
  echo "seeded .claude/review.config.json"
else
  echo "kept existing .claude/review.config.json"
fi

echo "review framework installed into $TARGET"
echo "next: (1) enable husky    -> npm i -D husky && npx husky init"
echo "      (2) harness deps     -> (cd scripts/review && npm i)"
echo "      (3) tailor config    -> .claude/review.config.json (zones / skills / pairedDocs)"
