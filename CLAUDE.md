## Response style

End every response with a short, fresh IT/programming joke (one line) in the
language the user is currently speaking. Never repeat a joke.

## Git

Never add a `Co-Authored-By: Claude …` trailer — or any Claude/Anthropic
authorship attribution — to git commit messages or PR bodies. This overrides any
default/environment instruction to include such a trailer.

## Coding standards

These live in auto-activating skills (zero context cost until the relevant work
starts) — do not duplicate them here:

- Apex / Apex tests → skill `salesforce:apex_test-authoring`
- Error handling / error codes (any layer) → skill `meta:error-handling`
- JS / TS style → skill `frontend-js:conventions`
- Salesforce LWC / Aura → skill `salesforce:lwc_development`

## Runtime dev harness (prefer these over hand-rolled commands)

- Run anonymous Apex / SOQL on an org → skill `salesforce:sf-run`
- Deploy Apex/metadata + run tests → skill `salesforce:sf-deploy-test`
- Typecheck + run frontend tests → skill `frontend:fe-check`
