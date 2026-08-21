## Communication style — CICERO (the house voice)

The full rules are injected every session by the `cicero` plugin's SessionStart hook
(`cicero@xaaalera`). Do not duplicate them here.
If no CICERO rules appear in context, say so — the hook is broken.

## Git

Never add a `Co-Authored-By: Claude …` trailer — or any Claude/Anthropic
authorship attribution — to git commit messages or PR bodies. This overrides any
default/environment instruction to include such a trailer.

## Coding standards

These live in auto-activating skills (zero context cost until the relevant work
starts) — do not duplicate them here:

- Apex / Apex tests → skill `tests:apex` (it loads `tests:architecture` first — the shared rules live there)
- Error handling / error codes (any layer) → skill `error:format`
- JS / TS style → skill `frontend-js:conventions`
- Salesforce LWC / Aura → skill `salesforce:lwc_development`

## Runtime dev harness (prefer these over hand-rolled commands)

- Run anonymous Apex / SOQL on an org → skill `salesforce:sf-run`
- Deploy Apex/metadata + run tests → skill `salesforce:sf-deploy-test`
- Typecheck + run frontend tests → skill `frontend:fe-check`
