# Phase 18 Task 01: Shape Primitive Surface

## Goal

Create the base `Shape` primitive and its public validation/export surface
without yet implementing the harder non-rect geometry work.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md` `Shape`
- `docs/incidents/spec_patch_drawable_shape_surface.md` sections:
  - `Proposed Primitive`
  - `Public Surface`
  - `Leaf-Only Rule`

## Scope

- base `Shape` class
- `Shape` schema/public props
- root export wiring
- leaf-only composition enforcement

## Concrete Module Targets

- add `lib/ui/core/shape.lua`
- add `lib/ui/core/shape_schema.lua`
- update `lib/ui/init.lua`
- update any internal module index or loader surface needed to expose the new
  primitive

## Implementation Guidance

- implement `Shape` as a direct subclass of `Container`
- follow the existing class and schema conventions already used by
  `Container`, `Drawable`, and `Image`
- limit the public surface to:
  - `fillColor`
  - `fillOpacity`
- reuse existing color validation helpers where possible
- keep `Shape` outside the `Drawable` schema and outside the styling/effects
  pipeline
- enforce leaf-only behavior directly on the primitive boundary rather than
  relying on documentation alone

## Required Behavior

- `Shape` exists as a first-class retained primitive
- `Shape` accepts only the approved fill props in addition to inherited
  `Container` props
- `Shape` does not expose `Drawable` props such as padding, alignment, skin,
  shader, mask, blend mode, or styling families
- attaching child nodes to a `Shape` fails deterministically

## Non-Goals

- no concrete non-rect classes yet
- no Stage targeting changes yet
- no renderer-wide refactor

## Acceptance Checks

- the project exposes `Shape` publicly
- invalid `Shape` child composition fails deterministically
- `Shape` instances can exist in the retained tree without inheriting the
  `Drawable` public surface

