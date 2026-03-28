# Task 03: Container Transform, Measurement, And Dirty State

## Goal

Implement the `Container` state model around local/world transform resolution, measurement caches, bounds, and dirty propagation.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.1.1 Container`
- `docs/spec/ui-foundation-spec.md §3C State Model`
- `docs/spec/ui-foundation-spec.md §3E.4 Transition Interruption`

## Scope

- Local transform input storage
- Local matrix resolution
- World matrix composition through ancestors
- Bounds resolution
- Dirty and clean state transitions
- Coordinate conversion helpers

## Required Behavior

- Geometry mutation marks local measurement or transform state dirty.
- Tree mutation marks ordering and world state dirty.
- Breakpoint resolution changes must participate in the dirty-state model even if Phase 1 only provides placeholder resolution hooks.
- `visible = false` must not be treated as an escape hatch from geometry, transform, or descendant-state resolution while the node remains attached.
- Dirty resolution completes during Stage update traversal before draw traversal begins.

## Required APIs

- `getWorldTransform()`
- `localToWorld(...)`
- `worldToLocal(...)`
- Bounds query support needed by clipping and hit testing

## Settled Spec Clarifications

- Dirty coverage is broader than the original phase draft: local measurement, local transform, descendant world state, and bounds all need explicit invalidation coverage.
- Responsive input re-resolution is part of the spec-shaped state model now, not an optional follow-up refinement.

## Non-Goals

- No percentage, `content`, or general `fill` measurement algorithm yet beyond the limited Phase 1 cases explicitly needed for retained-tree correctness.
- No layout-family placement logic yet.

## Acceptance Checks

- Parent transform changes invalidate descendant world transforms.
- `localToWorld` and `worldToLocal` are inverse operations for representative points.
- A clean subtree remains unchanged across repeated update passes with no mutations.
