---
description: Apply Occam's razor when creating ANY new file, component, folder, hook, util, abstraction, prop, layer, or top-level category — do not multiply entities beyond necessity. Activate before adding structure of any kind.
---

# OCKHAM — Minimize Entities

> *Entia non sunt multiplicanda praeter necessitatem.*
> Entities must not be multiplied beyond necessity.

The cheapest file is the one you never create. Before adding **any** new
entity — a file, folder, component, sub-component, hook, util, prop, variant,
wrapper, abstraction layer, or top-level category — prove it must exist.

## When to Activate

Activate the moment you are about to **add structure**:

- Creating a new file, component, or sub-component
- Creating a new folder or top-level category under `components/`, `lib/`, etc.
- Adding a new prop, variant, generic, config option, or layer of indirection
- Wrapping something native (`<span>`, `<button>`, `<input>`) in a custom component
- Introducing a new abstraction "for the future" / "to be safe" / "in case we need it"
- Splitting one thing into many, or grouping many things under a new umbrella

If you are only editing existing entities, this skill is lighter — but still
ask whether the edit could remove an entity instead of adding one.

---

## The Razor — apply in order

### 1. Default to NO new entity
Ask first: **can an existing file/component/folder host this?** If yes, put it
there. A new entity is justified only when an existing one cannot reasonably
absorb the change.

### 2. Reuse → extend → only then create
- **Reuse** what exists (see `frontend-react_ui-primitive-reuse`).
- **Extend** the existing thing (add a `variant`/prop/case) before forking a copy.
- **Create new** only when reuse and extension both genuinely fail.

### 3. No speculative abstraction (YAGNI)
Do not add props, layers, wrappers, or generality for hypothetical futures.
Build for the cases that exist **today**. Three real call-sites justify an
abstraction; one imagined one does not. Remove a layer that no longer earns
its keep.

### 4. Prefer native over wrappers
If a wrapper adds no behavior, accessibility, or styling value over the native
element, use the native element. Wrap (e.g. a `@base-ui/react` primitive) only
when it buys real value — focus management, ARIA, portals, keyboard handling.
A wrapper that just forwards props is an entity that should not exist.

### 5. Few top-level themes; nest the details
Top-level categories are the most expensive entities — keep them few and broad.
A new thing belongs **inside** an existing theme unless it is a genuinely new
top-level concern. Prefer `theme/detail/` over a flat sprawl of sibling folders.

### 6. Delete dead code, don't preserve it "just in case"
Unused exports, deprecated duplicates, and empty folders are entities with
negative value. Remove them — git history is the safety net.

---

## When a split / new entity IS justified

Adding an entity is correct when at least one holds — and you can name which:

- **Real duplication:** the same logic exists in 3+ places.
- **Divergent change reasons:** two concerns change for different reasons / at
  different times (single-responsibility).
- **Cognitive load / size:** one unit has grown too large to read at a glance.
- **A hard rule requires it:** e.g. `frontend-react_component-structure` mandates
  a kebab folder + `.tsx` + `.scss` + `index.ts` for any component with its own
  styles/state. That is the *minimum* unit — meet it, but do not over-split a
  component into premature micro sub-components below that bar.

If you cannot name the trigger, do not create the entity.

---

## Checklist — before creating any entity

- [ ] Confirmed no existing file/component/folder can reasonably host this
- [ ] Reuse and extension both genuinely fail (not just "cleaner to add new")
- [ ] No speculative props/layers/wrappers added for hypothetical futures
- [ ] Native element used unless a wrapper buys real (a11y/behavior/styling) value
- [ ] New thing nested under an existing theme, not a new top-level category
- [ ] Any dead/duplicate/empty entity nearby removed in the same change
- [ ] If splitting/adding: named the concrete trigger (duplication / divergence / size / hard rule)