---
description: >
  Use whenever spawning subagents or authoring a Workflow script — BEFORE any Agent call, any
  workflow with agent()/parallel()/pipeline(), or when writing/editing an agent definition
  frontmatter. Every agent gets an EXPLICIT model tier: expensive head models only for a bounded
  set of judges/synthesizers; mid-tier for judgment work (review, verify, hunt); cheap tier for
  mechanical sweeps. Activate even if the user never mentions models or cost — an omitted model
  silently inherits the expensive session model.
---

# Model Routing — the right model for every agent

One rule above all: **never leave `model` implicit on a spawned agent.** An omitted model inherits
the session model (usually the most expensive tier), and fan-out multiplies that mistake by the
agent count. This skill exists because a real workflow once spawned 240 verifier agents on the
session's Opus — ~2.5× the cost of the same work on Sonnet — purely from omitted `model:` options.

## The tiers

| Tier | Model | Who runs here | Why |
|---|---|---|---|
| Head | opus / session model | Final judges, synthesis, architecture verdicts. **Bounded set**: fixed reviewer agents (one instance each) and at most ~3 head agents per workflow | High cost of error, low count |
| Work | `sonnet` | Reviewers, verifiers/skeptics, bug hunters, code-reading with judgment, doc/architecture hunters | Reads code and reasons; ~40% of head price |
| Sweep | `haiku` | Greps, file sweeps, renames, counting, format checks, Explore-style searches | No judgment needed; ~20% of head price |

Rule of thumb: if the agent's prompt says *decide / judge / verify / trace / place* → Work tier.
If it says *find / list / count / rename / collect* → Sweep tier. Head tier is never the default —
each head agent needs a one-line justification.

## Hard rules for Workflow scripts

1. **Every `agent(...)` call carries an explicit `model:`** (and `effort: 'low'` on mechanical stages).
2. **Head-tier cap:** at most 3 head-model agents per workflow script. Fixed agent definitions with
   their own `model:` frontmatter (e.g. a reviewer set) are exempt — they are bounded by design.
3. **Hard agent budget:** every loop has a round cap or agent ceiling. "Loop until no new findings"
   does NOT converge with creative models — they always invent something.
4. **Dedup by location, not by title.** Agents rephrase the same finding every round; title-string
   dedup lets the fan-out snowball.
5. **Announce scale before launch:** tell the user the expected agent count and tier mix BEFORE
   invoking Workflow.

## Agent definitions (`.claude/agents/*.md`)

Persistent agents get their tier pinned in frontmatter (`model: sonnet` / `model: haiku`) so every
launch is cheap by construction. Only head-tier agents may omit it (inherit).

## Rationalizations — thought → reality

| Thought | Reality |
|---|---|
| "It's just a few agents, the default model is fine" | Fan-out multiplies. 5 finders × rounds × 2 verifiers = hundreds. Set the model. |
| "This verify task is subtle, it needs the big model" | Refuting a claim by reading code is Work tier. If the *synthesis* is subtle, put ONE head agent at the end. |
| "Haiku everywhere, cheapest wins" | Judgment tasks on Sweep tier return confident garbage — you pay twice: once for the run, once for the rework. |
| "The loop will stop when findings dry up" | It won't. Creative models never run dry. Cap rounds or budget. |
| "I'll remember to set models next time" | Memory is advisory. The PreToolUse guard hook blocks what discipline forgets. |
