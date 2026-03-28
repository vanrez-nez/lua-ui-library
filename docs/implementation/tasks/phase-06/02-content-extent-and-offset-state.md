# Task 02: Content Extent And Offset State

## Goal

Implement the scroll container state model around content extent measurement, valid offset ranges, and idle/dragging/inertial state transitions.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.3.1 ScrollableContainer`
- `docs/spec/ui-foundation-spec.md §3C State Model`
- `docs/spec/ui-foundation-spec.md §3E.2 Overflow And Constraint Behavior`

## Scope

- Measure content extent from the laid-out content subtree
- Resolve viewport dimensions
- Clamp offsets to valid ranges
- Maintain `idle`, `dragging`, and `inertial` state

## Required Behavior

- Content extent is derived after the content subtree has been laid out.
- Valid scroll ranges are computed from content extent minus viewport extent.
- Empty content remains valid and yields zero content extent.
- When both scroll axes are disabled, the container remains valid and never scrolls.

## Implementation Boundary

- Overscroll and momentum must affect observable state as the spec requires, but exact damping, spring-back, velocity sampling, and stop-threshold values remain internal.
- `momentumDecay` validation should follow the spec surface, but do not add extra range semantics unless they are required elsewhere in the codebase and documented as internal constraints.

## Non-Goals

- No public scroll math API.
- No consumer-facing measurement API.

## Acceptance Checks

- Offset clamping is correct at both lower and upper bounds.
- Empty content does not enter a scrolling state.
- State transitions match the spec model and remain stable across repeated layout updates.
