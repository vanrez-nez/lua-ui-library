# Task 03: Hover Tracking And Interaction State

## Goal

Implement hover tracking as internal interaction-state plumbing, matching the spec’s explicit classification of hover ownership as derived internal state rather than public API.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §3C.1 State Category Taxonomy`
- `docs/spec/ui-foundation-spec.md §3C.6 Derived State`
- `docs/spec/ui-foundation-spec.md §3D.4 Focus Model`
- `docs/spec/ui-foundation-spec.md §7.1.2 Target resolution rules`

## Scope

- Track the current hover candidate during pointer movement with no button held
- Update the previous and new hover owners when the target changes
- Provide internal pointer-enter / pointer-leave style notifications if needed by controls

## Required Behavior

- Hover changes are derived from hit testing and pointer movement.
- Hover state does not interfere with the logical focus model.
- Hover updates remain consistent with current effective visibility and clipping.

## Normalization Rules

- `hovered` should be treated as internal derived interaction state in this task set, not as a public node contract.
- Synthetic pointer-enter / pointer-leave notifications should remain internal plumbing, not named public events in this phase.
- Hover tracking should not alter the propagation contract for Activate, Navigate, Dismiss, Scroll, or Drag.

## Non-Goals

- No new public hover event names.
- No public focus-request helper naming in this phase.

## Acceptance Checks

- Moving the pointer between eligible targets updates hover ownership deterministically.
- Hover changes do not emit public propagation events.
- Hover state clears cleanly when the pointer leaves all eligible targets.
