# Task 04: Focused Indicator And Cleanup

## Goal

Implement the focus indicator protocol and cleanup rules so focused state never leaks across reparenting, destruction, or draw cycles.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §3C.6 Derived State`
- `docs/spec/ui-foundation-spec.md §7.2 Focus`
- `docs/spec/ui-foundation-spec.md §3E.5 Destruction During Activity`

## Scope

- Derived `focused` state for draw-time use
- Default focus-ring rendering for Drawable
- Cleanup on destroy
- Cleanup on reparent or loss of eligibility

## Required Behavior

- Focused nodes render the default visible ring in Phase 5.
- The ring is derived from current focus ownership, not stored as durable node state.
- Destroying the focused node clears Stage focus ownership.
- Reparented or hidden nodes cannot retain stale focus indicators.

## Missing Detail Normalization

- The exact ring geometry in the implementation doc is acceptable as a rendering choice, but it should remain a presentation decision, not a public contract surface unless later stabilized.
- The draw-time mutation of a `focused` field should be treated as an internal draw context rather than as part of the public node API.

## Non-Goals

- No control-specific focus skinning yet.
- No theme-based focus-ring styling yet.

## Acceptance Checks

- Focus ring appears only on the currently focused node.
- Focus ring disappears immediately when focus changes or the node is destroyed.
- The runtime never holds a dangling reference to a destroyed focus owner.
