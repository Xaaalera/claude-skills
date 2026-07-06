# Xaaalera — personal Claude Code skills

My personal [Claude Code](https://claude.com/claude-code) skill library, published as a plugin
**marketplace**. Each domain is a plugin; skills live inside it and are pulled via the marketplace —
no copied folders, no duplication.

## Adopt the review gate in your repo

One command, from the root of the repo you want to protect (needs the GitHub CLI, `gh auth login`):

```bash
bash <(gh api repos/Xaaalera/claude-skills/contents/plugins/review/bootstrap.sh -H "Accept: application/vnd.github.raw")
```

It vendors the gate (`scripts/review/*`, `.husky/pre-push`, `.github/workflows/review-gate.yml`), seeds
`.claude/review.config.json`, and wires this marketplace + `review@xaaalera` into the repo's committed
`.claude/settings.json`. Then commit, `(cd scripts/review && npm i)` + `npm i -D husky && npx husky init`
to arm the local hook, and make **`review-gate`** a required status check in branch protection (the real
enforcer). Tailor `.claude/review.config.json` per the `review:setup` skill.

## Plugins at a glance

| Plugin | Skills |
|---|---|
| `cicero` | *(no skill — a SessionStart hook that injects the house voice)* |
| `diogenes` | `diogenes` |
| `frontend` | `fe-check` |
| `frontend-css` | `rem`, `scss-modules` |
| `frontend-js` | `conventions` |
| `frontend-react` | `component-placement`, `component-structure`, `feature-components`, `hooks-registry`, `layout-components`, `storybook-stories`, `ui-primitive-reuse` |
| `git` | `commit` |
| `i18n` | `ui-strings` |
| `jira` | `comment-style` |
| `lovecraft` | `lovecraft` |
| `meta` | `error-handling`, `lean-writing`, `model-routing`, `new-skill`, `ockham`, `solid`, `triage`, `wittgenstein` |
| `review` | `setup`, `/scavenge` command, `review-scavenger` agent |
| `salesforce` | `apex_test-authoring`, `dx_mcp`, `lwc_development`, `security_review-rules`, `sf-deploy-test`, `sf-run` |

Full per-skill descriptions are in [Skills](#skills) below.

## Model

`plugins/<domain>/` is hand-edited source. There is **no generator** — `plugins/`, this `README.md`,
and `.claude-plugin/marketplace.json` are all maintained by hand. A PostToolUse hook
(`~/.claude/settings.json`) just `git add -A && commit && push`es on any edit under `~/.claude/skills/`.

A skill is referenced as `<plugin>:<skill>` (e.g. `frontend-react:component-placement`,
`meta:ockham`). The `@xaaalera` suffix is only the install/enable key, never part of the invocation.
Enable/disable is per **plugin**, so domains are split fine-grained for independent control.

## Use

This repo lives at `~/.claude/skills/` and is wired into `~/.claude/settings.json`
(`extraKnownMarketplaces.xaaalera` + per-plugin `enabledPlugins`). To pull into another project, add to
its `.claude/settings.json` and run `/plugin`:

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

## Skills

### `cicero`
- *(no skill)* — a SessionStart hook that injects the house communication voice (bottom line first,
  concise, plain language, recommend-don't-survey, push back, stay in scope) plus a Stop hook that
  enforces reply language/concision. Configuration, not an invokable skill.

### `diogenes`
- **`diogenes:diogenes`** — Per-session token-spend report narrated by Diogenes the Cynic: session
  totals + cost, per-skill amortized cost, the heaviest tool-results and output turns. Use when you ask
  where tokens went, who's eating tokens, or what the session cost.

### `lovecraft`
- **`lovecraft:lovecraft`** — the Chronicler of the Unknown: house narrative voice for the
  engineering journal (xaaalera.github.io). Expedition-journal post-mortems — dated log entries,
  eroding composure, exact numbers, a survivor's protocol at the end.

### `frontend-css`
- **`frontend-css:rem`** — Always size in `rem`, never `px`. Applies whenever CSS / SCSS / Tailwind is
  written or reviewed, so type and spacing scale with the user's root font size.
- **`frontend-css:scss-modules`** — House conventions for SCSS modules (structure, scoping, naming).
  Applies any time styles are created, modified, or refactored.

### `frontend-js`
- **`frontend-js:conventions`** — House JS/TS style: arrow functions, single quotes, full variable
  names, braces on every control structure, small readable functions. Use whenever writing or editing
  any JavaScript/TypeScript (React, Node, anything).

### `frontend-react`
- **`frontend-react:component-placement`** — The entry point *before* creating any component: first
  search for an existing one, then decide where it belongs (primitive / feature / layout / page-local)
  and route to the matching skill below. Prevents duplicate and misplaced components.
- **`frontend-react:component-structure`** — How a single component file is laid out (props, hooks,
  handlers, render order). Apply when creating, editing, or reviewing a component.
- **`frontend-react:feature-components`** — Rules for *feature* components: domain-coupled blocks that
  compose primitives and hold business logic/data (a panel/table/editor tied to your domain).
- **`frontend-react:hooks-registry`** — Before writing a custom `use*` hook, check the hooks registry to
  reuse an existing one; update the registry whenever a hook is added/renamed/removed. Keeps hooks
  discoverable and non-duplicated.
- **`frontend-react:layout-components`** — Rules for app-chrome / layout: the shell, top bar, sidebar,
  command palette, and global overlays that frame every page.
- **`frontend-react:storybook-stories`** — After making a component, decide whether it also needs a
  Storybook story, and honor the project's recorded yes/no choice consistently.
- **`frontend-react:ui-primitive-reuse`** — Before hand-rolling any shared primitive (button, input,
  dialog, badge…), search the primitive library first and reuse/extend it; build new only when truly
  absent.

### `git`
- **`git:commit`** — Split all uncommitted changes into atomic, logical commits — one concern each,
  conventional-commit messages. Use whenever committing or pushing.

### `i18n`
- **`i18n:ui-strings`** — Route every user-facing string (labels, buttons, errors, toasts, empty states)
  through the project's localization system instead of hardcoding it. Applies any time display text is
  written or edited.

### `jira`
- **`jira:comment-style`** — Keep Jira ticket comments short and essence-first: bottom line up top,
  one-line bullets, understandable on the first read. Use before posting any ticket comment.

### `meta`
- **`meta:error-handling`** — One error format everywhere: the Google AIP-193 / `google.rpc.Status`
  envelope on every layer (Apex, BFF, client). Activate when adding an error path, throwing from a
  service/route/controller, mapping an upstream failure, or reading an error on the client. If the
  package has no error-code registry, create one.
- **`meta:lean-writing`** — Write specs, design docs, and brainstorm summaries terse: short plain
  sentences, bullets over prose, no filler — caveman-simple but technically precise.
- **`meta:model-routing`** — Assign an explicit model tier to every spawned agent / fan-out / eval before
  it launches (head for final judges, sonnet for judgment, haiku for mechanical sweeps); measure one unit
  and show the cost table before scaling. Use whenever planning multi-agent or eval work.
- **`meta:new-skill`** — How to author a new skill in the plugin model: naming, `SKILL.md` structure,
  and where it goes (`plugins/<domain>/skills/<name>/`).
- **`meta:ockham`** — The Razor. Invoke *before* creating any new entity (file, module, abstraction,
  config key…) to challenge whether it should exist at all — kill needless complexity early.
- **`meta:solid`** — The design law for code (SRP/OCP/LSP/ISP/DIP + DRY/KISS/YAGNI). Activate at design
  time and when writing/reviewing code — especially when deciding whether to split a class/function or
  how one module should depend on another. Pairs with `meta:ockham`.
- **`meta:triage`** — shallow first, deep only where it hurts: before any expensive exhaustive operation
  (fleet evals, big-diff review, migrations, repo sweeps), run a cheap full-coverage sorting pass, then
  spend the deep pass on the shortlist only.
- **`meta:wittgenstein`** — Clarity gate for specs and plans: audit each section so a non-technical
  reader grasps its point and nothing is a bloated wall of text, then fix it in place.

### `review`
- **`review:setup`** — Install and target the stack-agnostic pre-push review framework in a repo:
  5 reviewer agents (security, architecture, conventions, tests, docs), the `/review` orchestrator, and
  a secret-scan + attestation git/CI gate, all driven by a per-project `.claude/review.config.json`.
- **`review-scavenger` agent** — Cruft & Reuse reviewer (threshold 8/10). Blocks when a diff introduces
  duplicate files/hooks/services/utils or raw re-implementations of existing transports. Whole-repo aware
  but gates only on the diff. Pre-existing cruft → Advisory only, never a blocker. Supports a `persona`
  toggle (`twitch` / `plain`) for voice; verdict and scores are identical either way.
- **`/scavenge` command** — On-demand full-app hunt (not pre-push). Sweeps `src/` and `server/` for dead
  files, unused exports, unused dependencies, duplicated logic, and consolidatable services. Appends a
  deduped `🐀 Scavenger` section to `docs/superpowers/BACKLOG.md`; re-running never duplicates bullets.
  Prints an atmospheric Twitch report (ASCII rat + plague-rat narration) when `persona: twitch`, or a
  plain table when `persona: plain`.

### `salesforce`
- **`salesforce:apex_test-authoring`** — Author and maintain Apex unit tests to a strict house standard:
  per-object fluent-builder factories, `@TestSetup`, `Assert.*`, FLS/user-mode, and bulk + positive +
  negative coverage. Every new Apex class gets a matching test class in the same change.
- **`salesforce:dx_mcp`** — Prefer the salesforce-dx MCP tools over the raw `sf` CLI for any org
  interaction — SOQL/Tooling queries, running Apex tests, deploying or retrieving metadata.
- **`salesforce:lwc_development`** — House rules for building Lightning Web Components / Aura: the
  `.js` controller, `.html` template, `.js-meta.xml`, DOM access, and styling conventions.
- **`salesforce:security_review-rules`** — Security review checklist: secret leakage, BFF route auth,
  the client token boundary, injection, and the Salesforce AppExchange Security Review bar for Apex.

## Adding a skill

See `meta:new-skill`. New skill in an existing plugin: just add `plugins/<domain>/skills/<name>/SKILL.md`.
New domain: also add `plugins/<domain>/.claude-plugin/plugin.json`, a row above, an entry in
`.claude-plugin/marketplace.json`, and enable `<domain>@xaaalera` in `~/.claude/settings.json`.

> Local-only infra (hook + statusline scripts) lives in `claude-config/`, which is gitignored — it is
> not part of the published marketplace.

- **`meta:triage`** — shallow first, deep only where it hurts: before any expensive exhaustive
  operation (fleet evals, big-diff review, migrations, repo sweeps), run a cheap full-coverage
  sorting pass, then spend the deep pass on the shortlist only.

## Eval gate (pre-push)

Every touched or new skill must ship a trigger eval. A pre-push hook
(`hooks/pre-push` → `scripts/eval-gate.sh`) blocks the push if a touched skill has
no valid `evals/trigger-eval.json` (JSON array of ≥6 `{query, should_trigger}`
cases, ≥1 positive and ≥1 negative). It only *warns* — never blocks — when the
eval exists but has not been measured or has gone stale (no fresh
`evals/result.json`). Refresh a measurement by running the optimizer **from the
`claude-skills` repo** (that repo owns the runner), pointing it at this skill's
path: `python3.14 scripts/optimize_description.py --skill-path <dir> --apply`, which
writes `evals/result.json`.

**Install once per clone:** `bash install.sh` (sets `core.hooksPath` to `hooks/`).
Untouched legacy skills are never inspected; `git push --no-verify` skips the local hook.
