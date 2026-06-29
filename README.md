# Xaaalera — personal Claude Code skills

My personal [Claude Code](https://claude.com/claude-code) skill library, published as a plugin
**marketplace**. Each domain is a plugin; skills live inside it and are pulled via the marketplace —
no copied folders, no duplication.

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

## Plugins

| Plugin | Skills |
|---|---|
| `diogenes` | `diogenes` — per-session token-spend report |
| `frontend-css` | `rem`, `scss-modules` |
| `frontend-js` | `conventions` — JS/TS house style |
| `frontend-react` | `component-placement`, `component-structure`, `feature-components`, `hooks-registry`, `layout-components`, `storybook-stories`, `ui-primitive-reuse` |
| `git` | `commit` — atomic commit splitting |
| `i18n` | `ui-strings` — route UI text through localization |
| `jira` | `comment-style` — short, essence-first ticket comments |
| `meta` | `lean-writing`, `new-skill`, `ockham`, `wittgenstein` |
| `review` | `setup` — install the pre-push review framework (5 agents + `/review` + gate) |
| `salesforce` | `apex_test-authoring`, `dx_mcp`, `lwc_development`, `security_review-rules` |

## Adding a skill

See `meta:new-skill`. New skill in an existing plugin: just add `plugins/<domain>/skills/<name>/SKILL.md`.
New domain: also add `plugins/<domain>/.claude-plugin/plugin.json`, a row above, an entry in
`.claude-plugin/marketplace.json`, and enable `<domain>@xaaalera` in `~/.claude/settings.json`.

> Local-only infra (hook + statusline scripts) lives in `claude-config/`, which is gitignored — it is
> not part of the published marketplace.
