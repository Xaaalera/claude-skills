# Xaaalera — personal Claude Code skills

My personal [Claude Code](https://claude.com/claude-code) skill library, published as a plugin
**marketplace**. Each domain is a plugin; skills live inside it and are pulled via the marketplace —
no copied folders, no duplication.

## Plugins at a glance

| Plugin | Skills |
|---|---|
| `diogenes` | `diogenes` |
| `frontend-css` | `rem`, `scss-modules` |
| `frontend-js` | `conventions` |
| `frontend-react` | `component-placement`, `component-structure`, `feature-components`, `hooks-registry`, `layout-components`, `storybook-stories`, `ui-primitive-reuse` |
| `git` | `commit` |
| `i18n` | `ui-strings` |
| `jira` | `comment-style` |
| `meta` | `lean-writing`, `new-skill`, `ockham`, `wittgenstein` |
| `review` | `setup` |
| `salesforce` | `apex_test-authoring`, `dx_mcp`, `lwc_development`, `security_review-rules` |

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

### `diogenes`
- **`diogenes:diogenes`** — Per-session token-spend report narrated by Diogenes the Cynic: session
  totals + cost, per-skill amortized cost, the heaviest tool-results and output turns. Use when you ask
  where tokens went, who's eating tokens, or what the session cost.

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
- **`meta:lean-writing`** — Write specs, design docs, and brainstorm summaries terse: short plain
  sentences, bullets over prose, no filler — caveman-simple but technically precise.
- **`meta:new-skill`** — How to author a new skill in the plugin model: naming, `SKILL.md` structure,
  and where it goes (`plugins/<domain>/skills/<name>/`).
- **`meta:ockham`** — The Razor. Invoke *before* creating any new entity (file, module, abstraction,
  config key…) to challenge whether it should exist at all — kill needless complexity early.
- **`meta:wittgenstein`** — Clarity gate for specs and plans: audit each section so a non-technical
  reader grasps its point and nothing is a bloated wall of text, then fix it in place.

### `review`
- **`review:setup`** — Install and target the stack-agnostic pre-push review framework in a repo:
  5 reviewer agents (security, architecture, conventions, tests, docs), the `/review` orchestrator, and
  a secret-scan + attestation git/CI gate, all driven by a per-project `.claude/review.config.json`.

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
