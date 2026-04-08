# Phase 19: Shape Stroke And Node Opacity

## Purpose

Extend the existing `Shape` primitive implementation with:

- shape-owned `stroke*` props
- shape stroke rendering for all built-in shapes
- whole-node `opacity` on `Shape`

This phase builds on the current `lib/ui` baseline where `Shape` already
exists as a `Container` subclass with fill rendering, concrete non-rect shape
classes, and silhouette-aware containment, but still lacks stroke support and
still depends on a `Drawable`-only isolation path for node opacity.

Current-surface note: this document records the phase-19 extension scope only.
The shipped `Shape` surface is broader after phase 20, which adds shared root
compositing props plus shape-owned gradient and texture fill sources. For the
current implementation-facing graphics surface, see
[`docs/implementation/phase-20-shape-graphics-capability-normalization.md`](./phase-20-shape-graphics-capability-normalization.md).

## Authority

- `docs/spec/ui-foundation-spec.md`
- `docs/spec/ui-styling-spec.md`
- `docs/incidents/spec_patch_shape_border_and_opacity_surface.md`

This document is sequencing and scoping context only.

## Current Implementation Baseline

Relevant current code in `lib/ui`:

- `lib/ui/core/shape.lua` provides fill-only draw behavior and leaf-only
  composition enforcement
- `lib/ui/core/shape_schema.lua` validates only `fillColor` and `fillOpacity`
- `lib/ui/shapes/rect_shape.lua`, `circle_shape.lua`, `triangle_shape.lua`,
  and `diamond_shape.lua` render fills and expose local geometry helpers
- `lib/ui/shapes/draw_helpers.lua` contains fill-color and point-transform
  helpers only
- `lib/ui/core/container.lua` applies isolated opacity, shader, mask, blend,
  and transform effects only when `_ui_drawable_instance == true`
- `lib/ui/render/styling.lua` owns `Drawable` border rendering and dashed-border
  helpers, but those helpers assume the `border*` contract and rectangular or
  rounded-rect styling geometry

Implication:

- this phase should not retrofit `Shape` into the `Drawable` styling pipeline
- this phase should not reuse `border*` prop names on `Shape`
- node-opacity work must generalize the current retained render path rather
  than introducing a shape-local alpha hack

## Scope

This phase covers:

- `Shape` public `stroke*` surface and `opacity`
- validation and rejection rules for the new shape-owned surface
- shared stroke rendering helpers for polygon and approximated-circle shapes
- canonical dashed-stroke traversal for all built-in shape classes
- generalized retained-node opacity support for `Shape`
- focused acceptance coverage for stroke and opacity behavior

This phase does not introduce:

- `Shape` as a subtype of `Drawable`
- `border*`, `background*`, `cornerRadius*`, or `shadow*` support on `Shape`
- per-side or per-segment stroke widths
- inside-only or outside-only stroke placement
- `shader`, `mask`, or `blendMode` on `Shape`
- new shape families beyond `RectShape`, `CircleShape`, `TriangleShape`, and
  `DiamondShape`

## Target Contract

The implementation must follow these settled boundaries:

- `Shape` remains parallel to `Drawable`
- `Shape.stroke*` is shape-owned and independent from the `border*` styling
  family
- `strokeStyle` means line quality:
  - `"smooth"`
  - `"rough"`
- `strokePattern` means segmentation:
  - `"solid"`
  - `"dashed"`
- `strokeWidth` is scalar-only and center-aligned on the silhouette
- stroke painting does not alter layout footprint
- stroke painting does not alter `containsPoint`
- dashed traversal uses canonical local perimeter order per concrete shape
- `Shape.opacity` is whole-node opacity, not fill-only opacity and not
  stroke-only opacity
- motion-driven `opacity` on `Shape` must flow through the same retained
  compositing path as direct `Shape.opacity`

## File Plan

### 1. Shape Surface And Validation

Primary modules:

- `lib/ui/core/shape_schema.lua`
- `lib/ui/core/shape.lua`

Required outcomes:

- add `strokeColor`, `strokeOpacity`, `strokeWidth`, `strokeStyle`,
  `strokeJoin`, `strokeMiterLimit`, `strokePattern`, `strokeDashLength`,
  `strokeGapLength`, `strokeDashOffset`, and `opacity`
- keep `strokeWidth` scalar-only
- reject `border*`, `background*`, `cornerRadius*`, `shadow*`, `skin`,
  `shader`, `mask`, and `blendMode` on `Shape`
- preserve the existing leaf-only and containment behavior

### 2. Shared Shape Stroke Helpers

Primary modules:

- `lib/ui/shapes/draw_helpers.lua`
- one new shared shape-stroke helper module if separation is clearer

Required outcomes:

- centralize fill/stroke color save-restore logic
- centralize line-state save-restore logic for style, join, width, and miter
- add helpers for canonical perimeter traversal and cumulative dash phase
- keep helper boundaries shape-oriented rather than `Drawable` border-oriented

### 3. Concrete Shape Stroke Rendering

Primary modules:

- `lib/ui/shapes/rect_shape.lua`
- `lib/ui/shapes/circle_shape.lua`
- `lib/ui/shapes/triangle_shape.lua`
- `lib/ui/shapes/diamond_shape.lua`

Required outcomes:

- fill remains unchanged
- stroke paints after fill
- polygon shapes use the same canonical local geometry for fill, stroke, and
  containment
- `CircleShape` stroke uses the same polygon approximation family as fill
- `strokeJoin` and `strokeMiterLimit` are accepted on every shape, but inert on
  `CircleShape`

### 4. Generalized Node Opacity

Primary modules:

- `lib/ui/core/container.lua`
- `lib/ui/core/shape.lua`

Required outcomes:

- generalize retained render effects so `Shape` can participate in node opacity
- keep `shader`, `mask`, and `blendMode` restricted to documented carriers
- preserve current `Drawable` behavior while widening opacity support to other
  render-capable nodes
- ensure motion-owned root `opacity` values are honored for `Shape`

### 5. Acceptance Coverage

Primary code areas:

- `spec/shape_primitive_surface_spec.lua`
- `spec/rect_shape_render_spec.lua`
- `spec/nonrect_shape_spec.lua`
- new focused shape stroke / opacity specs as needed

Required outcomes:

- regression coverage for the new public surface
- draw-path verification for stroke and opacity
- motion-driven opacity verification on `Shape`
- explicit coverage that outward stroke does not expand hit testing

## Recommended Execution Order

1. confirm the exact `lib/ui` seams for shape schema, draw helpers, and
   drawable-only isolation
2. add the `Shape` public surface and validation changes
3. introduce shared stroke helpers and wire polygon-shape stroke rendering
4. add `CircleShape` stroke rendering and canonical dashed traversal behavior
5. generalize retained node opacity so `Shape.opacity` and motion-driven
   opacity work correctly
6. finish with focused acceptance coverage

## Verification

Minimum verification after implementation:

- `Shape` accepts the approved `stroke*` props and `opacity`
- `Shape` rejects `border*` and other excluded styling families
- `strokeWidth` rejects non-scalar input
- no stroke paints when `strokeColor` is absent or `strokeWidth == 0`
- `strokeStyle` and `strokePattern` behave independently
- polygon shapes stroke along the same silhouette used for fill and hit testing
- `CircleShape` stroke follows the shared approximation path
- `opacity = 0` keeps `Shape` targetable
- motion-driven `opacity` affects `Shape` rendering through the retained path
