# Phase 18 Task 06: Shape Centroid Pivot Alignment

## Goal

Bring the `Shape` implementation into alignment with the centroid-pivot patch
without changing the inherited `Container` pivot contract.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md`
  - `§6.1.1 Container`
  - `§6.1.3 Shape`
- `docs/incidents/spec_patch_shape_pivot_centroid_contract.md`

## Scope

- base `Shape` centroid helper methods
- one-time centroid-driven pivot assignment
- custom-shape centroid helper path
- focused regression coverage

## Concrete Module Targets

- update `lib/ui/core/shape.lua`
- update `spec/shape_primitive_surface_spec.lua`
- update `spec/nonrect_shape_spec.lua`
- add a focused centroid-pivot spec file only if the existing shape specs become
  unclear

## Implementation Guidance

- keep `pivotX` and `pivotY` normalized and bounds-relative
- do not change the inherited default `pivotX = 0.5` and `pivotY = 0.5`
- add `Shape:get_local_centroid()` as the centroid helper method
- `get_local_centroid()` returns the current centroid in local pixel space
- the base `Shape:get_local_centroid()` implementation returns the local bounds
  center
- add `Shape:set_centroid_pivot()` as the public one-shot pivot helper
- `set_centroid_pivot()` calls `get_local_centroid()`
- `set_centroid_pivot()` converts the returned local centroid to normalized
  pivot coefficients by dividing by the resolved width and height
- `set_centroid_pivot()` assigns the converted values to `pivotX` and `pivotY`
- treat zero-width or zero-height bounds as a no-op for centroid-pivot
  assignment
- keep the centroid helper independent from transform state; centroid is derived
  from canonical local geometry under resolved bounds
- all built-in shapes, including `TriangleShape`, should keep the inherited
  bounds-center default pivot behavior
- the centroid logic is an opt-in helper path, not a default pivot remapping
- if a future custom shape needs a geometry-derived centroid, that helper should
  be implemented from the shape's resolved local vertices or equivalent
  canonical geometry

## Required Behavior

- `Shape` exposes:
  - `get_local_centroid()`
  - `set_centroid_pivot()`
- `get_local_centroid()` returns the local centroid point used by the helper
- calling `set_centroid_pivot()` calls `get_local_centroid()` and assigns the
  returned point to `pivotX` and `pivotY` in normalized form
- later size changes do not reassign pivot automatically
- the default pivot contract remains unchanged for all shapes
- built-in shapes do not change draw or containment behavior as part of this
  task
- the base helper path is available for custom geometry-driven centroid
  calculation when explicitly needed

## Non-Goals

- no live centroid tracking
- no anchor changes
- no new shape families
- no arbitrary polygon centroid framework
- no triangle-specific default centroid behavior
- no styling, stroke, or clipping changes

## Acceptance Checks

- a base `Shape:get_local_centroid()` returns the local bounds center
- a base `Shape:set_centroid_pivot()` resolves to `pivotX = 0.5` and
  `pivotY = 0.5`
- `RectShape`, `CircleShape`, `DiamondShape`, and `TriangleShape` all keep
  bounds-center default pivot behavior
- calling the centroid-pivot helper on a zero-width or zero-height shape does
  not mutate `pivotX` or `pivotY`
- leaving `pivotX` and `pivotY` at defaults still means bounds-center rotation
  for every shape, including `TriangleShape`
- a custom shape can provide a geometry-derived centroid helper implementation
  without changing the default pivot semantics inherited from `Container`
