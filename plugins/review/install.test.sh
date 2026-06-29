#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

bash "$HERE/install.sh" "$T"

for p in scripts/review/gate.ts scripts/review/config.ts scripts/review/docPairing.ts \
         scripts/review/package.json .husky/pre-push .github/workflows/review-gate.yml \
         .claude/review.config.schema.json .claude/review.config.json; do
  [ -f "$T/$p" ] || { echo "MISSING: $p"; exit 1; }
done

[ -x "$T/.husky/pre-push" ] || { echo "pre-push not executable"; exit 1; }
[ -d "$T/scripts/review/node_modules" ] && { echo "node_modules leaked"; exit 1; }

# Idempotency: a custom config must survive a re-run.
echo '{"custom":true}' > "$T/.claude/review.config.json"
bash "$HERE/install.sh" "$T" >/dev/null
grep -q '"custom":true' "$T/.claude/review.config.json" || { echo "config clobbered"; exit 1; }

echo "INSTALL TEST PASS"
