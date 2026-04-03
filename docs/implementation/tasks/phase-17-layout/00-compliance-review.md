# Phase 17 Task 00: Compliance Review

## Goal

Establish the current implementation gap between `lib/ui` and
`docs/spec/ui-layout-spec.md` before editing runtime behavior.

## Scope

Primary code areas:

- `lib/ui/core/drawable.lua`
- `lib/ui/core/drawable_schema.lua`
- `lib/ui/core/container.lua`
- `lib/ui/layout/layout_node.lua`
- `lib/ui/layout/layout_node_schema.lua`
- `lib/ui/layout/stack.lua`
- `lib/ui/layout/sequential_layout.lua`
- `lib/ui/layout/flow.lua`
- `lib/ui/layout/safe_area_container.lua`

## Work

1. Confirm the current `Drawable` internal content alignment behavior against
   the layout spec.
   Required check:
   - `Drawable:resolveContentRect(...)` is the only internal-content alignment
     path and it uses `alignX` / `alignY` against the effective content box.
2. Confirm which spacing props currently resolve through effective merged values
   and which still read raw public values.
   Required check:
   - `Container` / `Drawable` reads use `_effective_values`
   - `LayoutNode` reads still bypass `_effective_values`
3. Confirm where `padding` is consumed in layout and self-measurement.
   Required check:
   - layout content rect generation
   - content-sized self measurement
   - safe-area content rect derivation
4. Confirm where child `margin` is currently ignored.
   Required check:
   - `Stack`
   - sequential layout (`Row` / `Column`)
   - `Flow`
   - `SafeAreaContainer`
5. Confirm how invisible children are excluded from layout participation today.
   Required check:
   - invisible children do not contribute measurement
   - invisible children still get a layout offset assignment path
6. Record any implementation-specific edge cases that the layout spec now makes
   normative.
   Required checklist:
   - negative margin overlap
   - `clipChildren` interaction
   - `content` sizing interaction
   - `wrap` interaction
   - safe-area plus padding composition order

## Expected Findings

- `LayoutNode.__index` returns raw `_public_values` and must be aligned with the
  effective merged quad read path.
- `layout_node_schema.lua` validates `gap` as plain number and `padding` through
  `Insets.normalize(...)`, which is too loose for the current layout spec.
- no current layout parent consumes child `margin`.
- invisible children are already excluded from layout measurement in the main
  layout paths.

## Exit Criteria

- The implementation gaps are identified precisely enough to execute the next
  two tasks without re-scoping.
