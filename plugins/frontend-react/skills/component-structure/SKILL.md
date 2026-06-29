---
description: Use this skill any time a new React component is created or an existing component is edited or reviewed.
---

# Component Structure — BEM + SCSS + rem + i18n

## When to Activate

Any time a new React component is created, or an existing component is edited or its structure is reviewed.

---

## Step 0 — Activate supporting skills first

Before writing any component code or styles, activate both of these skills and apply their rules throughout:

1. **Activate `frontend-css:scss-modules` skill** — governs colors, spacing, file extension, variables
2. **Activate `frontend-css:rem` skill** — governs all dimensional values

Everything in this skill assumes those two are already in effect.

---

## Folder structure

**Every component — including sub-components — gets its own kebab-case folder** with its own `.tsx`, `.scss`, and `index.ts`. No exceptions.

```
component-name/
  ComponentName.tsx      ← React component (PascalCase file)
  component-name.scss    ← BEM styles for this component only
  index.ts               ← barrel export
```

Sub-components nest as sibling folders inside the parent folder:

```
sidebar/
  Sidebar.tsx
  sidebar.scss
  index.ts
  sidebar-nav-item/
    SidebarNavItem.tsx
    sidebar-nav-item.scss
    index.ts
  sidebar-sub-nav-item/
    SidebarSubNavItem.tsx
    sidebar-sub-nav-item.scss
    index.ts
```

The parent `index.ts` re-exports everything public from all sub-component folders:

```ts
// sidebar/index.ts
export { Sidebar } from './Sidebar';
export { SidebarNavItem } from './sidebar-nav-item';
export { SidebarSubNavItem } from './sidebar-sub-nav-item';
export type { NavItemData, NavSelectionEvent } from './Sidebar';
```

**No flat sub-components.** A component that has its own styles, state, or props is always a folder — never a bare `.tsx` file sitting alongside the parent.

---

## BEM naming

Block = component root class (matches the folder name).
Element = `block__element`.
Modifier = `block--modifier` or `block__element--modifier`.

```scss
.card-item {              // Block
  &__title  { ... }      // Element
  &__body   { ... }      // Element
  &--active { ... }      // Modifier
}
```

Rules:
- Block name matches the folder name (kebab-case)
- Never nest blocks inside each other's BEM — use a new block
- Modifiers only change what's different; don't repeat base styles inside a modifier
- State classes (`:hover`, `:focus`, `:disabled`) go inside the element or block rule via SCSS `&`

---

## SCSS file structure

```scss
@use '@/styles/variables' as *;

// 1. Optional component-level variables at the top
$item-height: 2.5rem;

// 2. Block
.block-name {
  // base styles

  // 3. Elements
  &__element { ... }

  // 4. Modifiers
  &--modifier {
    // overrides only
    .block-name__element { ... }
  }

  // 5. State
  &:hover { ... }
}
```

Follow `frontend-css:scss-modules` skill for: colors (`$color-*` / `var(--color-*)`),
spacing (`$space-*`, `$radius-*`), and file extension (`.scss` only).

Follow `frontend-css:rem` skill for: all dimensional values in rem except
border-width, box-shadow offsets, and SVG attributes.

---

## No inline hover handlers

Never use `onMouseEnter`/`onMouseLeave` to toggle styles in JS.
All hover/focus/active states must be CSS-only via `&:hover` etc.

```tsx
// Wrong
onMouseEnter={(e) => (e.currentTarget.style.background = '#eee')}

// Correct — handled in SCSS
&:hover { background: $color-surface-hover; }
```

---

## i18n — all user-visible strings must use translations

**Never hardcode user-visible text** in JSX or component logic. All strings go through `react-i18next`.

### Which namespace to use

| Component location | Namespace |
|---|---|
| `src/pages/<page-name>/` | `pages/<page-name>` |
| `src/lib/` or `src/components/` (shared) | `common` |

### Usage pattern

```tsx
import { useTranslation } from 'react-i18next';

export function MyComponent() {
  const { t } = useTranslation('pages/billing'); // or 'common'

  return <h1>{t('title')}</h1>;
}
```

### Adding new keys

When adding user-visible text to a component:

1. Add the key to the corresponding JSON file in `src/i18n/locales/en/`:
   - Page component → `src/i18n/locales/en/pages/<page-name>.json`
   - Shared component → `src/i18n/locales/en/common.json`
2. If creating a **new** page namespace: also register it in `src/i18n/index.ts`
3. Use nested keys to group related strings by component or section:

```json
{
  "header": {
    "title": "Billing",
    "description": "Invoices and billing management"
  },
  "table": {
    "emptyState": "No invoices found",
    "columns": {
      "date": "Date",
      "amount": "Amount"
    }
  }
}
```

### What counts as user-visible text

- Labels, titles, descriptions
- Button text
- Placeholder text
- `aria-label` attributes
- Error and empty-state messages
- Loading indicators
- Any string the user reads or hears

### What does NOT need translation

- Internal constants, enum values, CSS class names
- Log messages, developer-facing error messages
- Dynamic data coming from the API (names, amounts, dates)

---

## Barrel exports (index.ts)

Always export:
- The main component(s)
- All public TypeScript types/interfaces

```ts
export { FeatureBlock } from './FeatureBlock';
export { FeatureBlockItem } from './FeatureBlockItem';
export type { FeatureBlockItemData } from './FeatureBlockItem';
```

---

## Checklist — creating a new component

- [ ] Folder is kebab-case
- [ ] Component file is PascalCase `.tsx`
- [ ] Style file is kebab-case `.scss`
- [ ] `index.ts` barrel exports the component and its public types
- [ ] BEM: block matches folder name, elements use `&__`, modifiers use `&--`
- [ ] No inline `onMouseEnter`/`onMouseLeave` — hover states are in SCSS
- [ ] Colors from `$color-*` or `var(--color-*)` (see `frontend-css:scss-modules`)
- [ ] Spacing from `$space-*` / `$radius-*` (see `frontend-css:scss-modules`)
- [ ] All sizes in rem (see `frontend-css:rem`)
- [ ] All user-visible strings use `useTranslation` — no hardcoded text in JSX
- [ ] Translation keys added to the correct JSON file in `src/i18n/locales/en/`
- [ ] New page namespace registered in `src/i18n/index.ts` (if applicable)

## Checklist — editing an existing component

- [ ] Any new user-visible strings added via `useTranslation`, not hardcoded
- [ ] New translation keys added to the existing JSON namespace file
- [ ] No existing hardcoded strings left as-is if they were missed — fix them too
- [ ] BEM structure preserved: new elements follow `&__element` pattern
- [ ] No new inline hover handlers introduced
- [ ] No new hardcoded color or spacing values — use tokens