---
description: "Ship Salesforce Apex classes or metadata to an org and get back a compact pass/fail summary \u2014 deploy status plus optional Apex test results \u2014 instead of wading through raw `sf project deploy` / `sf apex run test` output.\n\nUse this for any request to deploy, push, or ship Apex/LWC/metadata (a single class, several classes, or a whole package/directory like widgetSettings) to a Salesforce org, whether or not tests are also run. Also use it to run specific test classes right after deploying, or to check test results as part of a deploy. And use it when a deploy has failed and the user needs help interpreting or fixing the error \u2014 including source-tracking, unsafe-path, or cross-repo shared-object failures.\n\nDon't use it for anonymous Apex snippets, ad-hoc SOQL queries, listing orgs, code review, or building UI components with no deploy involved."
---

# sf-deploy-test — deploy + run tests

A colocated script (`sf-deploy-test.sh`, in this skill's directory) wraps
`sf project deploy start` (+ optional `sf apex run test`) and prints a two-line summary.

## Use it

```bash
bash "<this-skill-dir>/sf-deploy-test.sh" --project-dir /path/to/repo \
     --source-dir force-app/main/default/classes/Foo.cls --tests FooTest
bash "<this-skill-dir>/sf-deploy-test.sh" --metadata "ApexClass:Foo" --tests "FooTest,BarTest"
```

- `--org <alias>` — default `myOrg`.
- `--project-dir <path>` — where to run `sf` from (default: current dir).
- `--source-dir <path>` (repeatable) OR `--metadata <Type:Name>` (repeatable).
- `--tests <ClassA,ClassB>` — optional; comma-separated test classes/methods.
- Always deploys with `--ignore-conflicts`.

## Output

- `deploy: Succeeded` / `deploy: Failed — <problems>` / `deploy: ERROR — <message>`.
- `tests: X/Y passed` / `tests: X/Y passed — FAIL: <names>` (only when `--tests` given).

## Gotcha

If a deploy fails with `The filepath "../<other-repo>/…" contains unsafe character sequences`,
the CLI is resolving a shared object across sibling repos. This is an environment/source-tracking
issue, not a code problem — it will show up as `deploy: ERROR — …`. Deploy that shared object
from its owning repo, or resolve the cross-repo source-tracking state before retrying.
