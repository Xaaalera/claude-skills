# What the test standard caught — a running log

Every real defect found by a test written against the `tests` plugin's standard
(`tests:architecture` + `tests:apex`), kept for coursework. One entry per defect, always in the same
four parts: **what it was**, **what it became**, **which rule of the standard produced the case**,
and **what the defect would have cost in production**.

The point of the log is the third column. A defect found by "I thought of a case" teaches nothing
reusable; one found by walking a fixed list of axes is evidence that the list works. So every entry
names the axis, and an entry that cannot name one is a note rather than a finding.

Repository under test: `Accounting-Seed-UI` (React + TypeScript SPA over a Salesforce backend).
Method: derive the case space from the axis table in `references/case-space.md` — cardinality,
boundary, absence, idempotence, order, dependency failure, interleaving, time and locale, input
immutability, invariant, error shape, scale, permission — and for each axis either write a case or
write down why it does not apply.

---

## 2026-08-21 · Finding 1 — a well-formed impossible date rendered as a real one

**Where:** `src/pages/close-management/hooks/periodsFromRecords.ts` · `parseIsoDate`

**Axis:** 3, absence — specifically the distinction between *malformed* and *impossible*. The
function's own doc comment promised `null` for a malformed date, so the case asked what a
well-formed but impossible one does.

**What it was**

```ts
const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(iso);
if (!match) return null;
const [, year, month, day] = match;
return new Date(Number(year), Number(month) - 1, Number(day));
```

The regex checks the *shape*. `new Date(2026, 1, 31)` — 31 February — does not fail; it rolls
forward to 3 March. `2026-13-01` rolls to 1 January 2027. Both come back as a `Date` the caller then
formats and prints.

**What it became**

```ts
const parsed = new Date(Number(year), Number(month) - 1, Number(day));
// The shape being right does not make the date real: `new Date(2026, 1, 31)` rolls 31 February
// forward to 3 March, and month 13 rolls into the next January — both silently.
const roundTrips =
  parsed.getFullYear() === Number(year) &&
  parsed.getMonth() === Number(month) - 1 &&
  parsed.getDate() === Number(day);
return roundTrips ? parsed : null;
```

Reading the components back is the only thing that tells the two apart.

**The case that caught it**

```ts
it('reports nothing for a day the month does not have', () => {
  // 31 February is well-formed and impossible. `new Date(2026, 1, 31)` rolls it forward to
  // 3 March silently, so a period whose end date is upstream nonsense would render a
  // real-looking date three days off rather than nothing at all.
  expect(parseIsoDate('2026-02-31')).toBeNull();
});
```

**What it would have cost:** a *plausible* wrong date rather than a blank. Every consumer of this
parse — the period sub-label, the "Target close" line, the days-to-close average — would have shown
a date three days off, with nothing on screen to suggest it was derived from garbage. A blank is
self-reporting; a wrong date is not. Reachability is low today (the upstream field is a Salesforce
`Date`, which cannot hold 31 February), so the finding is about the contract, not about a live
outage: the function is exported and reused by two other modules, and the next caller may not have a
validating upstream.

---

## 2026-08-21 · Finding 2 — tasks on an invisible ledger vanished from the summary but not from the count

**Where:** `src/pages/close-management/hooks/periodsFromRecords.ts` · `buildLedgerStatuses`

**Axes:** 10, invariant — *the same tasks must be described by the period's own count and by its
sub-rows* — crossed with 13, permission. The invariant is what made the case worth writing; the
permission axis is what supplied the input that breaks it.

**What it was**

Tasks were grouped by their `Ledger__c` id, then the code walked the *ledger* list and emitted one
sub-row per ledger that had tasks. A task whose ledger was not in that list matched no branch: it
was not emitted, and it was not gathered into the cross-ledger group either (that group is defined
as tasks with a *blank* ledger). It simply disappeared.

Meanwhile the period's own `taskCount` and `blockers` were computed from the *whole* task list.

```ts
for (const ledger of ledgers) {
  const ledgerTasks = tasksByLedgerId.get(ledger.id);
  if (ledgerTasks?.length) statuses.push(buildLedgerRow(ledger.id, ledger.name, ledgerTasks, t));
}
if (crossLedgerTasks.length > 0) { /* blank-ledger group */ }
// anything left in tasksByLedgerId is silently dropped
```

**What it became**

```ts
for (const ledger of ledgers) {
  const ledgerTasks = tasksByLedgerId.get(ledger.id);
  if (ledgerTasks?.length) {
    statuses.push(buildLedgerRow(ledger.id, ledger.name, ledgerTasks, t));
    tasksByLedgerId.delete(ledger.id);
  }
}

// Whatever is LEFT names a ledger the ledger read did not return — deactivated, deleted, or one
// this user may not see. Dropping those rows would leave the period's own `taskCount` (and its
// blocker count) describing tasks no sub-row accounts for.
for (const orphanLedgerId of [...tasksByLedgerId.keys()].sort()) { … }
```

Plus one new translation key, `periods.ledger.unknown` — "Unknown ledger".

**The case that caught it**

```ts
it('still accounts for every task when one names a ledger the caller cannot see', () => {
  // three tasks, one of them on a ledger the ledger read did not return — a
  // permission-restricted, deactivated or deleted ledger, from this function's point of view
  const inSubRows = period.ledgers.reduce((sum, l) => sum + l.tasksTotal, 0);
  expect(inSubRows).toBe(period.taskCount);   // failed: 2 !== 3
});
```

The case immediately above it — the same invariant with every ledger visible — passed. That pairing
is the whole method: the invariant is not wrong, the *input* the permission axis supplies is the one
nobody had written down.

**What it would have cost:** a summary that contradicts the table under it, which is the most
expensive kind of wrong number because the user can see both. The Close Hub hero sums `tasksTotal`
across the sub-rows to render "12 of 40 tasks signed off", while the periods table prints
`taskCount` for the same period. With one task on an invisible ledger the two disagree, and nothing
on screen explains why. This exact class of divergence had already been hit once by hand on this
page — a KPI tile reading "24 across 2 periods" while the table showed 42 across 3 — and it took a
screenshot from the product owner to find. Here the axis walk found the second instance before the
code shipped.

**Reachability:** real. `BoardLedger` carries an `isActive` flag, so the ledger read can legitimately
return a narrower set than the tasks reference; a deleted ledger and a field-level permission
restriction produce the same input.

---

## Method notes worth keeping

- **Two of the three failures on the first run were real defects**, and the third was a fixture
  error in the test itself. The signal-to-noise of an axis-derived suite was high enough that the
  failures were worth reading one by one rather than being assumed to be the test's fault.
- **The invariant axis needed a partner.** "The sub-rows account for every task" is a true statement
  about the code as written, and asserting it on ordinary input passes. It only becomes a defect
  detector when a *different* axis (permission) supplies the input. Axes compose; a single-axis walk
  would have missed this.
- **The mutation check earned its place on the guard.** Three deliberate breaks of
  `isCellControlClick` — deleting one selector entry, matching an attribute's presence instead of its
  value, and swapping `closest()` for `matches()` — were each caught by a different case. That is
  what makes the suite's greenness mean something rather than merely being green.
