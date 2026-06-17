---
name: salesforce-apex_test-authoring
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

**Order of operations:**
1. **Search for an existing factory** before writing data-setup code. Look for `TestDataFactory`, `TestDataSuite`, `*TestData*`, `*Factory*` classes in the repo. (In AccountingCloud the canonical one is `TestDataSuite` — a singleton accessed via `TestDataSuite.getInstance(true)` in `@TestSetup`, `getInstance()` inside tests, with fluent `create*()` builders. Reuse it for core financial objects.)
2. **One factory CLASS per SObject, written as a fluent builder — every factory has the SAME shape.** Each object a test touches gets its OWN factory class named `<Object>Factory` (e.g. `UIConfigFactory` for `UI_Config__c`, `UIKpiCardFactory` for `UI_KPI_Card__c`, `UserTestFactory` for `User`). Do NOT lump several objects into one factory class. Because they all share one shape, they read alike and chain naturally:
   - **Constructor** seeds all **required** fields with sensible defaults, so a bare `new <Object>Factory().build()` is already valid.
   - A **`with<FieldName>(value)`** setter for each field a test may vary — it mutates the in-progress record and `return this;` so calls chain.
   - **`build()`** → returns the **in-memory** record (no DML). **`build(Boolean doInsert)`** inserts first when `true`.
   - **`insertRecord()`** → separate terminal that inserts the built record and returns it (Apex reserves `insert`, so the method can't be named `insert`).
   - Optional **bulk** helper (e.g. `static List<SObject> buildAndInsert(Integer count, ...)`) for governor-limit tests.
   - Never hardcode Ids. Extend with more `with*`/helpers over time, but one object's creation logic stays in that one factory.

   Usage reads like a sentence:
   ```apex
   UI_KPI_Card__c card = new UIKpiCardFactory()
       .withConfig(cfg.Id)
       .withKpiType('cash')
       .withSortOrder(1)
       .build(true);   // build() = in-memory; build(true) or insertRecord() = persist
   ```
3. **Where the factory lives — a dedicated factory folder.** Keep test-data factories together, not scattered among production classes:
   - Look for an existing dedicated factory folder (e.g. `.../classes/factories/`).
   - **If none exists, create one** and put new factories there. Every factory we create goes into that folder.
   - **If factories already exist elsewhere in the repo, propose consolidating them** into that folder (ask before relocating shared/managed ones like `TestDataSuite` — don't silently move code others depend on).
   - In SFDX source format, Apex classes may live in subdirectories under `classes/`; they deploy the same. Keep one factory per cohesive area, not one giant method per test.

**Factory shape — one fluent-builder class per object:**
```apex
// File: classes/factories/UIKpiCardFactory.cls
@IsTest
public class UIKpiCardFactory {
    private final UI_KPI_Card__c record;

    public UIKpiCardFactory() {
        // Constructor seeds all REQUIRED fields with valid defaults.
        record = new UI_KPI_Card__c(
            KPI_Id__c     = 'test-' + sequence(),  // unique external Id; never hardcoded
            KPI_Type__c   = 'revenue',
            Timeframe__c  = 'CURRENT_PERIOD',
            Sort_Order__c = 0
        );
    }

    // One with<Field>() per varied field — each returns `this` to chain.
    public UIKpiCardFactory withConfig(Id configId)   { record.Config__c     = configId; return this; }
    public UIKpiCardFactory withKpiId(String v)       { record.KPI_Id__c     = v;        return this; }
    public UIKpiCardFactory withKpiType(String v)     { record.KPI_Type__c   = v;        return this; }
    public UIKpiCardFactory withTimeframe(String v)   { record.Timeframe__c  = v;        return this; }
    public UIKpiCardFactory withSortOrder(Integer v)  { record.Sort_Order__c = v;        return this; }

    // Terminals: build (optionally insert via the flag), or insert separately.
    public UI_KPI_Card__c build() { return build(false); }
    public UI_KPI_Card__c build(Boolean doInsert) {
        if (doInsert) { insert record; }
        return record;
    }
    public UI_KPI_Card__c insertRecord() { insert record; return record; }

    private static Integer counter = 0;
    private static Integer sequence() { return counter++; }
}
```
`UIConfigFactory`, `UserTestFactory`, etc. follow the EXACT same shape (constructor defaults → `with*` chain → `build()` / `build(true)` / `insertRecord()`), so any factory is used the same way.

---

## @TestSetup — shared pre-setup data

When several test methods need the same baseline data, create it once in a `@TestSetup` method instead of rebuilding it per method. `@TestSetup` data is rolled back to its post-setup state before each test, so tests stay isolated.

```apex
@TestSetup
static void setup() {
    // Build the baseline every test starts from — via the factory.
    UIConfigTestDataFactory.createTestUserWithEditPerm();
}
```

Guidelines:
- Use `@TestSetup` only for data that is genuinely shared and read-only-ish across methods. Data a single test mutates in a method-specific way is better created in that method's `// Setup`.
- `@TestSetup` runs as the test-context user. Create users/permission-set assignments here so methods can `System.runAs` them.
- Re-query records inside the test method (don't rely on Ids captured at setup time across the rollback boundary — re-SELECT them).

---

## FLS / user mode (`WITH USER_MODE`, `as user`)

Code that uses `WITH USER_MODE` queries or `... as user` DML enforces the running user's FLS and object permissions. A test running as the system context won't exercise that enforcement. So:

- Create a **test user** with a minimal profile and assign the **permission set** the feature ships with (e.g. `UI_KpiCardConfig_Edit`). Do this in the factory / `@TestSetup`. A minimal profile + the shipped permission set is enough — do NOT reach for a System Administrator user to dodge FLS.
- **Universally-required fields have no separate FLS.** Salesforce always grants access to a required custom field and you cannot assign `fieldPermissions` to it — so a permission set covering such fields legitimately has only `objectPermissions`. If every field the code touches is required, object-level access is all the running user needs for `WITH USER_MODE` / `as user`. Only worry about field FLS for *optional* fields.
- Run the exercised code inside `System.runAs(testUser) { ... }`.
- Add at least one **negative permission test**: run as a user WITHOUT the permission set and assert the expected `System.QueryException` / `DmlException` / `NoAccessException` is thrown.

```apex
User u = UIConfigTestDataFactory.createUserWithPermSet('UI_KpiCardConfig_Edit');
System.runAs(u) {
    Test.startTest();
    new UIKpiCardConfigHandler().saveConfig(payloadJson);
    Test.stopTest();
}
```

Create users with a unique username (append a UUID/timestamp) to avoid `DUPLICATE_USERNAME` across parallel test runs — and never hardcode the username.

---

## REST resource tests (`@RestResource`)

Mock the REST context by hand, then call the method directly and assert on `RestContext.response`.

```apex
// Setup
RestRequest req = new RestRequest();
RestResponse res = new RestResponse();
req.requestURI = '/services/apexrest/AcctSeed/ui/config/KPI_Cards'; // namespaced path when the org has a namespace
req.httpMethod = 'GET';
RestContext.request = req;
RestContext.response = res;

// Exercise
Test.startTest();
UIConfigResource.getConfig();
Test.stopTest();

// Verify
Assert.areEqual(200, RestContext.response.statusCode, 'GET should succeed');
Object body = JSON.deserializeUntyped(RestContext.response.responseBody.toString());
Assert.isNotNull(body, 'response body should be JSON');
```

For POST/PATCH set `req.requestBody = Blob.valueOf(jsonString)`. Cover URI-parsing branches explicitly: type-only URI (`/config/KPI_Cards`) vs type+itemId (`/config/KPI_Cards/<id>`), and the namespace-prefixed variant.

---

## Adversarial / negative testing — mandatory, ≥7 diverse scenarios

Happy-path tests tell you the code works when everything is right. They tell you nothing about what happens when a caller sends garbage, a user lacks rights, or a record is missing — which is exactly where real defects and security holes live. So **every test class must include an adversarial suite that actively tries to break the class under test, with at least 7 scenarios drawn from DIFFERENT break vectors below.** Seven variations of the same idea (e.g. seven malformed strings) do not count — diversity is the point; each vector exercises a distinct failure mode.

For each scenario, assert the code fails *safely and specifically*: it throws the **expected** typed exception (not a bare `Exception` you forgot to scope), or returns a defined empty/`null`/zero result — never silently corrupts data or swallows the error. Prefer `try { ...; Assert.fail('why this should have thrown'); } catch (TheSpecificException e) { Assert.isTrue(e.getMessage().contains(...), ...); }` so a *missing* throw also fails the test.

**Break vectors — pick ≥7 across distinct categories (more if the class warrants it):**

1. **Unknown / unsupported key** — an unregistered type, enum value, or lookup key (e.g. `getHandler('Nope')`). Assert the specific exception names the bad value.
2. **Malformed input** — invalid JSON, or valid JSON of the wrong shape (an object where a list is expected, a string where a number is). Assert it throws rather than persisting half-parsed data.
3. **Null / blank / empty input** — `null` body, empty string, empty list, blank required field. Distinguish "empty list = delete all" (defined behavior) from "null = error".
4. **Missing / not-found target** — read, update, delete, or reorder an Id that doesn't exist. Assert the defined result (`null`, `count = 0`) and that nothing else is touched.
5. **Permission denied / FLS** — run as a user WITHOUT the permission set, on BOTH a read and a write path (not just one method). Assert `QueryException` / `DmlException` / `NoAccessException`. A feature is only as safe as its least-tested entry point — cover every layer (handler, controller, REST resource), not just the innermost one.
6. **Cross-user / sharing isolation** — user A creates a record; assert user B cannot read or mutate it. Catches broken `with sharing` / OwnerId scoping that happy-path tests never reach.
7. **Boundary / overflow** — value out of allowed range, oversized string past field length, negative/huge numbers, duplicate external-Id collision. Assert the validation fires (or the upsert dedupes) rather than throwing an unhandled DML error to the user.
8. **Idempotency / double-op** — run the same destructive op twice (delete already-deleted, save same external Id twice). Assert the second call is a safe no-op / clean upsert, not a duplicate or crash.
9. **Bulk / governor limits** — feed ≥200 records to any method that does DML or queries in a loop. Assert it completes within limits and processes every record (catches SOQL-in-loop and partial-commit bugs).
10. **Wrong protocol shape (REST/Aura)** — for `@RestResource`: a URI missing the expected segment, extra trailing segments, or a method with no body. Assert the parser resolves correctly or fails cleanly.

Spread the ≥7 across the test classes for a feature so each layer is probed where it matters (e.g. permission + malformed-body at the REST resource, unknown-type + sharing at the handler). Name each test for the abuse: `saveConfig_throwsWhenUserLacksObjectAccess`, `getConfig_uriWithoutConfigSegmentResolvesNoTypeAndThrows`, `saveConfig_rejectsMalformedJson`, `getConfig_otherUsersConfigIsNotVisible`.

## Coverage checklist for each class under test

Aim for behavior coverage, not a % number — but every public/exposed method needs:

- [ ] **Positive** path — normal input, asserts the real result (not just "no exception").
- [ ] **Negative** path — bad/empty input, missing permission, unknown key → assert the specific exception or empty/`null` result. Use a try/catch + `Assert.fail()` pattern, or assert on the returned error shape.
- [ ] **Bulk** — exercise with a list of records (≈200 where the code does DML in a loop or aggregates) to catch governor-limit and partial-processing bugs. Where the domain uses small fixed datasets, match that, but still loop rather than asserting a single record.
- [ ] **Boundary/branch** — each `if`/early-return in the method (e.g. empty saved config → falls back to defaults; blank external Id → generates one; item found vs not found).

**Asserting an expected exception:**
```apex
// Exercise + Verify
Test.startTest();
try {
    UIConfigHandlerFactory.getHandler('Nope');
    Assert.fail('Expected UIConfigException for unknown config type');
} catch (UIConfigHandlerFactory.UIConfigException e) {
    Assert.isTrue(e.getMessage().contains('Unknown config type'), 'message names the bad type');
}
Test.stopTest();
```

---

## Skeleton — full test class

```apex
@IsTest(SeeAllData=false)
private class UIKpiCardConfigHandlerTest {

    private static final String KPI_TYPE_REVENUE = 'revenue';
    private static final String TIMEFRAME_PERIOD = 'CURRENT_PERIOD';

    @TestSetup
    static void setup() {
        UIConfigTestDataFactory.createUserWithPermSet('UI_KpiCardConfig_Edit');
    }

    @IsTest
    static void getConfig_returnsDefaultsWhenNoSavedCards() {
        // Setup
        User u = [SELECT Id FROM User WHERE Alias = 'uicfg01' LIMIT 1];
        // Exercise
        Object result;
        System.runAs(u) {
            Test.startTest();
            result = new UIKpiCardConfigHandler().getConfig();
            Test.stopTest();
        }
        // Verify
        List<Object> cards = (List<Object>) result;
        Assert.areEqual(4, cards.size(), 'should fall back to the 4 default CMDT cards');
    }
}
```

---

## Workflow

1. Write/extend the **factory** for every object the class touches.
2. Write the **test class** (`{ClassName}Test`) following the rules above.
3. **Deploy + run** via the salesforce-dx MCP (`deploy_metadata`, then `run_apex_test` with `RunSpecifiedTests`, `codeCoverage: true`). See the `salesforce-dx_mcp` skill.
4. On failure, re-run with `verbose: true`, read the real assertion/stack, fix, repeat. Never weaken an assertion just to make it pass.

## Final checklist

- [ ] Test class named `{ClassName}Test`, `@IsTest(SeeAllData=false)`
- [ ] Only `Assert.*` assertions, each with a message
- [ ] `// Setup` / `// Exercise` / `// Verify` markers in every method, exercise wrapped in `Test.startTest/stopTest`
- [ ] Data built via a factory (reused or newly created — one method per object)
- [ ] Shared baseline in `@TestSetup`; constants for test values
- [ ] No hardcoded Ids; unique usernames for created users
- [ ] FLS/user-mode code exercised under `System.runAs` + permission set, with a negative-permission test
- [ ] REST methods mock `RestContext`, cover URI-parsing branches
- [ ] **Adversarial suite: ≥7 diverse "try to break it" scenarios across distinct break vectors, each asserting a safe/specific failure**
- [ ] Positive + negative + bulk + each branch covered
