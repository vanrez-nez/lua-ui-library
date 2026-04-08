# Phase 19 Task 05: Node Opacity Generalization

## Goal

Generalize the retained render path so `Shape.opacity` and motion-driven
`opacity` render correctly without routing `Shape` through the `Drawable`
styling/effects system.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md` `Shape`
- `docs/spec/ui-foundation-spec.md` isolation rules
- `docs/incidents/spec_patch_shape_border_and_opacity_surface.md`

## Scope

- retained-node effect resolution for opacity
- isolation trigger path in `Container`
- shape participation in motion-driven root opacity

## Concrete Module Targets

- `lib/ui/core/container.lua`
- `lib/ui/core/shape.lua`

## Implementation Guidance

- treat this as a retained render-path change, not as a shape-local multiply
- widen opacity participation to render-capable nodes that document it
- keep `shader`, `mask`, and `blendMode` constrained to documented carriers
- preserve current `Drawable` behavior and existing motion surfaces

## Required Behavior

- `Shape.opacity` participates in the retained compositing path
- motion-owned root `opacity` values affect `Shape`
- `opacity = 0` keeps `Shape` in the tree and targetable
- fill alpha and stroke alpha both compose with node opacity
- shape opacity does not require the `Drawable` styling renderer

## Non-Goals

- no `shader`, `mask`, or `blendMode` support on `Shape`
- no change to shape hit testing or layout semantics

## Acceptance Checks

- a `Shape` with `opacity < 1` composites as a whole node rather than as
  unrelated per-primitive alpha changes
- motion-driven `opacity` updates the rendered result on `Shape`
- mixed trees of `Drawable` and `Shape` preserve current draw ordering and
  isolated-opacity correctness
