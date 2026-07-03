---
description: Author and maintain Apex unit tests to a strict house standard. Use WHENEVER you create or edit an Apex class (.cls), write or fix an Apex test, or set up Apex test data — every new Apex class must get a matching test class in the same change. Covers data factories, @TestSetup, Assert.* assertions, FLS/user-mode testing, REST resource mocking, and bulk/positive/negative coverage.
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

1. **One test class per class, named `{ClassName}Test`.** No underscore. `WidgetConfigResource` → `WidgetConfigResourceTest`.
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
9. **Test data values live in constants** at the top of the test class (`private static final String WIDGET_TYPE_SAMPLE = 'alpha';`). No magic strings scattered through methods.
10. **Every test class includes a dedicated adversarial suite that genuinely tries to break the class in as many distinct ways as actually apply.** Don't anchor on a number and stop — a fixed count becomes a ceiling ("wrote 7, done") when it should be a floor. Enumerate every way THIS class can be misused or fed bad state, then cover each one. As a sanity floor: if you've written fewer than ~7–10 break scenarios you've almost certainly under-tested; for a rich class expect more. One scenario per method (rule 5 applies here too). See **Adversarial / negative testing** below — mandatory, not optional.

---

## Data factories — search first, then create

Test data creation belongs in a reusable factory, not copy-pasted into each test.

- **Search first** for an existing factory (`TestDataFactory`, `SharedTestDataFactory`, `*Factory*`) and reuse it. In SharedPkg reuse `SharedTestDataFactory` for core objects.
- **One fluent-builder class per SObject**, named `<Object>Factory` — constructor seeds all required fields (a bare `new <Object>Factory().build()` is valid); a `with<Field>(v)` setter per varied field returns `this` to chain; terminals `build()` (in-memory) / `build(true)` / `insertRecord()` persist. Never hardcode Ids. Don't lump several objects into one factory class.
- **Live in a dedicated `classes/factories/` folder** — create it if absent; propose consolidating scattered factories there (ask before moving shared/managed ones like `SharedTestDataFactory`).

Full builder shape + code example → `references/factories.md`.

---

## @TestSetup — shared pre-setup data

When several test methods need the same baseline data, create it once in a `@TestSetup` method instead of rebuilding it per method. `@TestSetup` data is rolled back to its post-setup state before each test, so tests stay isolated.

```apex
@TestSetup
static void setup() {
    // Build the baseline every test starts from — via the factory.
    WidgetConfigTestDataFactory.createTestUserWithEditPerm();
}
```

Guidelines:
- Use `@TestSetup` only for data that is genuinely shared and read-only-ish across methods. Data a single test mutates in a method-specific way is better created in that method's `// Setup`.
- `@TestSetup` runs as the test-context user. Create users/permission-set assignments here so methods can `System.runAs` them.
- Re-query records inside the test method (don't rely on Ids captured at setup time across the rollback boundary — re-SELECT them).

---

## FLS / user mode (`WITH USER_MODE`, `as user`)

Code using `WITH USER_MODE` queries or `as user` DML enforces the running user's FLS — the system context won't exercise it. Create a minimal-profile test user, assign the **shipped permission set** (not a System Admin), run the code inside `System.runAs(u)`, and add a **negative-permission test** (no permission set → assert `QueryException` / `DmlException` / `NoAccessException`). Universally-required fields have no separate FLS. Use a unique username per created user.

Setup patterns + the required-field nuance → `references/fls-and-rest.md`.

---

## REST resource tests (`@RestResource`)

Mock `RestContext` by hand: build `RestRequest`/`RestResponse`, set `requestURI` + `httpMethod`, call the method directly, and assert on `RestContext.response`. Use the namespaced URI (`/services/apexrest/Pkg/...`) and cover the URI-parsing branches (type-only vs type+itemId).

Full example → `references/fls-and-rest.md`.

---

## Adversarial / negative testing — mandatory

Happy-path tests only prove the code works when everything is right; real defects and security holes live where callers send garbage, users lack rights, or records are missing. **Every test class MUST include an adversarial suite that genuinely tries to break the class across every distinct failure mode that applies** — don't anchor on a count (~7–10 is a floor, not a ceiling); diversity of vectors beats repetition. One break per method (rule 5), each named for the abuse, each asserting a *safe, specific* failure (the expected typed exception, or a defined empty/`null` result) — never a swallowed error or corrupted data. Use `try { ...; Assert.fail('should have thrown'); } catch (TheSpecificException e) { ... }` so a missing throw also fails.

The full break-vector catalog (unknown key · malformed/null input · not-found · permission/FLS · cross-user sharing · boundary/overflow · idempotency · bulk/governor · wrong protocol shape) + the assert-exception pattern → `references/adversarial-testing.md`.

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
