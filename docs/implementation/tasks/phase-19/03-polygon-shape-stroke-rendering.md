# Phase 19 Task 03: Polygon Shape Stroke Rendering

## Goal

Add stroke rendering for the polygon-backed built-in shapes:

- `RectShape`
- `TriangleShape`
- `DiamondShape`

## Spec Anchors

- `docs/spec/ui-foundation-spec.md` `RectShape`, `TriangleShape`, `DiamondShape`
- `docs/incidents/spec_patch_shape_border_and_opacity_surface.md`

## Scope

- stroke paint pass after fill
- line-quality and join handling for polygon shapes
- canonical dashed traversal for polygon perimeters

## Concrete Module Targets

- `lib/ui/shapes/rect_shape.lua`
- `lib/ui/shapes/triangle_shape.lua`
- `lib/ui/shapes/diamond_shape.lua`
- shared shape stroke helper module(s)

## Implementation Guidance

- keep fill rendering behavior intact
- use each shape's existing canonical local points as the stroke path source
- ensure dashed phase travels the whole perimeter cumulatively rather than
  restarting at each segment
- keep `strokeJoin` meaningful on polygon corners
- keep `strokeMiterLimit` active only when the join is `"miter"`

## Required Behavior

- stroke paints after fill
- no stroke paints unless `strokeColor` is present and `strokeWidth > 0`
- `strokeStyle` controls line quality independently from `strokePattern`
- `strokePattern = "solid"` yields continuous perimeter stroke
- `strokePattern = "dashed"` uses cumulative perimeter phase with
  `strokeDashOffset`
- `strokeJoin` affects polygon corners
- outward stroke extent does not affect `containsPoint`

## Non-Goals

- no `CircleShape` stroke yet
- no node-opacity generalization yet

## Acceptance Checks

- `RectShape`, `TriangleShape`, and `DiamondShape` render solid and dashed
  strokes with the expected canonical start point
- line style, line join, and miter limit are restored after drawing
- the same local geometry still governs containment
