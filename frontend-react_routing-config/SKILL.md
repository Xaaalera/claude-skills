---
description: Use when adding a new route, adding a nav item to the sidebar, or modifying routing/navigation in the Accounting Seed UI project.
---

# Routing & Navigation Config

## When to Activate

- User asks to add a new page or route
- User asks to add a nav item to the sidebar
- User asks to modify sidebar navigation
- Any change to `src/app/routes.tsx` or `src/config/`

---

## Single source of truth

All routing and navigation is driven by two config locations:

```
src/config/
  router/
    AppRoute.ts        ← enum: route name = URL path (e.g. BILLING = '/billing')
    AppRouteObject.ts  ← type: restricts RouteObject path to AppRoute values
    index.ts
  navigation/
    sidebar/
      types.ts         ← SidebarNavItem, SidebarNavSection
      top-items.ts     ← home, workspace, reports
      bottom-items.ts  ← settings, approvals, audit-trail
      accounting.ts    ← accounting section items
      receivables.ts   ← receivables section items
      payables.ts      ← payables section items
      treasury.ts      ← treasury section items
      inventory.ts     ← inventory section items (ERP-only)
      close-management.ts
      index.ts         ← assembles sections[]
    index.ts
```

---

## Adding a new route

**Step 1 — Add to `AppRoute` enum:**
```ts
// src/config/router/AppRoute.ts
NEW_PAGE = '/new-page',
```

**Step 2 — Add to `src/app/routes.tsx`:**
```ts
{ path: AppRoute.NEW_PAGE, element: <NewPage /> }
// If ERP-only:
{ path: AppRoute.NEW_PAGE, loader: createGuardLoader(erpGuard), element: <NewPage /> }
```

**Step 3 — Add to sidebar nav config** (the correct section file):
```ts
// e.g. src/config/navigation/sidebar/accounting.ts
{ route: AppRoute.NEW_PAGE, labelKey: 'items.newPage', icon: 'icon-name', objectApiName: null }
```

**Step 4 — Add i18n key** to `src/i18n/locales/en/navigation.json`:
```json
{ "items": { "newPage": "New Page Label" } }
```

---

## Rules

- `path` in `routes.tsx` must always be `AppRoute.*` — never a raw string
- Nav items use `route: AppRoute.*` — Sidebar reads the value as the URL
- ERP-only routes get `loader: createGuardLoader(erpGuard)` in routes AND `erpOnly: true` in nav config
- Never hardcode URL strings outside of `AppRoute.ts`