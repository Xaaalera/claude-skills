---
name: frontend-js_conventions
description: House JavaScript/TypeScript coding style — arrow functions, single quotes, full variable names, braces on all control structures, small readable functions. Use whenever writing or editing JavaScript or TypeScript (React, Node, or any JS/TS).
---

# JS / TS Conventions

House style for all JavaScript and TypeScript. Apply on every JS/TS edit.

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

For Salesforce LWC / Aura-specific rules (DOM access, styling) see
`salesforce-lwc_development`.
