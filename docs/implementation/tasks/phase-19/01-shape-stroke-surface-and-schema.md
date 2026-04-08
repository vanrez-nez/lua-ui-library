# Phase 19 Task 01: Shape Stroke Surface And Schema

## Goal

Add the public `stroke*` and `opacity` surface to `Shape` without yet solving
the full renderer generalization work.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md` `Shape`
- `docs/spec/ui-styling-spec.md` `Shape-Owned Stroke Boundary`
- `docs/incidents/spec_patch_shape_border_and_opacity_surface.md`

## Scope

- `Shape` schema validation
- base `Shape` public read/write surface
- explicit rejection of non-shape styling families

## Concrete Module Targets

- `lib/ui/core/shape_schema.lua`
- `lib/ui/core/shape.lua`

## Implementation Guidance

- follow the current schema pattern already used by `Shape` and `Drawable`
- keep `strokeWidth` scalar-only
- keep `strokeStyle` and `strokePattern` distinct:
  - `strokeStyle = "smooth" | "rough"`
  - `strokePattern = "solid" | "dashed"`
- validate `opacity` with the same numeric domain as other node-opacity inputs
- reject `border*`, `background*`, `cornerRadius*`, and `shadow*` on `Shape`
  rather than silently ignoring them

## Required Behavior

- `Shape` accepts:
  - `strokeColor`
  - `strokeOpacity`
  - `strokeWidth`
  - `strokeStyle`
  - `strokeJoin`
  - `strokeMiterLimit`
  - `strokePattern`
  - `strokeDashLength`
  - `strokeGapLength`
  - `strokeDashOffset`
  - `opacity`
- defaults match the published spec
- `strokeWidth` rejects tables and other non-scalar inputs
- `strokeDashLength` is strictly positive
- `strokeGapLength` is non-negative
- `opacity` remains separate from `fillOpacity`

## Non-Goals

- no stroke rendering yet
- no generalized node-opacity runtime changes yet
- no acceptance/doc sync work yet

## Acceptance Checks

- constructing `Shape` with any approved `stroke*` prop succeeds
- invalid `strokeStyle` and `strokePattern` values fail deterministically
- non-scalar `strokeWidth` fails deterministically
- excluded `border*` or styling-family props fail deterministically
