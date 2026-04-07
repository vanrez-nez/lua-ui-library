# Phase 18 Task 03: Containment And Stage Targeting

## Goal

Integrate `Shape` into the existing retained-tree targeting path by making
containment transform-aware and shape-local without inventing a second hit-test
API.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md` `Shape` containment contract
- `docs/incidents/spec_patch_drawable_shape_surface.md` sections:
  - `Interaction Contract`
  - `Containment Model`
  - `Transform Rule`

## Scope

- `Shape:containsPoint(x, y)`
- `_contains_local_point(local_x, local_y)`
- Stage-path targeting compatibility
- transformed hit testing for `RectShape`

## Concrete Module Targets

- `lib/ui/core/shape.lua`
- `lib/ui/core/container.lua`
- `lib/ui/scene/stage.lua`

## Implementation Guidance

- preserve `containsPoint(x, y)` as the public entry point
- world-space point handling should live at the base `Shape` level
- concrete geometry checks should stay local-space through
  `_contains_local_point`
- keep Stage targeting logic on the existing method vocabulary:
  - `containsPoint`
  - `_is_effectively_targetable`
  - `_hit_test_resolved`
- do not add a shape-only targeting branch in Stage

## Required Behavior

- `Shape:containsPoint(x, y)` accepts world-space coordinates
- the point is inverse-transformed into local shape space before geometry
  testing
- the base `Shape` local containment rule is rectangular against local bounds
- transformed `RectShape` nodes target correctly through the current Stage path

## Non-Goals

- no `CircleShape`, `TriangleShape`, or `DiamondShape` geometry yet
- no renderer-side optimization work

## Acceptance Checks

- rotation, scale, skew, and pivot-driven transforms affect `RectShape`
  targeting correctly
- mixed sibling trees containing `Container`, `Drawable`, and `RectShape`
  preserve normal topmost-hit behavior
- Stage does not learn a second shape-specific containment API

