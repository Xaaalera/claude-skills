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
/plugin install review@xaaalera
```

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

It vendors the gate (`scripts/review/*`, `.husky/pre-push`, `.github/workflows/review-gate.yml`), seeds
`.claude/review.config.json`, and wires this marketplace + `review@xaaalera` into the repo's committed
`.claude/settings.json`. Then commit, `(cd scripts/review && npm i)` + `npm i -D husky && npx husky init`
to arm the local hook, and make **`review-gate`** a required status check in branch protection (the real
enforcer). Tailor `.claude/review.config.json` per the [`setup`](#setup) skill.

## Plugins

Install as `<plugin>@xaaalera`; invoke skills as `<plugin>:<skill>`. Skill links jump to [Skills](#skills).

| Plugin | What it does | Skills |
|---|---|---|
| `cicero` | House voice — SessionStart + Stop hooks that set a plain, concise, bottom-line-first reply style. | — (hook only) |
| `diagram` | Architecture/flow diagram authoring — spec or raw code → readable, clickable D2→ELK page; Atlas + Sextant-hardened. | [diagram](#diagram) |
| `diogenes` | Per-session token-spend report, narrated by Diogenes the Cynic. | [diogenes](#diogenes) |
| `lovecraft` | House narrative voice for the engineering journal — expedition-journal post-mortems. | [lovecraft](#lovecraft) |
| `frontend-css` | CSS conventions — rem units, SCSS modules. | [rem](#rem), [scss-modules](#scss-modules) |
| `frontend-js` | JavaScript/TypeScript style conventions. | [conventions](#conventions) |
| `frontend-react` | React conventions — placement, structure, hooks, primitives, layout, skeletons, stories. | [component-placement](#component-placement), [component-structure](#component-structure), [feature-components](#feature-components), [hooks-registry](#hooks-registry), [layout-components](#layout-components), [skeleton-components](#skeleton-components), [storybook-stories](#storybook-stories), [ui-primitive-reuse](#ui-primitive-reuse) |
| `frontend` | Frontend dev-harness — types + tests runner. | [fe-check](#fe-check) |
| `git` | Git workflow — atomic commit splitting. | [commit](#commit) |
| `i18n` | Route user-facing strings through localization. | [ui-strings](#ui-strings) |
| `jira` | Short, essence-first Jira comments. | [comment-style](#comment-style) |
| `meta` | Design law, error handling, doc writing, skill authoring, model routing. | [error-handling](#error-handling), [lean-writing](#lean-writing), [model-routing](#model-routing), [new-skill](#new-skill), [ockham](#ockham), [solid](#solid), [triage](#triage), [wittgenstein](#wittgenstein) |
| `review` | Stack-agnostic pre-push review framework — reviewer agents, `/review`, secret-scan + attestation gate. | [setup](#setup) (+ `/scavenge`, `review-scavenger` agent) |
| `salesforce` | Apex tests, LWC, security, deploy/run harness. | [apex_test-authoring](#apex_test-authoring), [dx_mcp](#dx_mcp), [lwc_development](#lwc_development), [security_review-rules](#security_review-rules), [sf-deploy-test](#sf-deploy-test), [sf-run](#sf-run) |

## Skills

Grouped by plugin. Each group links back to [Plugins](#plugins).

### cicero &nbsp;·&nbsp; [↑ Plugins](#plugins)
No skill — a **SessionStart** hook injects the house communication voice (bottom line first, concise,
plain language, recommend-don't-survey, push back, stay in scope), and a **Stop** hook enforces reply
language and concision. Configuration, not an invokable skill.

### diogenes &nbsp;·&nbsp; [↑ Plugins](#plugins)
- <a id="diogenes"></a>**diogenes** — Per-session token-spend report narrated by Diogenes the Cynic:
  session totals + cost, per-skill amortized cost, the heaviest tool-results and output turns. Use when
  you ask where tokens went, who's eating tokens, or what the session cost.

### lovecraft &nbsp;·&nbsp; [↑ Plugins](#plugins)
- <a id="lovecraft"></a>**lovecraft** — the Chronicler of the Unknown: house narrative voice for the
  engineering journal (xaaalera.github.io). Expedition-journal post-mortems — dated log entries, eroding
  composure, exact numbers, a survivor's protocol at the end.

### frontend-css &nbsp;·&nbsp; [↑ Plugins](#plugins)
- <a id="rem"></a>**rem** — Always size in `rem`, never `px`, so type and spacing scale with the user's
  root font size. Applies whenever CSS / SCSS / Tailwind is written or reviewed.
- <a id="scss-modules"></a>**scss-modules** — House conventions for SCSS modules: structure, the
  color/spacing/radius token system, BEM. Applies any time styles are created, modified, or refactored.

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
- <a id="error-handling"></a>**error-handling** — One error format everywhere: the `google.rpc.Status`
  envelope on every layer (Apex, BFF, client). Activate on any error path; create an error-code registry
  if the package has none.
- <a id="lean-writing"></a>**lean-writing** — Write specs, design docs, and summaries terse: short plain
  sentences, bullets over prose, no filler — caveman-simple but technically precise.
- <a id="model-routing"></a>**model-routing** — Assign an explicit model tier to every spawned agent /
  fan-out / eval before it launches; measure one unit and show the cost table before scaling.
- <a id="new-skill"></a>**new-skill** — How to author a new skill in the plugin model: naming, `SKILL.md`
  structure, and where it goes (`plugins/<domain>/skills/<name>/`).
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

## Eval gate (pre-push)

Every touched or new skill must ship a trigger eval. A pre-push hook
(`hooks/pre-push` → `scripts/eval-gate.sh`) blocks the push if a touched skill has no valid
`evals/trigger-eval.json` (JSON array of ≥6 `{query, should_trigger}` cases, ≥1 positive and ≥1
negative). It only *warns* — never blocks — when the eval exists but has not been measured or has gone
stale. Refresh a measurement with
`python3.14 scripts/optimize_description.py --skill-path <dir> --apply`.

**Install once per clone:** `bash install.sh` (sets `core.hooksPath` to `hooks/`). Untouched legacy
skills are never inspected; `git push --no-verify` skips the local hook.
