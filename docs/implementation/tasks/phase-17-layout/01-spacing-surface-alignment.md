# Phase 17 Task 01: Spacing Surface Alignment

## Goal

Align the public spacing surface and effective-value reads with the layout spec
before changing parent layout behavior.

## Scope

Primary files:

- `lib/ui/core/drawable_schema.lua`
- `lib/ui/core/container.lua`
- `lib/ui/layout/layout_node.lua`
- `lib/ui/layout/layout_node_schema.lua`
- `lib/ui/core/drawable.lua`

## Work

1. Tighten `padding` validation to match the layout spec:
   - finite
   - non-negative
   Implementation detail:
   - stop validating layout `padding` through plain `Insets.normalize(...)`
   - route it through the shared side-quad path with non-negative member
     validation
2. Tighten layout-family `gap` validation to finite and non-negative.
   Implementation detail:
   - `gap` remains scalar
   - reject negative, `math.huge`, `-math.huge`, and `NaN`
3. Preserve `margin` as finite and signed where the layout spec allows it.
   Implementation detail:
   - do not clamp or normalize signed margins to non-negative values
   - keep margin storage in canonical expanded quad form
4. Ensure flat `padding*` reads on layout-family nodes resolve through the
   effective merged quad values rather than raw public values.
   Implementation detail:
   - make `LayoutNode` read spacing props the same way `Drawable` now does:
     through `Container._get_public_read_value(...)`
   - do not leave layout nodes as a special raw-read exception
5. Re-verify `Drawable.alignX` / `alignY` behavior against the layout spec’s
   internal content alignment contract.
   Implementation detail:
   - no new layout-parent behavior belongs here
   - this task should only confirm and, if needed, minimally correct the
     internal-content alignment path in `Drawable:resolveContentRect(...)`
6. Keep non-layout parents leaving child `margin` inert.
   Implementation detail:
   - no generic parent-side margin consumption helper should be added to
     `Container`
   - margin consumption must remain layout-family-local

## Concrete Changes

1. `lib/ui/layout/layout_node_schema.lua`
   - replace permissive scalar validation with finite/non-negative validation
     for `gap`
   - replace permissive `Insets.normalize(...)` validation for `padding` with
     shared side-quad normalization plus non-negative member checks
2. `lib/ui/layout/layout_node.lua`
   - change public reads from raw `_public_values` to the effective read helper
   - keep layout-node method lookup behavior unchanged
3. `lib/ui/core/drawable_schema.lua`
   - only change if needed to keep `margin` and `padding` validation behavior
     consistent across `Drawable` and layout-family surfaces
4. `lib/ui/core/container.lua`
   - reuse existing effective quad merge logic; do not fork it
5. `lib/ui/core/drawable.lua`
   - touch only if alignment verification exposes a real mismatch with
     `ui-layout-spec.md`

## Constraints

- Do not make non-layout parents margin-consuming.
- Do not duplicate quad merge logic locally in layout classes.
- Keep shared value-family normalization owned by the existing core helpers.
- Do not widen this task into parent layout placement changes.

## Acceptance Examples

- `Stack.new({ padding = -1 })` must fail deterministically.
- `Row.new({ gap = -1 })` must fail deterministically.
- `Row.new({ gap = 0/0 })` must fail deterministically.
- `Drawable.new({ marginLeft = -12 })` remains valid.
- `Stack.new({ padding = 10, paddingLeft = 3 }).paddingLeft` must read `3`.
- `Stack.new({ padding = 10, paddingLeft = 3 }).paddingTop` must read `10`.

## Exit Criteria

- `padding` and `margin` validation behavior matches the new layout spec.
- `gap` validation behavior matches the new layout spec.
- `Drawable` and layout-family nodes expose coherent effective spacing reads.
- Internal content alignment semantics remain correct and explicit.
