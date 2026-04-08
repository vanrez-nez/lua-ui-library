# Phase 19 Task 00: Compliance Review

## Goal

Pin down the current implementation gap between the accepted shape stroke /
opacity contract and the code that already exists in `lib/ui`.

## Scope

Primary code areas:

- `lib/ui/core/shape.lua`
- `lib/ui/core/shape_schema.lua`
- `lib/ui/shapes/draw_helpers.lua`
- `lib/ui/shapes/rect_shape.lua`
- `lib/ui/shapes/circle_shape.lua`
- `lib/ui/shapes/triangle_shape.lua`
- `lib/ui/shapes/diamond_shape.lua`
- `lib/ui/core/container.lua`
- `lib/ui/render/styling.lua`

## Work

1. Confirm the current `Shape` public surface is still fill-only.
   Required check:
   - only `fillColor` and `fillOpacity` are in `shape_schema.lua`
   - `opacity` is not validated on `Shape`
   - no `stroke*` props are accepted yet
2. Confirm the current shape render path is concrete-class-local and fill-only.
   Required check:
   - `Shape:draw(...)` falls back to rectangle fill behavior
   - non-rect shapes each own their own polygon fill draw path
   - `draw_helpers.lua` contains no stroke-specific helpers yet
3. Confirm the current retained opacity path is still gated to `Drawable`.
   Required check:
   - `resolve_drawable_effects(...)`
   - `_ui_drawable_instance` guard
   - isolation trigger path in `Container`
4. Confirm what may be borrowed versus what must stay separate from the
   `Drawable` border renderer.
   Required check:
   - reusable line-state or dash math helpers, if any
   - rectangular assumptions in `Styling.paint_border(...)`
   - any `border*` naming or `SideQuad` assumptions that make direct reuse
     invalid for `Shape`
5. Record edge cases the later tasks must preserve.
   Required checklist:
   - zero-area shapes
   - fully transparent fill
   - transformed hit testing
   - `clipChildren` remains rectangular
   - mixed trees of `Drawable` and `Shape`

## Expected Findings

- `Shape` currently exposes only fill props
- concrete shapes already expose the canonical local geometry needed for stroke
- current opacity isolation is not reusable for `Shape` without widening the
  root-node effect resolution path
- the `Drawable` border renderer is a useful reference but not a drop-in shape
  stroke engine

## Exit Criteria

- the current `lib/ui` seams are identified precisely enough to execute the
  remaining Phase 19 tasks without re-scoping
