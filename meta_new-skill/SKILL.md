---
description: Use this skill when creating a new skill file. Ensures consistent naming, structure, and placement. For iterative creation with evals and testing, use the skill-creator plugin instead.
---

# Create a New Skill

## Naming convention

Format: **`{domain}-{subcategory}_{skill-name}`**

- `-` separates words within a block, and separates domain from subcategory
- `_` separates the category block from the skill name
- When there is no subcategory: **`{domain}_{skill-name}`**

### Domain + subcategory reference

| Domain | Subcategory | Example skill names |
|---|---|---|
| `frontend` | `css` | `frontend-css_rem`, `frontend-css_scss-modules` |
| `frontend` | `react` | `frontend-react_component-structure`, `frontend-react_hooks` |
| `frontend` | `a11y` | `frontend-a11y_aria-patterns` |
| `backend` | `auth` | `backend-auth_oauth-flow` |
| `backend` | `api` | `backend-api_bff-patterns` |
| `git` | *(none)* | `git_commit`, `git_sync-docs` |
| `media` | *(none)* | `media_dub`, `media_video-editing` |
| `meta` | *(none)* | `meta_new-skill`, `meta_sync-docs` |
| `ai` | *(none)* | `ai_claude-api`, `ai_prompting` |

**Never use vague short names** like `commit`, `css`, `dub`.

---

## Placement

| Scope | Location |
|---|---|
| Applies to all projects | `~/.claude/skills/<name>/SKILL.md` |
| Applies to this repo only | `.claude/skills/<name>/SKILL.md` |

When a skill is project-specific, also copy it to the global location if it will be reused.

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

1. Decide: global (`~/.claude/skills/`) or project-local (`.claude/skills/`)?
2. Pick a name using the convention above
3. Create the directory and write `SKILL.md` using the structure above
4. Make the `description:` frontmatter specific enough that Claude activates it only when truly relevant
5. If global — no commit needed. If project-local — commit with `chore: add <name> skill`
