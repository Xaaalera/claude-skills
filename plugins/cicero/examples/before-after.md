# CICERO — before / after on one real question

The same coding question, answered twice: once by vanilla Claude, once with the
CICERO output style active. Both answers are **real transcripts**, not mock-ups.

The point of the example is honest: CICERO does **not** make the model *more correct*
— both answers reach the same architecture (idempotency table + OCC + transactional
outbox). CICERO changes the *delivery*: verdict first, jargon glossed, far shorter,
readable in one pass. The visible height difference between the two columns below is
the whole pitch.

## The question

> In a high-throughput Node.js service with horizontal autoscaling and at-least-once
> webhook delivery, should I use a Redis-backed distributed lock (Redlock) or optimistic
> concurrency control with a version column to make idempotent event processing safe
> against double-processing? Assume the handler is not referentially transparent.

## Side by side

<table>
<tr>
<th width="50%">Vanilla Claude</th>
<th width="50%">With CICERO</th>
</tr>
<tr valign="top">
<td>

**Short answer:** neither — at least not as the only mechanism. The right defence
against double-processing here is an idempotency table (dedup) keyed by event ID + OCC
on the state transitions. Of the two you named, Redlock is the worse choice. Here's why.

**Why this isn't "lock vs OCC"**

You framed this as a choice of mutual-exclusion mechanism, but the real problem isn't
concurrency — it's deduplication of at-least-once delivery. Those are different jobs:

- Mutual exclusion guards against *simultaneous* processing.
- Deduplication guards against *repeat* processing (including minutes later, when no
  lock exists anymore).

At-least-once gives you both, but the second is dominant, and a lock cannot close it: a
duplicate can arrive after the lock is released.

**Against Redlock (the deciding argument)**

Redlock is not a safety mechanism. This is Kleppmann's critique and it's exactly your case:

1. The lock can expire mid-processing — a GC pause, stop-the-world, network delay — the
   TTL lapses, a second instance takes the lock while the first is still "inside". Double
   processing under a formally valid lock.
2. The only cure is fencing tokens (a monotonic counter the protected resource checks and
   rejects when stale). But for the resource to check a fencing token it needs… a version
   column and a conditional write. So you arrive at OCC anyway — just with an extra
   external dependency (Redis), an extra failure mode, and a false sense of safety.

Plus the operational cost: another stateful component in the hot path, its own timeouts,
clock drift between nodes, degradation under network partitions.

**Why OCC + version column is the right base**

OCC pushes the atomicity guarantee into the datastore — the single source of truth. Two
instances read version = N, both write `UPDATE ... SET version = N+1 WHERE id = ? AND
version = N` — exactly one commits, the other gets 0 rows and rolls back. A real safety
guarantee at commit time, no external moving parts, no expired-TTL problem.

**But OCC alone isn't enough — the handler isn't referentially transparent**

Your side-effect caveat is critical here. OCC only protects the DB row. If the handler
calls an external API / sends mail first and then hits an OCC conflict at commit, the
effect already leaked. So you need three layers:

1. Idempotency table: `INSERT event_id` with a unique constraint as the first step. A
   duplicate → constraint violation → exit quietly. This is the main line of defence
   against at-least-once, and it works regardless of the gap between duplicates.
2. OCC on the state transition — atomicity and protection against lost updates on a race.
3. Make side effects idempotent or transactional:
   - external calls — pass your own idempotency key downstream (Stripe-style
     `Idempotency-Key`) so a duplicate collapses on their side;
   - what can't be made idempotent — via a transactional outbox: write the intent in the
     same transaction as the state transition, and a dispatcher sends the effect off the
     committed state, marking the send in the dedup table.

In practice: split the handler into decide (reads state, pure) and act (effects). Then an
OCC conflict rolls back decide without a leak, and act is guarded by an idempotency key
downstream.

**Recommendation**

- Base: idempotency table (event ID, unique) + OCC version column. Enough for
  "effectively-once" correctness at the DB-state level.
- Redlock — only to cut wasted work (an expensive handler you don't want two instances to
  run, knowing one rolls back on OCC). Then the lock is a throughput optimization over
  OCC, not a replacement, and its incorrectness doesn't affect safety.
- External effects are closed by an idempotency key downstream or an outbox — the piece
  that neither Redlock nor OCC solves, and which in your setup (non-referentially-
  transparent handler) is the real risk.

If you'd like, I can sketch the table schema (dedup + outbox) and handler pseudocode with
these three layers.

</td>
<td>

**Neither Redlock nor the version column alone. The root is idempotency-key dedup**
*(a table of processed `event_id`s with a unique constraint; the repeat insert fails →
the effect applies once)*.

- **Redlock** *(a distributed lock over Redis)* — not for correctness. On a GC pause
  *(process stalled by the garbage collector)* the lock's TTL lapses, a second instance
  enters — double processing under a formally live lock. Only fencing tokens
  *(a monotonic counter; the resource rejects stale ones)* fix it, and checking those
  needs a version column anyway. So Redlock is at most an optimization "don't run the
  expensive handler twice", never a guarantee.
- **OCC** *(optimistic concurrency control — don't lock the row; at write time check
  `WHERE version = N`; exactly one commits)* — a real DB-level guarantee, no external
  moving parts.
- **at-least-once** *(deliver "at least once" → duplicates are inevitable)* hits repeat
  processing minutes later, when no lock exists — a lock can't close that. The dedup
  table can.
- **The handler is not referentially transparent** *(it has side effects — mail, an
  external call)* — this decides it. OCC guards only the row; a side effect outside the
  transaction repeats on retry. You need a **transactional outbox** *(write the intent in
  the same transaction as the state transition; a separate worker emits it off the
  committed state)*.

**Verdict:** idempotency table + OCC + an outbox for side effects. The Redis lock is
optional — only against wasted work, never as the safety guarantee.

</td>
</tr>
</table>

## What CICERO changed (delivery, not substance)

| Rule | Vanilla | With CICERO |
|------|---------|-------------|
| **1 · Answer first** | verdict lives in a "Recommendation" section at the very bottom | verdict is the first sentence |
| **2 · Size to ask** | ~600 words, six headed sections | ~200 words, one list |
| **3 · Gloss** | Redlock, OCC, fencing tokens, at-least-once used raw | each glossed in-line on first use |
| **4 · Recommend, don't survey** | lays out the full analysis, then recommends | leads with the pick, detail follows |
| **0 · Readable first** | nested sub-lists and cross-references | flat points, one idea each |

Same conclusion, a third of the length, and you know the answer from line one.
