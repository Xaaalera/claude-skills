# Xaaalera — Claude Code skills

My personal [Claude Code](https://claude.com/claude-code) skill library, published as a plugin
**marketplace**. Each domain is a plugin; skills live inside it and load via the marketplace —
no copied folders, no duplication.

- **Invoke** a skill as `<plugin>:<skill>` (e.g. `meta:ockham`, `frontend-react:component-placement`).
- The `@xaaalera` suffix is only the install/enable key — never part of the invocation.
- Enable/disable is per **plugin**, so domains are split fine-grained for independent control.

## Install

From Claude Code:

```
/plugin marketplace add Xaaalera/claude-skills
/plugin install scout@xaaalera
```

> **Install [`scout`](#scout) first — it's the one plugin that finds all the others.** It ships the
> whole compiled catalog, so you just ask — *"which skills would help me in this project?"*, *"what's
> here / what helps with this task?"* — and it discovers, recommends, and installs any other skill on
> demand, including ones you haven't installed yet. One plugin to reach the rest; grab the specific
> ones below only if you already know what you want.

Or wire it into a project's `.claude/settings.json` and run `/plugin`:

```json
{
  "extraKnownMarketplaces": {
    "xaaalera": { "source": { "source": "github", "repo": "Xaaalera/claude-skills" } }
  },
  "enabledPlugins": {
    "frontend-react@xaaalera": true,
    "frontend-css@xaaalera": true,
    "git@xaaalera": true
  }
}
```

Project skills win over plugin skills on a name clash.

## Adopt the review gate in your repo

One command, from the root of the repo you want to protect (needs the GitHub CLI, `gh auth login`):

```bash
bash <(gh api repos/Xaaalera/claude-skills/contents/plugins/review/bootstrap.sh -H "Accept: application/vnd.github.raw")
```

It seeds `.claude/review.config.json`, `.husky/pre-push`, and `.github/workflows/review-gate.yml`, and
wires this marketplace + `review@xaaalera` and `review-workflow@xaaalera` into the repo's committed
`.claude/settings.json`. Nothing is vendored — the harness comes from npm. Then commit, `npm i -D husky
&& npx husky init` to arm the local hook, and make **`review-gate`** a required status check in branch
protection (the real enforcer). Tailor `.claude/review.config.json` per the [`setup`](#setup) skill.

## Guard the gate — [`cerberus`](#leak-check)

**If you publish skills anywhere public, install this first.** When a skill library is authored
alongside private work, it is easy for an example to quietly pick up something specific to that
work rather than a clean invented demo. Scrubbing it after the fact is slow and nerve-wracking;
catching it at edit time is not. `cerberus` is that nudge — the moment you touch a skill, it checks
the change and flags anything that reads as real before it ships.

**Why it's an agent, not a regex:** a denylist scanner that *lists the things to catch* is itself a
leak. So `cerberus` keeps **zero denylist by design** — a path-only **PostToolUse hook** fires on any
edit under `skills/`, `references/`, or `evals/` (or to a `SKILL.md` / `plugin.json` /
`marketplace.json`) — it reads the file path, never the content, so it names nothing — and the
**[`leak-check`](#leak-check) skill** reads the change in context and rewrites anything that looks
copied-from-real onto one fictional demo product before it ships.

### Install

```
/plugin install cerberus@xaaalera
```

Or enable it in a project's `.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "cerberus@xaaalera": true
  }
}
```

Nothing to vendor, no CI wiring — one hook plus one skill. The hook arms itself when the plugin loads.

## Plugins

Install as `<plugin>@xaaalera`; invoke skills as `<plugin>:<skill>`. Skill links jump to [Skills](#skills).

| Plugin | What it does | Skills |
|---|---|---|
| `scout` | **Start here — the plugin that finds all the others.** Reads this marketplace's compiled catalog to discover/recommend/install any skill on demand (even ones you haven't installed), surfacing declared side effects and treating catalog text as untrusted data; never runs code itself. | [scout](#scout) |
| `cerberus` | Leak guard at the gate — a PostToolUse hook reminds on any skill/eval edit; the agent skill reviews the change for work-codebase fingerprints (real class/object/namespace names, secrets, employer brand, domain flavor) and rewrites them to a fictional demo before they ship. No denylist by design. | [leak-check](#leak-check) |
| `cicero` | House voice — an always-on output style (result first, plain words, honest) plus hooks for the banner and reply-language. | hook only — [see the difference →](plugins/cicero/examples/before-after.md) |
| `diagram` | Architecture/flow diagram authoring — spec or raw code → readable, clickable D2→ELK page; Atlas + Sextant-hardened. | [diagram](#diagram) |
| `docs` | Documentation standard — four layers with one duty each, a per-section README that states that section's own rules, and one deterministic check that blocks a push when a declared mechanism changes without its doc. | [standard](#standard) |
| `plan-gate` | *(project)* PreToolUse hook — blocks Edit/Write to code unless you are off `main` and a plan matching the branch task-id exists. | — (hook only) |
| `error` | Error handling — the unified error envelope + reason-code vocabulary, and the framework-agnostic client-side error-handling architecture. | [format](#format), [architecture](#architecture) |
| `diogenes` | Per-session token-spend report, narrated by Diogenes the Cynic. | [diogenes](#diogenes) |
| `lovecraft` | House narrative voice for the engineering journal — expedition-journal post-mortems. | [lovecraft](#lovecraft) |
| `frontend-css` | CSS conventions — rem units, SCSS modules, responsive breakpoint validity. | [rem](#rem), [scss-modules](#scss-modules), [responsive-layout](#responsive-layout) |
| `frontend-js` | JavaScript/TypeScript style conventions. | [conventions](#conventions) |
| `frontend-react` | React conventions — placement, structure, hooks, primitives, layout, skeletons, stories. | [component-placement](#component-placement), [component-structure](#component-structure), [feature-components](#feature-components), [hooks-registry](#hooks-registry), [layout-components](#layout-components), [skeleton-components](#skeleton-components), [storybook-stories](#storybook-stories), [ui-primitive-reuse](#ui-primitive-reuse) |
| `frontend` | Frontend dev-harness — types + tests runner. | [fe-check](#fe-check) |
| `git` | Git workflow — atomic commit splitting. | [commit](#commit) |
| `i18n` | Route user-facing strings through localization. | [ui-strings](#ui-strings) |
| `jira` | Short, essence-first Jira comments. | [comment-style](#comment-style) |
| `meta` | Design law, doc writing, skill authoring, model routing. | [lean-writing](#lean-writing), [model-routing](#model-routing), [new-skill](#new-skill), [skill-eval](#skill-eval), [ockham](#ockham), [solid](#solid), [triage](#triage), [wittgenstein](#wittgenstein) |
| `review` | Stack-agnostic pre-push review framework — reviewer agents, `/review`, secret-scan + attestation gate. | [setup](#setup) (+ `/scavenge`, `review-scavenger` agent) |
| `review-workflow` | Workflow script that dispatches the review plugin's five lenses in parallel, reconciles findings, and checks the gate criteria before `/review` may attest. | — (workflow script only) |
| `salesforce` | Apex tests, LWC, security, deploy/run harness. | [apex_test-authoring](#apex_test-authoring), [dx_mcp](#dx_mcp), [lwc_development](#lwc_development), [security_review-rules](#security_review-rules), [sf-deploy-test](#sf-deploy-test), [sf-run](#sf-run) |
| `tests` | The test standard — execution tiers declared by filename, the numbered rules a test must satisfy, the axes a case space is derived from, factories and matchers, a JSON failure envelope, and the coverage and mutation gates. Ships a whole-tree audit agent, a per-repo config, and a recommendations reporter that installs only what you name. | [architecture](#architecture), [apex](#apex) |
## Skills

Grouped by plugin. Each group links back to [Plugins](#plugins).

### cerberus &nbsp;·&nbsp; [↑ Plugins](#plugins)
- <a id="leak-check"></a>**leak-check** — the leak guard's agent pass. Before a new or edited skill,
  reference, or eval fixture ships to this PUBLIC marketplace, review the change for anything that points
  to a real work codebase (real class/object/namespace/org/ticket names, secrets, real people/emails, an
  employer brand, or the aggregate domain flavor) and rewrite it to a neutral fictional demo. A
  **PostToolUse** hook nudges it on every skill/eval edit; there is no denylist by design — a list of the
  real names to catch would itself be the leak.

### cicero &nbsp;·&nbsp; [↑ Plugins](#plugins)
Not a skill — the house communication style. The **numbered rules** under one governing readability rule
(result first, plain words, avoid a specialized term instead of glossing it, recommend one option,
push back, honesty, work silently by default; a closing joke is optional) ship as a
**force-for-plugin output style**
([output-styles/cicero.md](plugins/cicero/output-styles/cicero.md)), applied at the system-prompt level
whenever the plugin is on. Two hooks carry the runtime bits: a **SessionStart** hook shows a banner, a worked
example of the finding-tree notation, and picks the conversation language; a **UserPromptSubmit** hook (`language-nudge`) keeps the reply language
current across a mid-session switch.

**Why use it:** see [before / after on real questions](plugins/cicero/examples/before-after.md) — the same
answers with and without CICERO, side by side. Same conclusions; the answer lands first, plain words
replace the jargon, and it reads a third to two-thirds shorter.

### diogenes &nbsp;·&nbsp; [↑ Plugins](#plugins)
- <a id="diogenes"></a>**diogenes** — Per-session token-spend report narrated by Diogenes the Cynic:
  session totals + cost, per-skill amortized cost, the heaviest tool-results and output turns. Use when
  you ask where tokens went, who's eating tokens, or what the session cost.

### lovecraft &nbsp;·&nbsp; [↑ Plugins](#plugins)
- <a id="lovecraft"></a>**lovecraft** — the Chronicler of the Unknown: house narrative voice for the
  engineering journal (xaaalera.github.io). Expedition-journal post-mortems — dated log entries, eroding
  composure, exact numbers, a survivor's protocol at the end.

### docs &nbsp;·&nbsp; [↑ Plugins](#plugins)
- <a id="standard"></a>**standard** — Where a document belongs and whether anything keeps it honest: four layers separated by update discipline (decision, mechanism, rule, frozen record), a `README.md` in every layer root answering five fixed questions about that section's own rules, and a vendored `docs-check.py` that fails a push when a declared mechanism changes and its doc does not. Installs into a target repo with its own hook and CI workflow.

### error &nbsp;·&nbsp; [↑ Plugins](#plugins)
- <a id="format"></a>**format** — The unified error envelope + reason-code vocabulary: uniform error paths across layers — throwing from a service/route/controller and reading errors on the client.
- <a id="architecture"></a>**architecture** — The framework-agnostic client-side error-handling architecture: one code→UX policy table as the sole classifier, a state-dispatcher, a shared error-tile renderer that owns escalation, boundary tiers + a single outer floor; role-named with per-framework bindings.

### frontend-css &nbsp;·&nbsp; [↑ Plugins](#plugins)
- <a id="rem"></a>**rem** — Always size in `rem`, never `px`, so type and spacing scale with the user's
  root font size. Applies whenever CSS / SCSS / Tailwind is written or reviewed.
- <a id="scss-modules"></a>**scss-modules** — House conventions for SCSS modules: structure, the
  color/spacing/radius token system, BEM. Applies any time styles are created, modified, or refactored.
- <a id="responsive-layout"></a>**responsive-layout** — The definition-of-done that a component/page
  renders validly at every breakpoint (no overflow, readable text, discernible images, restrained
  borders, sane density); proposes a breakpoint scale if the project has none. Stack-agnostic.

### frontend-js &nbsp;·&nbsp; [↑ Plugins](#plugins)
- <a id="conventions"></a>**conventions** — House JS/TS style: arrow functions, single quotes, full
  variable names, braces on every control structure, path aliases over deep relative imports.

### frontend-react &nbsp;·&nbsp; [↑ Plugins](#plugins)
- <a id="component-placement"></a>**component-placement** — The entry point *before* creating any
  component: first search for an existing one, then decide placement (primitive / feature / layout /
  page-local) and route to the matching skill.
- <a id="component-structure"></a>**component-structure** — How a component's files are laid out
  (tsx/scss/index), BEM naming, styling, barrel exports. Apply when creating, editing, or reviewing one.
- <a id="feature-components"></a>**feature-components** — Rules for *feature* components: domain-coupled
  blocks that compose primitives and hold business logic/data.
- <a id="hooks-registry"></a>**hooks-registry** — Before writing a custom `use*` hook, check the registry
  to reuse an existing one; update it whenever a hook is added/renamed/removed.
- <a id="layout-components"></a>**layout-components** — Rules for app-chrome / layout: the shell, top bar,
  sidebar, command palette, and global overlays that frame every page.
- <a id="skeleton-components"></a>**skeleton-components** — When a component renders async-loaded data,
  build a colocated loading-skeleton component from the shared Skeleton primitive.
- <a id="storybook-stories"></a>**storybook-stories** — After making a component, decide whether it needs
  a Storybook story and which states it should cover; honor the project's recorded yes/no choice.
- <a id="ui-primitive-reuse"></a>**ui-primitive-reuse** — Before hand-rolling any shared primitive
  (button, input, dialog, badge…), search the primitive library first and reuse/extend it.

### frontend &nbsp;·&nbsp; [↑ Plugins](#plugins)
- <a id="fe-check"></a>**fe-check** — Typecheck and run targeted unit tests for a frontend repo, returning
  a terse one-block summary — instead of running `tsc` and `vitest` separately.

### git &nbsp;·&nbsp; [↑ Plugins](#plugins)
- <a id="commit"></a>**commit** — Split all uncommitted changes into atomic, logical commits — one concern
  each, conventional-commit messages. Use whenever committing or pushing.

### i18n &nbsp;·&nbsp; [↑ Plugins](#plugins)
- <a id="ui-strings"></a>**ui-strings** — Route every user-facing string (labels, buttons, errors, toasts,
  empty states) through the localization system instead of hardcoding it.

### jira &nbsp;·&nbsp; [↑ Plugins](#plugins)
- <a id="comment-style"></a>**comment-style** — Keep Jira comments short and essence-first: bottom line up
  top, one-line bullets, understandable on the first read.

### meta &nbsp;·&nbsp; [↑ Plugins](#plugins)
- <a id="lean-writing"></a>**lean-writing** — Write specs, design docs, and summaries terse: short plain
  sentences, bullets over prose, no filler — caveman-simple but technically precise.
- <a id="model-routing"></a>**model-routing** — Assign an explicit model tier to every spawned agent /
  fan-out / eval before it launches; measure one unit and show the cost table before scaling.
- <a id="new-skill"></a>**new-skill** — How to author a new skill in the plugin model: naming, `SKILL.md`
  structure, and where it goes (`plugins/<domain>/skills/<name>/`).
- <a id="skill-eval"></a>**skill-eval** — Faithfully measure whether a skill's description triggers and
  score it (bundled `score-description.py`, self-contained); the canonical measurer, replaces
  skill-creator's false-negative-prone run_eval.
- <a id="ockham"></a>**ockham** — The Razor. Invoke *before* creating any new entity (file, module,
  abstraction, config key…) to challenge whether it should exist at all.
- <a id="solid"></a>**solid** — The design law for code (SRP/OCP/LSP/ISP/DIP + DRY/KISS/YAGNI). Activate
  at design time and when writing/reviewing code. Pairs with [`ockham`](#ockham).
- <a id="triage"></a>**triage** — Shallow first, deep only where it hurts: before any expensive exhaustive
  operation (fleet evals, big-diff review, migrations, repo sweeps), run a cheap full-coverage sorting
  pass, then spend the deep pass on the shortlist only.
- <a id="wittgenstein"></a>**wittgenstein** — Clarity gate for specs and plans: audit each section so a
  non-technical reader grasps its point and nothing is a bloated wall of text, then fix it in place.

### review &nbsp;·&nbsp; [↑ Plugins](#plugins)
- <a id="setup"></a>**setup** — Install and target the stack-agnostic pre-push review framework in a repo:
  reviewer agents (security, architecture, conventions, tests, docs), the `/review` orchestrator, and a
  secret-scan + attestation git/CI gate, all driven by a per-project `.claude/review.config.json`.
- **`review-scavenger` agent** — Cruft & Reuse reviewer (threshold 8/10). Blocks when a diff introduces
  duplicate files/hooks/services/utils or raw re-implementations of existing transports. Whole-repo aware
  but gates only on the diff; pre-existing cruft → Advisory only.
- **`/scavenge` command** — On-demand full-app hunt (not pre-push). Sweeps `src/` and `server/` for dead
  files, unused exports/dependencies, duplicated logic, and consolidatable services; appends a deduped
  `🐀 Scavenger` section to `docs/superpowers/BACKLOG.md`.

### salesforce &nbsp;·&nbsp; [↑ Plugins](#plugins)
- <a id="apex_test-authoring"></a>**apex_test-authoring** — Author Apex unit tests to a strict house
  standard: per-object fluent-builder factories, `@TestSetup`, `Assert.*`, FLS/user-mode, and bulk +
  positive + negative coverage. Every new Apex class gets a matching test class in the same change.
- <a id="dx_mcp"></a>**dx_mcp** — Prefer the salesforce-dx MCP tools over the raw `sf` CLI for any org
  interaction — SOQL/Tooling queries, running Apex tests, deploying or retrieving metadata.
- <a id="lwc_development"></a>**lwc_development** — House rules for building Lightning Web Components /
  Aura: the `.js` controller, `.html` template, `.js-meta.xml`, DOM access, and styling conventions.
- <a id="security_review-rules"></a>**security_review-rules** — Security review checklist: secret
  leakage, BFF route auth, the client token boundary, SOQL injection, XSS, and the AppExchange Security
  Review bar for Apex.
- <a id="sf-deploy-test"></a>**sf-deploy-test** — CLI fallback that deploys Apex/metadata to an org and
  returns a compact two-line pass/fail + test summary (a bash wrapper over `sf project deploy` +
  `sf apex run test`). Prefer [`dx_mcp`](#dx_mcp) when the project has the MCP.
- <a id="sf-run"></a>**sf-run** — Run anonymous Apex or a SOQL query against an org and get a terse
  pass/fail result — instead of hand-rolling `sf org display` + a Tooling API curl.

### scout &nbsp;·&nbsp; [↑ Plugins](#plugins)
- <a id="scout"></a>**scout** — Passive, never runs: instructs the agent to read this marketplace's
  bundled `catalog.json`, then Discover (list skills grouped by plugin with their purpose), Recommend
  (match a task to a skill and explain why, disclosing transitive `needs`), Safety (surface declared
  `changes` tags/notes — never "certified safe"), and Install (the unit is the plugin, not the skill —
  state sibling skills and needs before confirming, then run `/plugin install <plugin>@xaaalera` and
  prompt `/reload-plugins`).

## How it works

`plugins/<domain>/` is hand-edited source. There is **no generator** — `plugins/`, this `README.md`, and
`.claude-plugin/marketplace.json` are all maintained by hand. A PostToolUse hook auto-commits and pushes
on edits under the skills tree.

## Adding a skill

See [`new-skill`](#new-skill). New skill in an existing plugin: just add
`plugins/<domain>/skills/<name>/SKILL.md`. New domain: also add
`plugins/<domain>/.claude-plugin/plugin.json`, a row in the [Plugins](#plugins) table, an entry in
`.claude-plugin/marketplace.json`, and enable `<domain>@xaaalera` in `~/.claude/settings.json`.

> Local-only infra (hook + statusline scripts) lives in `claude-config/`, which is gitignored — it is
> not part of the published marketplace.

## Eval gate (CI)

Every touched or new skill must ship a trigger eval. The **eval-gate** GitHub Actions check
(`scripts/eval-gate.sh`, a required status check on `main`) fails the PR if a touched skill has no valid
`evals/trigger-eval.json` (JSON array of ≥6 `{query, should_trigger}` cases, ≥1 positive and ≥1
negative). It only *warns* — never fails — when the eval exists but has not been measured or has gone
stale. Refresh a measurement with
`python3.14 scripts/optimize_description.py --skill-path <dir> --apply`.

Server-side only — nothing to install per clone. Untouched legacy skills are never inspected.

### tests &nbsp;·&nbsp; [↑ Plugins](#plugins)
- <a id="architecture"></a>**architecture** — The standard itself: which execution tier a test file belongs to and how its filename declares it, the numbered rules a test must satisfy, the fixed axis list a case space is derived from, one factory per entity, assertions that state the rule rather than its encoding, a JSON failure envelope every custom matcher fills in, and the coverage ratchet plus the mutation bar that keeps a coverage floor from being decoration. Carries a transition section, so a repository adopting it knows what is in force before every mechanism exists.
- <a id="apex"></a>**apex** — The Apex delta of the same standard: what that runtime does differently, and nothing the shared rules already say. Loads `architecture` first by design.

Also in the plugin, and neither is a skill: a read-only whole-tree audit agent that answers for every numbered rule — including the ones nothing runs unattended — and `tests-recommend`, which reports what the recommended environment is missing and what its absence costs, installing only what you name.
