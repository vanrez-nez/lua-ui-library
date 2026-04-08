# Phase 19 Task 04: Circle Stroke And Dash Traversal

## Goal

Add `CircleShape` stroke rendering while preserving the spec rule that circle
stroke and fill share the same approximation family.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md` `CircleShape`
- `docs/incidents/spec_patch_shape_border_and_opacity_surface.md`

## Scope

- `CircleShape` stroke rendering
- top-center canonical traversal start
- dashed traversal over the same approximation path used by fill

## Concrete Module Targets

- `lib/ui/shapes/circle_shape.lua`
- shared shape stroke helper module(s)

## Implementation Guidance

- do not introduce a second geometry source for stroke
- keep the existing polygon approximation model for fill and stroke aligned
- reorder or regenerate the approximated point list as needed so dashed phase
  starts at the top-center contract point
- accept `strokeJoin` and `strokeMiterLimit` without giving them visible effect

## Required Behavior

- `CircleShape` stroke follows the inscribed ellipse approximation
- dashed phase starts at top-center and travels clockwise
- `strokeJoin` and `strokeMiterLimit` are accepted and inert
- fill and stroke remain geometrically coupled through the same approximation
  family

## Non-Goals

- no new circle approximation tuning surface
- no true arc-stepping stroke path
- no node-opacity generalization yet

## Acceptance Checks

- `CircleShape` can render solid and dashed strokes
- dashed offset advances phase along the canonical clockwise traversal
- `strokeJoin` on `CircleShape` does not fail and has no visual effect
