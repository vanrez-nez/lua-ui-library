# Implementation Task: Foundation Anchor And Pivot Contract Alignment

## Summary

Bring `lib/ui` into compliance with the `Container` anchor/pivot contract
published in [docs/spec/ui-foundation-spec.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-foundation-spec.md).

The implementation must align to this public surface:

- `pivotX` / `pivotY` define the local transform origin for rotation, scaling,
  and skewing
- `anchorX` / `anchorY` define the parent-relative attachment and measurement
  basis
- `pivotX` and `pivotY` default to `0.5`
- `anchorX` and `anchorY` default to `0.0`

This is a non-phased spec-alignment task. Update the current `lib/ui`
implementation directly.

## Public Contract To Implement

Align the retained-node transform and placement path so omitted values and
explicit values both follow the published foundation contract.

Behavior:

- omitted `pivotX` resolves to `0.5`
- omitted `pivotY` resolves to `0.5`
- omitted `anchorX` resolves to `0.0`
- omitted `anchorY` resolves to `0.0`
- rotation is applied relative to the resolved pivot
- scaling is applied relative to the resolved pivot
- skewing is applied relative to the resolved pivot
- parent-relative attachment and measurement use the resolved anchor

## Implementation Changes

### Foundation Surface And Defaults

- Update the `Container` public-surface default resolution so omitted pivot
  values resolve to `0.5`.
- Keep omitted anchor values resolving to `0.0`.
- Ensure any schema, constructor, or extraction path that materializes defaults
  matches the spec exactly.

### Transform And Placement Semantics

- Verify and correct the transform pipeline so `pivotX` / `pivotY` are the
  actual origin for rotation, scaling, and skewing.
- Verify and correct the parent-relative placement path so `anchorX` /
  `anchorY` are the attachment and measurement basis against the parent region.
- Remove or correct any path where pivot is treated as parent-relative anchor
  or anchor is treated as local transform origin.

## Required File Changes

- `lib/ui/core/container_schema.lua`
  Update the public defaults for `pivotX` and `pivotY` from `0` to `0.5`. Keep
  `anchorX` and `anchorY` at `0.0`.
- `lib/ui/core/container.lua`
  Update every omitted-value fallback for `pivotX` / `pivotY` to `0.5` and keep
  every omitted-value fallback for `anchorX` / `anchorY` at `0.0`. This file is
  the authoritative runtime path for local transform resolution and isolated
  subtree compositing, so both pivot call sites in this file must comply.
- `lib/ui/layout/spacing.lua`
  Keep stack-layout anchor consumption aligned to the published anchor contract.
  This file is part of the parent-relative attachment path and must continue to
  resolve omitted anchors as `0.0`.
- `lib/ui/layout/safe_area_container.lua`
  Keep safe-area placement aligned to the published anchor contract. This file
  consumes parent-relative anchor offsets directly and must continue to resolve
  omitted anchors as `0.0`.
- `spec/shape_primitive_surface_spec.lua`
  Update the inherited default-pivot assertions from `0` to `0.5`.
- Any other spec or demo file that asserts or documents omitted pivot behavior
  as origin-based must be updated to the centered default.

## Acceptance Criteria

- A `Container` with omitted `pivotX` / `pivotY` behaves as if both are `0.5`.
- A `Container` with omitted `anchorX` / `anchorY` behaves as if both are `0.0`.
- Explicit `pivotX` / `pivotY` control the local origin for rotation, scaling,
  and skewing.
- Explicit `anchorX` / `anchorY` control parent-relative attachment and
  measurement.
- No retained-node path uses omitted pivot as `0`.
- Tests and demos reflect the published foundation contract.

## Suggested Verification

- Add or update focused specs for omitted versus explicit pivot values.
- Add or update focused specs for omitted versus explicit anchor values.
- Check one direct child and one nested child case for parent-relative
  attachment.
- Check one rotation case and one scaling case where centered pivoting is
  visually distinct from origin pivoting.
