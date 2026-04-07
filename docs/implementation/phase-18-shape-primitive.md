# Phase 18: Shape Primitive

## Purpose

Introduce the first-class `Shape` foundation primitive and its initial concrete
shape families:

- `RectShape`
- `CircleShape`
- `TriangleShape`
- `DiamondShape`

This phase implements the new primitive boundary defined by the accepted shape
spec patch. It is not a `Drawable` extension, not a graphics-object feature,
and not a styling-system retrofit.

## Authority

- `docs/spec/ui-foundation-spec.md`
- `docs/incidents/spec_patch_drawable_shape_surface.md`

This document is sequencing and scoping context only.

## Scope

This phase covers:

- the base `Shape` primitive
- `Shape` public fill props
- shape-local containment hooks
- Stage-path hit testing through the existing targeting vocabulary
- the four approved concrete shapes
- focused acceptance coverage and demo/doc sync

This phase does not introduce:

- `Shape` as a subtype of `Drawable`
- `Drawable` styling families on shapes
- stroke or border semantics
- shape-aware clipping or non-rect layout footprints
- arbitrary polygons or additional preset shapes
- consumer child composition inside `Shape`

## Target Contract

The implementation must follow these settled boundaries:

- `Shape` extends `Container`, not `Drawable`
- `Shape` is render-capable and retained-tree interactive
- the v1 public surface is fill-only:
  - `fillColor`
  - `fillOpacity`
- Stage targeting continues to use:
  - `containsPoint(x, y)`
  - `_is_effectively_targetable`
  - `_hit_test_resolved`
- `Shape` converts world-space points to local space first, then evaluates local
  geometry through `_contains_local_point(local_x, local_y)`
- `RectShape` uses the base rectangular fallback
- `CircleShape`, `TriangleShape`, and `DiamondShape` each define their own
  canonical local geometry
- layout footprint remains rectangular
- `clipChildren` remains rectangular and bounds-based
- `Shape` is leaf-only in this revision

## File Plan

### 1. Base Primitive Surface

Preferred new modules:

- `lib/ui/core/shape.lua`
- `lib/ui/core/shape_schema.lua`

Required outcomes:

- `Shape` inherits from `Container`
- public validation surface is limited to the approved fill props
- `Drawable`-specific props do not appear on `Shape`
- leaf-only composition is enforced at the primitive boundary

### 2. Concrete Shape Classes

Preferred new modules:

- `lib/ui/shapes/rect_shape.lua`
- `lib/ui/shapes/circle_shape.lua`
- `lib/ui/shapes/triangle_shape.lua`
- `lib/ui/shapes/diamond_shape.lua`

Required outcomes:

- one class per concrete shape
- one clear local-geometry rule per class
- rendering and hit testing use the same canonical silhouette

### 3. Draw Integration

Primary code areas to review:

- `lib/ui/core/container.lua`
- `lib/ui/scene/stage.lua`
- any existing draw callback or primitive draw hook path

Required outcomes:

- `Shape` participates in ordinary retained drawing
- fill rendering does not require `Drawable` styling/effect plumbing
- zero-area and fully transparent fill cases remain valid

### 4. Targeting Integration

Primary code areas to review:

- `lib/ui/core/container.lua`
- `lib/ui/scene/stage.lua`
- any control logic that already depends on `containsPoint`

Required outcomes:

- no parallel shape-specific hit-test API is introduced
- transformed shapes target correctly through the current Stage path
- mixed trees of `Container`, `Drawable`, and `Shape` preserve normal z-order
  targeting

### 5. Acceptance And Docs

Review and update:

- focused runtime/spec coverage under `spec/`
- demo coverage for the new shapes
- stale implementation planning docs if any still assume shape belongs on
  `Drawable`

## Recommended Execution Order

1. establish the `Shape` primitive shell and schema boundary
2. implement `RectShape` and the simplest fill render path
3. wire transformed containment into the existing Stage targeting path
4. add the non-rect concrete shape classes
5. finish with focused acceptance coverage and doc/demo sync

## Verification

Minimum verification after implementation:

- `Shape` exposes only the approved fill surface
- `RectShape` renders and hit-tests against the same rectangle
- transformed `Shape` instances target correctly
- `CircleShape` uses an inscribed ellipse for non-square bounds
- `TriangleShape` uses the upright isosceles canonical vertices
- `DiamondShape` uses the midpoint-based canonical vertices
- `clipChildren` on `Shape` stays rectangular
- child composition on `Shape` fails deterministically

