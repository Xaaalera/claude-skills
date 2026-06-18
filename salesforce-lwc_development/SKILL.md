---
name: salesforce-lwc_development
description: House rules for developing Salesforce Lightning Web Components (LWC) and Aura. Use whenever creating or editing an LWC/Aura bundle — a component .js controller, .html template, or .js-meta.xml — or any Salesforce-side frontend JS. Covers DOM access and styling conventions.
---

# Salesforce LWC Development

House standard for working with Lightning Web Components and Aura.

General JS/TS style applies here too (arrow functions, single quotes, full
variable names, braces for all control structures, small readable functions) —
see `frontend-js_conventions`. This skill adds the LWC-specific rules.

## DOM access

- Never touch the global DOM (`document`, `document.body`, global `window` DOM
  queries, etc.).
- Query and mutate the DOM only through `this.template`
  (e.g. `this.template.querySelector(...)`) and the component's own public APIs.

## Styling

- Do **not** use SCSS in LWC. Style through the component's own CSS file and use
  CSS custom properties (`var(--token)`) for shared values.
- Plain-web / React styling (SCSS, modules) lives in `frontend-css_scss-modules`.

## Related architecture

When the LWC work is part of the React ↔ Salesforce integration (Canvas
postMessage bridge, Aura container, BFF transport) or per-user UI config, the
org-specific architecture is documented in the project skills
`salesforce-data-router` and `salesforce-ui_config-architecture` — read those
before changing bridge or config code.
