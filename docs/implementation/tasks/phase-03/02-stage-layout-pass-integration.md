# Task 02: Stage Layout Pass Integration

## Goal

Integrate layout resolution into Stage update traversal in a way that preserves the runtime contract from the foundation spec.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.4.1 Stage`
- `docs/spec/ui-foundation-spec.md §6.2.3 Common state model`
- `docs/spec/ui-foundation-spec.md §3A.6 Lifecycle Model`

## Scope

- Add layout traversal to Stage update
- Preserve draw-pass non-resolution rule
- Support layout-dirty transitions from child mutation, size mutation, visibility mutation, and breakpoint change

## Required Behavior

- Layout resolution occurs during Stage update traversal, never during draw traversal.
- Layout pass completes before downstream behavior depends on current measurements and placements.
- Draw traversal remains read-only with respect to layout state.
- Child addition, removal, size mutation, visibility mutation, and responsive-rule changes mark affected layout roots dirty.

## Settled Boundaries

- A distinct "layout pass then transform pass" execution model is acceptable as internal implementation detail.
- That split must not be documented as a new public runtime guarantee beyond the spec’s update-pass contract.

## Non-Goals

- No focus integration yet.
- No scroll-layout integration yet.

## Acceptance Checks

- Dirty layout state resolves during Stage update and is stable for the ensuing draw.
- Repeated updates with no mutations keep layout roots in `layout_clean`.
- Draw pass never performs deferred placement work.
