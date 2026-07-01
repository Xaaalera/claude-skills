---
description: When building or editing a React component that renders asynchronously-loaded data, decide whether it needs a loading skeleton — and if so, build a separate skeleton component colocated next to it from the shared Skeleton primitive. Activate whenever a component gains a loading state, shows a blank/"Loading…" gap, or you are reviewing async data UI.
---

# Skeleton Components — decide first, then colocate

A skeleton is not a default. It earns its place only when a component has a real
loading window. This skill gates that decision and, when a skeleton is warranted,
fixes how it is built: a **separate component next to the real one**, composed from
the shared `Skeleton` primitive — never a library, never hand-rolled pulse markup.

## When to Activate

- Creating or editing a React component that fetches its own data (TanStack Query,
  `await`, `isLoading`/`isPending`/`isFetching`).
- A component shows a blank area or a bare "Loading…" string before content paints.
- Reviewing async-data UI, or someone asks to "add a skeleton / loading state".

---

## Step 0 — Decide: does this component even need a skeleton?

**Default: no.** A skeleton is warranted ONLY when there is a real loading window —
the component renders data it fetches, and there is a visible gap before that data
arrives.

Quick test — is the first paint gated by an `isLoading` / `isPending` /
`isFetching` / `await`?

| Situation | Skeleton? |
|---|---|
| Component owns an async query and has a real pre-data gap | **Yes** — build one |
| Purely presentational; data comes in via props | **No** |
| Data resolves synchronously / is already cached | **No** |
| The parent already renders a skeleton for this whole region | **No** — don't double up |

No loading window → **stop here.** Do not create a skeleton for a component that
never waits. (OCKHAM: the cheapest skeleton is the one you didn't build.)

---

## Step 1 — Reuse the shared `Skeleton` primitive

Never add a skeleton **library**, and never hand-roll a pulsing `<div>` inline. Use
the project's shared `Skeleton` primitive (typically
`src/components/primitives/skeleton`) and compose several to mirror the shape of
what's loading. If the project has no `Skeleton` primitive yet, create it **once**
as a primitive (see `ui-primitive-reuse` / `component-placement`), then reuse it
everywhere — the shimmer is a CSS keyframe on a design-token background, not a
dependency.

## Step 2 — Build a SEPARATE skeleton component, colocated

Put the skeleton in the **same folder** as the component it stands in for, named
`<Component>Skeleton.tsx`. Export it from that module's `index.ts` barrel.

- It **mirrors the real component's layout** — same wrapper classes, same number
  and rough size of boxes — so the real content drops in without the page jumping.
- Do **not** inline skeleton markup in the page/consumer.
- Do **not** bake a loading branch inside the real component. Keep the skeleton a
  sibling that the consumer chooses to render.

```
components/kpi-grid/
  KpiGrid.tsx
  KpiGridSkeleton.tsx   ← colocated sibling, composed of <Skeleton/>
  index.ts              ← exports both
```

## Step 3 — Wire the loading branch at the consumer

Render the skeleton while loading, the real component once resolved. Expose
`isLoading` from the data hook if it isn't already available.

```tsx
{isLoading ? <ComponentSkeleton /> : <Component {...props} />}
```

---

## Checklist

- [ ] Confirmed a real async loading window exists — otherwise NO skeleton
- [ ] Reused the shared `Skeleton` primitive (no library, no hand-rolled pulse)
- [ ] Skeleton is a separate `<Component>Skeleton.tsx` in the same folder
- [ ] Mirrors the real component's shape/size so there's no layout jump
- [ ] Exported from the barrel and rendered in the consumer's loading branch
