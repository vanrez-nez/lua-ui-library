# Task 04: Focused Indicator And Cleanup

## Goal

Implement the Phase 05 default focus indicator and cleanup rules so focus-derived rendering state never leaks across reparenting, destruction, or draw cycles.

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

## Authority Boundaries

- `docs/spec/ui-foundation-spec.md §3C.6` settles that any transient `focused` render flag is internal derived state unless a later contract exposes it.
- The exact ring geometry from the phase plan may be used as the Phase 05 default rendering choice, but it remains presentation detail rather than a new public API surface unless later stabilized.

## Non-Goals

- No control-specific focus skinning yet.
- No theme-based focus-ring styling yet.

## Acceptance Checks

- Focus ring appears only on the currently focused node.
- Focus ring disappears immediately when focus changes or the node is destroyed.
- The runtime never holds a dangling reference to a destroyed focus owner.
