---
description: Use this skill any time a new React component is created or an existing component's structure is reviewed.
---

# Component Structure — BEM + SCSS + rem

## When to Activate

Any time a new component is created or an existing component's structure is reviewed.

---

## Step 0 — Activate supporting skills first

Before writing any component code or styles, activate both of these skills and apply their rules throughout:

1. **Activate `frontend-css_scss-modules` skill** — governs colors, spacing, file extension, variables
2. **Activate `frontend-css_rem` skill** — governs all dimensional values

Everything in this skill assumes those two are already in effect.

---

## Folder structure

One component = one kebab-case folder containing:

```
component-name/
  ComponentName.tsx      ← React component (PascalCase file)
  component-name.scss    ← BEM styles for this component only
  index.ts               ← barrel export
```

Sub-components (items, rows, cards) live in the same folder:

```
feature-block/
  FeatureBlock.tsx
  FeatureBlockItem.tsx
  FeatureBlockHeader.tsx
  feature-block.scss
  index.ts
```

If a small helper component is shared between siblings, place it as a single
file directly in the parent `components/` directory without its own folder:

```
components/
  SharedIcon.tsx          ← shared, no folder needed
  feature-a/
  feature-b/
```

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

Follow `frontend-css_scss-modules` skill for: colors (`$color-*` / `var(--color-*)`),
spacing (`$space-*`, `$radius-*`), and file extension (`.scss` only).

Follow `frontend-css_rem` skill for: all dimensional values in rem except
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

## Checklist when creating a new component

- [ ] Folder is kebab-case
- [ ] Component file is PascalCase `.tsx`
- [ ] Style file is kebab-case `.scss`
- [ ] `index.ts` barrel exports the component and its public types
- [ ] BEM: block matches folder name, elements use `&__`, modifiers use `&--`
- [ ] No inline `onMouseEnter`/`onMouseLeave` — hover states are in SCSS
- [ ] Colors from `$color-*` or `var(--color-*)` (see `frontend-css_scss-modules`)
- [ ] Spacing from `$space-*` / `$radius-*` (see `frontend-css_scss-modules`)
- [ ] All sizes in rem (see `frontend-css_rem`)
