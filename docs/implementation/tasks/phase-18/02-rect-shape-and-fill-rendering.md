# Phase 18 Task 02: Rect Shape And Fill Rendering

## Goal

Implement the simplest working `Shape` render path by adding fill rendering and
`RectShape` before introducing transformed containment or harder geometry.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md` `Shape`
- `docs/spec/ui-foundation-spec.md` `RectShape`
- `docs/incidents/spec_patch_drawable_shape_surface.md` sections:
  - `Public Surface`
  - `RectShape`
  - `Acceptance Criteria`

## Scope

- base `Shape:draw(...)` behavior or equivalent primitive draw hook
- fill-color and fill-opacity application
- `RectShape`
- zero-area and transparent-fill edge behavior

## Concrete Module Targets

- `lib/ui/core/shape.lua`
- add `lib/ui/shapes/rect_shape.lua`
- any small shared helper needed for shape fill application

## Implementation Guidance

- start with the rectangular case because it can reuse the base local bounds
  silhouette directly
- keep the render path fill-only; do not add stroke or styling hooks
- keep draw behavior usable from the ordinary retained traversal without
  special-casing `Drawable`
- ensure the rendered silhouette for `RectShape` matches the full local bounds

## Required Behavior

- `Shape` can render a filled silhouette using `fillColor` and `fillOpacity`
- `RectShape` renders the full local bounds rectangle
- zero-area bounds remain valid and draw nothing
- `fillOpacity = 0` remains valid and does not remove the node from the tree

## Non-Goals

- no non-rect shape classes
- no transformed hit testing changes yet
- no demo/doc sync work yet

## Acceptance Checks

- `RectShape` renders correctly with default and explicit fill values
- the draw path does not depend on `Drawable` styling infrastructure
- the drawn rectangle matches the intended local-bounds silhouette

