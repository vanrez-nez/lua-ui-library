# Phase 19 Task 02: Shared Shape Stroke Helpers

## Goal

Create the shared helper layer that shape stroke rendering will use across all
built-in shape classes.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md` `Shape-owned stroke and opacity contract`
- `docs/incidents/spec_patch_shape_border_and_opacity_surface.md`

## Scope

- shared fill/stroke color application helpers
- line-state save/restore helpers
- canonical path helpers for dashed traversal
- any reusable local-to-world point helpers needed by stroke rendering

## Concrete Module Targets

- `lib/ui/shapes/draw_helpers.lua`
- optionally one new helper module under `lib/ui/shapes/`

## Implementation Guidance

- keep helpers shape-oriented rather than styling-oriented
- avoid directly coupling helpers to `Drawable` props or styling resolution
- centralize the common line-state behavior:
  - line width
  - line style
  - line join
  - miter limit
- centralize cumulative-distance dash traversal so later shape tasks do not
  each reimplement phase math

## Required Behavior

- helpers can apply fill color and stroke color while restoring prior graphics
  state
- helpers can save and restore line-state mutations safely
- helpers can flatten canonical point lists for polygon drawing
- helpers can support cumulative perimeter traversal from an explicit start
  point

## Non-Goals

- no final shape-class wiring yet
- no node-opacity generalization yet

## Acceptance Checks

- the helper layer is sufficient to implement polygon and circle stroke
  rendering without duplicating dash-phase math in every concrete shape file
- no helper introduces `border*` assumptions into the shape renderer
