---
description: Use this skill when creating a new skill file. Ensures consistent naming, structure, and placement in the plugin/marketplace model. For iterative creation with evals and testing, use the skill-creator plugin instead.
---

# Create a New Skill

Skills live in a **marketplace plugin**, never as loose flat folders. A skill belongs to a domain
(the plugin); the domain is the folder, not a prefix on the skill name.

## Placement

```
plugins/<domain>/skills/<skill-name>/SKILL.md
plugins/<domain>/.claude-plugin/plugin.json      # one per domain
```

| Scope | Location |
|---|---|
| Personal, reusable everywhere | `~/.claude/skills/plugins/<domain>/skills/<name>/` (the `xaaalera` marketplace) |
| One specific repo / shared with a team | that repo's own marketplace plugin, or `.claude/skills/<name>/` for a quick repo-local skill |

There are **no** flat `~/.claude/skills/<name>/` skills anymore, and nothing is "copied to a global
location" — a skill exists once, in its plugin, and is pulled via the marketplace.

## Naming convention

The skill **folder name** is just `<skill-name>` — the domain is already the plugin folder. Use an
optional subcategory prefix inside the name when a domain needs grouping.

Format: **`<subcategory>_<skill-name>`** (or plain **`<skill-name>`** when no subcategory).

In use, skills are **namespaced by domain**: `<domain>:<skill-name>`.

| Domain (plugin) | Skill folder | Used as |
|---|---|---|
| `frontend` | `css_rem`, `react_component-structure` | `frontend-css:rem`, `frontend-react:component-structure` |
| `git` | `commit` | `git:commit` |
| `meta` | `new-skill`, `ockham` | `meta:new-skill`, `meta:ockham` |
| `media` | `dub`, `video-editing` | `media:dub`, `media:video-editing` |

Within a domain the short name is fine (`commit`, `dub`) — the `<domain>:` namespace disambiguates, so
it never collides with a project's own skill.

---

## SKILL.md structure

```markdown
---
description: One sentence — used to decide when to activate this skill.
---

# Skill Title

## When to Activate

Describe the exact triggers: user phrases, file types, situations.

---

## Instructions

Step-by-step instructions for Claude to follow.
Use ## sections, code blocks, tables as needed.

---

## Checklist (optional)

- [ ] Item one
- [ ] Item two
```

---

## Steps

1. Pick the **domain** (existing plugin) the skill belongs to, and a `<name>` per the convention above.
2. Create `plugins/<domain>/skills/<name>/SKILL.md` using the structure above.
3. Make the `description:` frontmatter specific enough that Claude activates it only when truly relevant.
4. **New domain only:** also create `plugins/<domain>/.claude-plugin/plugin.json`
   (`{name, description, author:{name:"Xaaalera"}}`), add the domain to `.claude-plugin/marketplace.json`
   (hand-maintained), and enable `<domain>@xaaalera` in `~/.claude/settings.json → enabledPlugins`.
   Adding a skill to an existing domain needs no manifest change.
5. Editing anything under `~/.claude/skills/` auto-commits + pushes via the PostToolUse hook — no manual
   sync step.

---

## Improving an existing skill

Use the **`skill-creator` plugin** for iterative improvement with test cases, evals, benchmarks, and
description optimization. Invoke it via `/skill-creator` or let it trigger when you say "improve this
skill", "optimize skill description", or "run evals on this skill".
