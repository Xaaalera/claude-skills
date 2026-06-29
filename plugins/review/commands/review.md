---
description: Run the configured pre-push reviewer agents over the cumulative diff, score it, and on all-pass write the review attestation.
---

Run the mandatory pre-push review.

1. Resolve the base and the change set. Base: `npx tsx -e "import('./scripts/review/diffHash.ts').then((m) => process.stdout.write(m.resolveBase()))"`. Then run `git diff <base>..HEAD` and `git diff --name-only <base>..HEAD`. If the diff is empty, tell the user there is nothing to review and stop.

2. Load the active reviewer set: `npx tsx -e "import('./scripts/review/config.ts').then((m) => process.stdout.write(JSON.stringify(m.loadConfig().agents.filter((a) => a.enabled))))"`. Dispatch ALL enabled reviewers IN PARALLEL (a single message with one Agent tool call each). Give each agent: the cumulative diff, the changed-file list, and its config block (`zones`, `skills`, `rules`, `pairedDocs`, `threshold`, `extensionSkill`). Each returns its JSON verdict object `{ agent, score, verdict, hasBlocker, findings[], advisories[] }`.

3. Apply ALL-PASS: the change set passes only if EVERY dispatched agent has `verdict: "PASS"` (its `score >= threshold` AND `hasBlocker: false`), using each agent's configured threshold.

4. On any FAIL: print a report grouped by agent — `agent: score/threshold verdict`, then each finding as `severity  file:line — problem -> fix`, advisories listed separately. Do NOT write an attestation. Do NOT edit code (reviewers report only). Stop here.

5. On all-pass: build the per-agent JSON `{ "<agent>": {"score":N,"verdict":"PASS"}, ... }` from the results and write the attestation:
   `npx tsx scripts/review/writeAttestation.ts '<perAgentJson>'`
   This writes `.review/attestation.json`. Then commit it:
   `git add .review/attestation.json && git commit -m "chore: review attestation"`
   Tell the user the gate is green and they can push.
