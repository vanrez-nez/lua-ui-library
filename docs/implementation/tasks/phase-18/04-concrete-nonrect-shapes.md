# Phase 18 Task 04: Concrete Non-Rect Shapes

## Goal

Implement the remaining approved concrete shape classes and their canonical
local-space geometry for both drawing and containment.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md` entries for:
  - `CircleShape`
  - `TriangleShape`
  - `DiamondShape`
- `docs/incidents/spec_patch_drawable_shape_surface.md` sections:
  - `CircleShape`
  - `TriangleShape`
  - `DiamondShape`
  - `Acceptance Criteria`

## Scope

- `CircleShape`
- `TriangleShape`
- `DiamondShape`
- draw/containment alignment for each class

## Concrete Module Targets

- add `lib/ui/shapes/circle_shape.lua`
- add `lib/ui/shapes/triangle_shape.lua`
- add `lib/ui/shapes/diamond_shape.lua`
- add any small shared geometry helpers only if they reduce obvious duplication

## Implementation Guidance

- keep all geometry defined in local node space
- `CircleShape` means the ellipse inscribed in local bounds, not a guaranteed
  equal-radius circle under non-square bounds
- `TriangleShape` is the upright isosceles triangle with vertices:
  - top-center
  - bottom-right
  - bottom-left
- `DiamondShape` uses the four edge midpoints:
  - top-center
  - right-center
  - bottom-center
  - left-center
- ensure draw and hit behavior use the same canonical geometry

## Required Behavior

- each concrete shape renders the correct fill silhouette
- each concrete shape overrides `_contains_local_point` as needed
- transformed targeting continues to work through the base `Shape` containment
  path
- layout footprint remains rectangular even when the visible silhouette is not

## Non-Goals

- no extra preset shapes such as stars or hearts
- no arbitrary polygon API
- no stroke or border semantics

## Acceptance Checks

- `CircleShape` uses the inscribed ellipse under rectangular bounds
- `TriangleShape` points upward in local space unless the node is rotated
- `DiamondShape` follows the node aspect ratio through its midpoint geometry
- the drawn silhouette and the hit silhouette match for all three classes

