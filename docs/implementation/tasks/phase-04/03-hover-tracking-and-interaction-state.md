# Task 03: Hover Tracking And Interaction State

## Goal

Implement hover tracking as internal interaction-state plumbing that supports controls without turning hover into a new stable public event surface.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §3C.1 State Category Taxonomy`
- `docs/spec/ui-foundation-spec.md §3C.6 Derived State`
- `docs/spec/ui-foundation-spec.md §3D.4 Focus Model`

## Scope

- Track the current hover candidate during pointer movement with no button held
- Update the previous and new hover owners when the target changes
- Provide internal pointer-enter / pointer-leave style notifications if needed by controls

## Required Behavior

- Hover changes are derived from hit testing and pointer movement.
- Hover state does not interfere with the logical focus model.
- Hover updates remain consistent with current effective visibility and clipping.

## Normalization Rules

- `hovered` should be treated as an internal or derived interaction state unless a later spec revision explicitly stabilizes it.
- Synthetic pointer-enter / pointer-leave notifications should remain internal plumbing, not named public events in this phase.
- Hover tracking should not alter the propagation contract for Activate, Navigate, Dismiss, Scroll, or Drag.

## Non-Goals

- No new public hover event names.
- No focus ownership API in this phase.

## Acceptance Checks

- Moving the pointer between eligible targets updates hover ownership deterministically.
- Hover changes do not emit public propagation events.
- Hover state clears cleanly when the pointer leaves all eligible targets.
