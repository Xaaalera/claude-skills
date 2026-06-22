---
description: After creating a React component, decide whether to also write a Storybook story. On the FIRST component in a project, explain Storybook to the user and ask if they want stories, record the yes/no choice in the project's CLAUDE.md, then honor that choice on every component afterwards.
---

# Storybook Stories — ask once per project, then follow the recorded choice

A story is the cheapest way for a human to see a component in isolation, but not
every project wants them. This skill makes that a deliberate, remembered, per-project
decision instead of a guess made fresh every time.

## When to Activate

Right after creating (or finishing) ANY new React component, in ANY project —
the moment you would otherwise just move on from a fresh `.tsx`. Pairs with
`frontend:react_component-placement`: its "catalog it" step routes here.

---

## Instructions

### Step 1 — Read the project's recorded preference

Look in the project's `CLAUDE.md` for a line recording the Storybook choice:

- **`Storybook stories: yes`** → go to **Step 3** (write the story).
- **`Storybook stories: no`** → STOP. Do not write a story. Say nothing further about it.
- **Not present** → this is the first time on this project → go to **Step 2**.

Do NOT re-ask if the line already exists — the whole point is to ask once.

### Step 2 — First time on this project: explain, ask, then record

First detect whether Storybook is even set up: a `storybook` dependency or script in
`package.json`, or a `.storybook/` directory.

Explain Storybook to the user in their own language, briefly — something like:

> Storybook is an isolated workbench for UI components. Each component renders on its
> own page (a "story") outside the app — no routing, auth, or backend needed. It's
> used to build, document, visually review, and test components in isolation, and it
> gives a browsable catalog so the next person finds an existing component instead of
> rebuilding it. Stories live next to the component as `<Component>.stories.tsx`.

Then ask plainly: **"Do you want me to create a Storybook story alongside each new
component in this project?"** (yes / no).

- If Storybook is **not** set up and they say yes, tell them it needs a one-time
  `npx storybook@latest init` and ask whether to set it up now.

Record their answer as a single, stable line in the project's `CLAUDE.md` so this skill
finds it next time — add or update:

```
Storybook stories: yes
```

(or `no`). Put it where the project keeps conventions/invariants; one line, exact
wording, so Step 1 can read it deterministically.

Then act on the answer (Step 3 if yes; otherwise stop).

### Step 3 — Write the story (only when the preference is "yes")

- If the repo exposes a Storybook MCP, call its `get-storybook-story-instructions`
  first and treat it as the source of truth for imports and patterns.
- **Colocate**: `<Component>.stories.tsx` next to the component.
- **Self-contained, abstract data.** A component is generic (prop-driven), so its
  stories must be too. NEVER import the app's runtime or domain mock-data into a story
  (that nails an abstract component to one concrete use). Define the sample data INSIDE
  the story file — or, if large/shared, a sibling `<Component>.mock.ts` — and name it
  after the component, e.g. `const <componentName>StorybookMock = …`. Make the values
  illustrative and neutral ("Metric — rising"), not domain-specific ("Revenue").
- Cover the **distinct states/variants** the component can reach (default, empty,
  error, loading, key prop/role variations) — not redundant duplicates. Use realistic
  or mock props.
- Match the project's existing story conventions (framework import path, test helpers,
  decorators) — don't introduce a new style.
- After writing, surface the **preview URL(s)** (Storybook MCP `preview-stories`, or the
  `iframe.html?id=…` URL) so the user can eyeball the result.

---

## Checklist

- [ ] Read `CLAUDE.md` for the recorded `Storybook stories:` preference
- [ ] If absent: explained Storybook, asked the user, recorded `yes`/`no` in `CLAUDE.md`
- [ ] If `yes`: wrote a colocated story covering the key states; surfaced the preview URL
- [ ] If `no`: skipped story creation silently
