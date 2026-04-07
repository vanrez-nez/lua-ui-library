# Phase 18 Task 00: Compliance Review

## Goal

Establish the current implementation gap between `lib/ui` and the accepted
`Shape` primitive contract before adding runtime code.

## Scope

Primary code areas:

- `lib/ui/core/container.lua`
- `lib/ui/core/container_schema.lua`
- `lib/ui/core/drawable.lua`
- `lib/ui/core/drawable_schema.lua`
- `lib/ui/scene/stage.lua`
- `lib/ui/init.lua`

## Work

1. Confirm there is no existing first-class `Shape` primitive in `lib/ui`.
   Required check:
   - no `Shape` base class
   - no concrete shape subclasses
   - no export surface already reserved for shapes
2. Confirm the current draw entry points a new `Container`-derived renderable
   primitive can use without inheriting from `Drawable`.
   Required check:
   - parent/child draw traversal path
   - per-node draw callback path
   - current assumptions that special-case `Drawable`
3. Confirm the current Stage targeting path already depends on
   `containsPoint(x, y)` and can therefore absorb `Shape` without a parallel
   targeting vocabulary.
   Required check:
   - `containsPoint`
   - `_is_effectively_targetable`
   - `_hit_test_resolved`
4. Confirm where composition enforcement should live for a leaf-only primitive.
   Required check:
   - `addChild`
   - any attach/reparent helpers
   - failure style used by existing closed primitives
5. Confirm the current validation and export seams for adding a new primitive.
   Required check:
   - schema merge conventions
   - class construction conventions
   - root export surface in `lib/ui/init.lua`
6. Record any implementation-specific edge cases the next tasks must preserve.
   Required checklist:
   - zero-area bounds
   - `visible = false`
   - `interactive = false`
   - z-order targeting among mixed sibling families
   - rectangular clipping behavior inherited from `Container`

## Expected Findings

- no current `Shape`-family implementation exists
- `containsPoint(x, y)` is already the public targeting seam
- `Drawable` currently owns styling/effect behavior that must not become the
  default inheritance path for shapes
- a new primitive will need its own class, schema surface, export wiring, and
  closed-composition enforcement

## Exit Criteria

- the implementation seams are identified precisely enough to execute the
  remaining Phase 18 tasks without re-scoping

