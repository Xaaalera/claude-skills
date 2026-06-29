---
description: Use this skill any time styles are written or modified — creating a new component, writing CSS/SCSS, or refactoring existing styles.
---

# CSS / SCSS — Modules, Colors, and Structure

## When to Activate

Any time styles are written or modified: creating a new component, writing CSS/SCSS,
refactoring existing styles.

---

## 0. SCSS over CSS — always propose SCSS

**If the project doesn't already use SCSS** and the user has their own bundler
(Vite, Webpack, Next.js, etc.) and is **not** in a Salesforce / LWC / Aura ecosystem:

→ **Propose switching to SCSS** before writing any styles.

Suggest this structure:

```
src/styles/
  variables/
    _colors.scss      ← $color-* brand + semantic tokens
    _typography.scss  ← $font-*, $text-*, $leading-*
    _spacing.scss     ← $space-* scale + $radius-*
    _effects.scss     ← $shadow-*, $duration-*, $ease-*, $z-*
    index.scss        ← @forward all of the above
  tokens/
    index.scss        ← :root { --var: #{$var}; } — CSS custom properties
  base/
    _reset.scss
  main.scss           ← SCSS entry: @use in order
```

**Why:** a global variables file eliminates hardcoded values across the codebase,
makes theming trivial, and gives you a single source of truth for every color,
spacing step, and radius.

**Bundler setup (Vite example):**
```ts
// vite.config.ts — no loadPaths needed when using path aliases
resolve: {
  alias: { '@': path.resolve(__dirname, './src') }
}
// Then in any .scss file:
// @use '@/styles/variables' as *;
```

If the user is in **Salesforce / LWC** — do not suggest SCSS. Use CSS custom properties (`var(--token)`) instead.

---

## 1. Always use .scss, never .css for component styles

```
# Correct
card.scss
user-profile.scss

# Wrong
card.css
user-profile.css
```

If an existing `.css` component file is being touched — rename it to `.scss` and update the import.

---

## 2. Colors — $variable in SCSS, var() in plain CSS

In SCSS files use `$color-*` variables directly.
In plain CSS or when `@use` is not available, use `var(--color-*)`.

```scss
// Wrong — hardcoded
.button { color: #003458; }

// Correct — SCSS variable
@use '@/styles/variables' as *;
.button { color: $color-primary; }

// Also correct — CSS custom property
.button { color: var(--color-primary); }
```

Never hardcode hex values. If a color is missing from variables — add it there first.

---

## 3. Spacing — use a scale, never magic numbers

Define a spacing scale in `_spacing.scss` (4px base step is standard):

```scss
$space-1:   0.25rem;   //  4px
$space-2:   0.5rem;    //  8px
$space-3:   0.75rem;   // 12px
$space-4:   1rem;      // 16px
$space-6:   1.5rem;    // 24px
$space-8:   2rem;      // 32px
// etc.

$radius-sm:   0.25rem;   //  4px
$radius-md:   0.5rem;    //  8px
$radius-lg:   0.75rem;   // 12px
$radius-full: 9999px;
```

Use these variables everywhere. Never write `padding: 12px` — write `padding: $space-3`.

---

## 4. Component SCSS structure (BEM)

One component = one `.scss` file.

```scss
@use '@/styles/variables' as *;

// Optional component-level vars
$avatar-size: 2.5rem;

.card {
  background: $color-surface;
  border-radius: $radius-lg;
  padding: $space-4 $space-6;

  &__title { color: $color-text-heading; }
  &__body  { color: $color-text; }

  &--highlighted {
    border: 1px solid $color-primary;
  }

  &:hover { background: $color-surface-hover; }
}
```

---

## Checklist when creating component styles

- [ ] Project uses SCSS (if not — propose it first)
- [ ] Global variables file exists before writing any values
- [ ] File extension is `.scss`, not `.css`
- [ ] No hardcoded hex colors — all from `$color-*`
- [ ] No magic numbers — spacing from `$space-*`, radius from `$radius-*`
- [ ] New tokens added to the correct `variables/_*.scss` file first
- [ ] All sizes in `rem` (except border-width, box-shadow offsets, SVG attributes)
- [ ] BEM structure: block → `&__element` → `&--modifier`
