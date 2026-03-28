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
- Breakpoint resolution hooks may remain placeholders, but the dirty-state model must reserve that transition path because it is part of the spec.
- Dirty resolution completes during Stage update traversal before draw traversal begins.

## Required APIs

- `getWorldTransform()`
- `localToWorld(...)`
- `worldToLocal(...)`
- Bounds query support needed by clipping and hit testing

## Missing Detail Normalization

- The phase doc currently describes dirtiness propagating only to layout ancestors. The spec model is broader: local measurement, local transform, descendant world state, and bounds all need separate invalidation coverage.
- The task must treat responsive input re-resolution as a first-class future hook, not an afterthought added in Phase 3.

## Non-Goals

- No percentage, `content`, or general `fill` measurement algorithm yet beyond the limited Phase 1 cases explicitly needed for retained-tree correctness.
- No layout-family placement logic yet.

## Acceptance Checks

- Parent transform changes invalidate descendant world transforms.
- `localToWorld` and `worldToLocal` are inverse operations for representative points.
- A clean subtree remains unchanged across repeated update passes with no mutations.
