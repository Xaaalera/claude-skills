---
description: Use when writing, fixing, or extending an Apex test — writing a test class for a new or changed Apex class, covering a negative or bulk path, adding a @TestSetup data factory, replacing System.assertEquals with Assert.*, removing a hardcoded record Id, mocking a RestRequest for a REST resource, or updating a test after you changed the class under test. Also whenever you create or edit any Apex `.cls` — every new class must get a matching test class in the same change. Covers data factories, @TestSetup, Assert.* assertions, FLS/user-mode testing, REST resource mocking, and bulk/positive/negative coverage.
---

# Apex Test Authoring

## When to Activate

- Creating a new Apex class → in the SAME change, create its matching test class. A class without a test is not done.
- Editing an existing Apex class → update (or create) its test so new branches are covered.
- Writing, fixing, or running Apex tests.
- Setting up Apex test data (factories, `@TestSetup`).

To run/deploy the tests against an org, use the **salesforce-dx MCP** (deploy_metadata, run_apex_test) — see the `salesforce-dx_mcp` skill, not raw `sf` CLI.

---

## Non-negotiable rules

These are house rules. Follow them even when the surrounding repo does something else (e.g. a repo where most tests still use `System.assert*` — we use `Assert.*` going forward).

1. **One test class per class, named `{ClassName}Test`.** No underscore. `UIConfigResource` → `UIConfigResourceTest`.
2. **Always `Assert.*`, never `System.assert*`.** Use `Assert.areEqual(expected, actual, msg)`, `Assert.isTrue`, `Assert.isFalse`, `Assert.isNull`, `Assert.isNotNull`, `Assert.fail(msg)`. Every assertion gets a message explaining what it verifies.
3. **`@IsTest(SeeAllData=false)`** — always. Never `SeeAllData=true`. Tests create the data they need.
4. **No hardcoded Ids.** Never type a `001...`/`a0X...` literal. Get Ids from inserted records or `UserInfo.getUserId()`.
5. **One test method = one behavior — strictly. Many small tests beat one big one.** This is SOLID/DRY/KISS applied to tests: each method verifies exactly ONE observable behavior and is named for it (`saveConfig_deletesCardsNotInPayload`, `getHandler_throwsOnUnknownType`). Never bundle several unrelated checks into a "kitchen-sink" test — if a method asserts two distinct behaviors, split it. A focused test that fails tells you precisely what broke; a big one tells you only that *something* did. Share setup via `@TestSetup` and factory helpers (DRY) so splitting costs nothing; keep each method short and obvious (KISS).
6. **Structure every test method with these comment markers**, in this order:
   ```apex
   @IsTest
   static void methodName_behavior() {
       // Setup
       ...
       // Exercise
       Test.startTest();
       ...
       Test.stopTest();
       // Verify
       Assert.areEqual(...);
   }
   ```
7. **Wrap the exercised code in `Test.startTest()` / `Test.stopTest()`** so it gets a fresh set of governor limits and async work flushes.
8. **Insert only the fields a test requires.** Don't populate fields the behavior under test doesn't read.
9. **Test data values live in constants** at the top of the test class (`private static final String KPI_TYPE_REVENUE = 'revenue';`). No magic strings scattered through methods.
10. **Every test class includes a dedicated adversarial suite that genuinely tries to break the class in as many distinct ways as actually apply.** Don't anchor on a number and stop — a fixed count becomes a ceiling ("wrote 7, done") when it should be a floor. Enumerate every way THIS class can be misused or fed bad state, then cover each one. As a sanity floor: if you've written fewer than ~7–10 break scenarios you've almost certainly under-tested; for a rich class expect more. One scenario per method (rule 5 applies here too). See **Adversarial / negative testing** below — mandatory, not optional.

---

## Data factories — search first, then create

Test data creation belongs in a reusable factory, not copy-pasted into each test.

- **Search first** for an existing factory (`TestDataFactory`, `TestDataSuite`, `*Factory*`) and reuse it. In AccountingCloud reuse `TestDataSuite` for core financial objects.
- **One fluent-builder class per SObject**, named `<Object>Factory` — constructor seeds required fields; `with<Field>(v)` setters chain; terminals `build()` / `build(true)` / `insertRecord()`. Never hardcode Ids. Don't lump several objects into one factory class.
- **Live in a dedicated `classes/factories/` folder** — create it if absent; propose consolidating scattered factories there (ask before moving shared/managed ones like `TestDataSuite`).

Full order of operations, builder shape + code example → `references/factories.md`.

---

## @TestSetup — shared pre-setup data

Baseline data shared by several test methods is built ONCE in a `@TestSetup` method (rolled back before each test); method-specific data stays in that method's `// Setup`. Create users/permission-set assignments there for `System.runAs`, and re-query records inside each test method (Ids don't survive the rollback boundary — re-SELECT).

Full guidelines + example → `references/factories.md` (§@TestSetup).

---

## FLS / user mode (`WITH USER_MODE`, `as user`)

Code using `WITH USER_MODE` queries or `as user` DML enforces the running user's FLS — the system context won't exercise it. Create a minimal-profile test user, assign the **shipped permission set** (not a System Admin), run the code inside `System.runAs(u)`, and add a **negative-permission test** (no permission set → assert `QueryException` / `DmlException` / `NoAccessException`). Universally-required fields have no separate FLS. Use a unique username per created user.

Setup patterns + the required-field nuance → `references/fls-and-rest.md`.

---

## REST resource tests (`@RestResource`)

Mock `RestContext` by hand: build `RestRequest`/`RestResponse`, set `requestURI` + `httpMethod`, call the method directly, and assert on `RestContext.response`. Use the namespaced URI (`/services/apexrest/AcctSeed/...`) and cover the URI-parsing branches (type-only vs type+itemId).

Full example → `references/fls-and-rest.md`.

---

## Adversarial / negative testing — mandatory

**Every test class MUST include an adversarial suite that genuinely tries to break the class across every distinct failure mode that applies** — don't anchor on a count (~7–10 is a floor, not a ceiling); diversity of vectors beats repetition. One break per method (rule 5), each named for the abuse, each asserting a *safe, specific* failure (the expected typed exception, or a defined empty/`null` result) — never a swallowed error or corrupted data. Use `try { ...; Assert.fail('should have thrown'); } catch (TheSpecificException e) { ... }` so a missing throw also fails.

Why happy-path is not enough + the full break-vector catalog (unknown key · malformed/null input · not-found · permission/FLS · cross-user sharing · boundary/overflow · idempotency · bulk/governor · wrong protocol shape) + the assert-exception pattern → `references/adversarial-testing.md`.

---

## Rationalizations this standard rejects

The shortcuts that feel reasonable under pressure — and why they fail:

| Thought | Reality |
|---|---|
| "Happy path passes — tests are done" | Defects and security holes live in garbage input / missing perms / not-found. The adversarial suite is mandatory. |
| "Wrote ~7 break tests, that's enough" | 7–10 is a FLOOR, not a ceiling. Enumerate every distinct vector THIS class allows, then cover each. |
| "Assertion fails — I'll relax it to green" | Never weaken an assertion to pass. Read the real failure, fix the code. |
| "One method can check these few things at once" | Kitchen-sink tests hide what broke. One observable behavior per method. |
| "System.assert works and the repo uses it" | House rule: `Assert.*` only, every assertion with a message. |
| "Trivial class, skip the test" | A class without a matching test is not done — same change. |
| "I'll hardcode this Id, it's just a test" | No hardcoded Ids ever. Derive from inserted records / `UserInfo`. |

---

## Coverage checklist for each class under test

Aim for behavior coverage, not a % number — but every public/exposed method needs:

- [ ] **Positive** path — normal input, asserts the real result (not just "no exception").
- [ ] **Negative** path — bad/empty input, missing permission, unknown key → assert the specific exception or empty/`null` result. Use a try/catch + `Assert.fail()` pattern, or assert on the returned error shape.
- [ ] **Bulk** — exercise with a list of records (≈200 where the code does DML in a loop or aggregates) to catch governor-limit and partial-processing bugs. Where the domain uses small fixed datasets, match that, but still loop rather than asserting a single record.
- [ ] **Boundary/branch** — each `if`/early-return in the method (e.g. empty saved config → falls back to defaults; blank external Id → generates one; item found vs not found).

---

## Skeleton — full test class

A complete `@IsTest` class (constants, `@TestSetup`, a `runAs` behavior test with Setup/Exercise/Verify markers) → `references/skeleton.md`.

---

## Workflow

1. Write/extend the **factory** for every object the class touches.
2. Write the **test class** (`{ClassName}Test`) following the rules above.
3. **Deploy + run** via the salesforce-dx MCP (`deploy_metadata`, then `run_apex_test` with `RunSpecifiedTests`, `codeCoverage: true`). See the `salesforce-dx_mcp` skill.
4. On failure, re-run with `verbose: true`, read the real assertion/stack, fix, repeat. Never weaken an assertion just to make it pass.

---

## Final checklist

- [ ] Test class named `{ClassName}Test`, `@IsTest(SeeAllData=false)`
- [ ] Only `Assert.*` assertions, each with a message
- [ ] `// Setup` / `// Exercise` / `// Verify` markers in every method, exercise wrapped in `Test.startTest/stopTest`
- [ ] Data built via a factory (reused or newly created — one method per object)
- [ ] Shared baseline in `@TestSetup`; constants for test values
- [ ] No hardcoded Ids; unique usernames for created users
- [ ] FLS/user-mode code exercised under `System.runAs` + permission set, with a negative-permission test
- [ ] REST methods mock `RestContext`, cover URI-parsing branches
- [ ] **Adversarial suite exhausts the distinct break vectors that apply (don't stop at a quota; ~7–10 is a floor), one break per method, each asserting a safe/specific failure**
- [ ] One behavior per test method — no kitchen-sink tests; many small focused tests over one big one (SOLID/DRY/KISS)
- [ ] Positive + negative + bulk + each branch covered
