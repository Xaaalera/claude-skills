---
description: Deploy Apex/metadata to a Salesforce org and optionally run Apex tests, returning a terse deploy + test summary. Use whenever you deploy classes and want a quick pass/fail instead of parsing full `sf project deploy` / `sf apex run test` JSON by hand.
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
