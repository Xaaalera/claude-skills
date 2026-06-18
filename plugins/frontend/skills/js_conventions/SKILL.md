---
name: frontend-js_conventions
description: House JS/TS coding style and LWC-specific rules. Use whenever writing or editing JavaScript, TypeScript, Lightning Web Components (LWC), or Aura — applies to React/Node and Salesforce frontend code alike.
---

# JS / TS / LWC Conventions

House style for all JavaScript and TypeScript. Apply on every JS/TS/LWC edit.

## General JS / TS

- Prefer **arrow functions** wherever possible.
- Use **single quotes** for strings.
- Use **full, descriptive variable names** — no abbreviations
  (`errorMessage` not `errMsg`, `selectedRecord` not `selRec`).
- Always use braces `{}` for **all** control structures (`if`, `else`, `for`,
  `while`, ...), even for a single-line body.
- Write functions a stranger to the code can understand:
  - one function = one clear responsibility;
  - extract helper functions with descriptive names instead of long inline logic;
  - avoid clever one-liners when a readable multi-line form is clearer.

## LWC-specific (Lightning Web Components / Aura)

- Do **NOT** access the global DOM (`document`, `body`, etc.).
- Use `this.template` and the component APIs to query and manipulate the DOM.

> These LWC rules do not apply to React — in React use the framework's normal
> patterns (refs, state) rather than `this.template`.
