# Phase 17 Task 02: Layout Margin Consumption

## Goal

Implement the parent-side layout behavior required by the layout spec for child
`margin`.

## Scope

Primary files:

- `lib/ui/layout/stack.lua`
- `lib/ui/layout/sequential_layout.lua`
- `lib/ui/layout/flow.lua`
- `lib/ui/layout/safe_area_container.lua`

## Work

1. Implement child `margin` consumption for `Stack`:
   - margin-adjusted placement region per child
   - negative margins may expand the placement region beyond the stack content
     box
   - content-based measurement using child outer footprints
   Required implementation shape:
   - compute a per-child placement rect from `content_rect` and child margins
   - place the child border box inside that rect
   - keep the child `_resolved_width` / `_resolved_height` unchanged
   - keep the child `_layout_offset_x` / `_layout_offset_y` as the only changed
     placement values
2. Implement child `margin` consumption for `Row` and `Column` in the shared
   sequential layout path:
   - main-axis advancement by outer footprint
   - cross-axis extent using outer footprint
   - `gap` composed between margin boxes
   - negative-margin overlap preserved as valid
   Required implementation shape:
   - enrich each line entry with resolved margin members
   - derive `outer_main` and `outer_cross`
   - build lines using `outer_main`, not border-box size alone
   - resolve line cross extent using `outer_cross`
   - when placing a child, compute border-box position from:
     - line cursor
     - leading margin on the main axis
     - leading margin on the cross axis
   - keep `gap` added between adjacent margin boxes, not between border boxes
3. Implement child `margin` consumption for `Flow`:
   - wrapping decisions by outer footprint
   - row extents by outer footprint
   - row/row spacing with negative-margin overlap preserved as valid
   Required implementation shape:
   - enrich each flow entry with resolved margin members
   - wrap and row width calculations use outer width
   - row height calculations use outer height
   - child placement offsets add leading margins before placing the border box
   - row-to-row advancement uses row outer footprint plus `gap`
4. Implement child `margin` consumption for `SafeAreaContainer` with stack-like
   semantics:
   - safe area first
   - parent padding second
   - child margin consumption third
   Required implementation shape:
   - do not merge safe-area inset math with margin math
   - reuse the same stack-like per-child placement logic after the content rect
     is produced
   - content-sized measurement uses outer footprints relative to the safe-area
     content rect
5. Preserve the rule that invisible children contribute no layout space and no
   margin footprint.
6. Preserve the rule that margin affects layout footprint only, never a child’s
   own hit/clip/paint bounds.
7. Preserve the rule that clipping remains a separate concern:
   - negative-margin placement may extend beyond the nominal content region
   - `clipChildren` and ancestor clipping still decide visibility

## Constraints

- Do not broaden margin consumption beyond the layout-family parents defined by
  the layout spec.
- Do not silently change child local bounds or world bounds semantics to encode
  margin.
- Keep overlap legal when resolved distances become negative.
- Keep the existing visible-child filtering model unless a spec mismatch is
  found.

## Concrete Changes

1. Add shared local helpers for layout-side margin math.
   Preferred placement:
   - helper functions inside `sequential_layout.lua` for axis-aware outer
     footprint math
   - helper functions inside `stack.lua` / `safe_area_container.lua` for
     stack-like placement rect derivation
2. `lib/ui/layout/stack.lua`
   - replace `place_children(...)` with a path that derives one placement rect
     per child from `content_rect` plus child margins
   - replace content measurement with union of child outer footprints relative
     to the content origin
3. `lib/ui/layout/sequential_layout.lua`
   - extend `make_entry(...)` to cache resolved margins
   - update line-building, fill allocation inputs, line extents, and final
     placement to use outer footprints
   - do not change the documented fill-allocation non-commitment beyond what is
     needed to measure outer footprints correctly
4. `lib/ui/layout/flow.lua`
   - mirror the sequential-layout change set in its row-building and placement
     logic
5. `lib/ui/layout/safe_area_container.lua`
   - replace raw child placement-at-content-origin with stack-like margin-aware
     placement
   - replace content measurement with union of child outer footprints

## Placement Formula Requirements

Use these concrete rules:

- horizontal outer footprint:
  - `outer_width = marginLeft + border_width + marginRight`
- vertical outer footprint:
  - `outer_height = marginTop + border_height + marginBottom`
- sequential main-axis cursor advancement:
  - border box starts at `cursor + leading_margin`
  - after placement, advance cursor by:
    - border-box size
    - trailing margin
    - parent `gap`
    - next child leading margin is applied when placing the next child
- stack-like placement region:
  - placement rect origin:
    - `x = content_rect.x + marginLeft`
    - `y = content_rect.y + marginTop`
  - placement rect size:
    - `width = content_rect.width - marginLeft - marginRight`
    - `height = content_rect.height - marginTop - marginBottom`
  - negative margins may increase that size
  - do not clamp this rect to the content rect before normal clipping

## Acceptance Examples

- In `Row`, child A with `marginRight = 10` and child B with `marginLeft = 5`
  and `gap = 8` must end up with `23` units between border boxes.
- In `Row`, the same setup with `marginRight = -10`, `marginLeft = 5`, and
  `gap = 0` must produce `-5` units of resolved distance, meaning overlap.
- In `Stack`, `marginLeft = -20` must allow the child placement region to begin
  `20` units before the stack content-box left edge before clipping is applied.
- In `SafeAreaContainer`, child placement must resolve from:
  - safe-area-adjusted content rect
  - then parent padding
  - then child margin
- Invisible children must not affect measured content size in any layout
  family.

## Exit Criteria

- `Stack`, `Row`, `Column`, `Flow`, and `SafeAreaContainer` behave according to
  the layout spec’s margin-consumption model.
- Negative margins produce overlap without changing child hit/clip ownership.
- Content-sized layout parents measure from the correct outer footprints.
