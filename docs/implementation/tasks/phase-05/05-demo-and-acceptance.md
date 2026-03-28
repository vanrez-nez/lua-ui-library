# Task 05: Phase 05 Demo And Acceptance

## Goal

Build a Phase 05 verification harness that proves the settled focus behaviors from `docs/spec` while avoiding demos that overstate internal helpers as public API.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §7.2 Focus`
- `docs/spec/ui-foundation-spec.md §3D.4 Focus Model`
- `docs/spec/ui-foundation-spec.md §7.2.5 Focus and overlays`

## Scope

- Create or revise `test/phase5/`
- Sequential traversal demo
- Directional traversal demo
- Overlay-style focus restoration demo
- Pointer-focus coupling demo
- `ui.focus.change` logging

## Demo Boundaries

- Demonstrate explicit focus request support as behavior, but do not present any runtime helper such as `requestFocus(...)` as a stable public handle unless the spec later names it.
- Frame the trap screen as overlay behavior support, not as a generic public `Container` trap prop commitment.
- Frame pointer coupling as a component-contract decision, not as a generic foundation prop guarantee.
- Use the parent phase plan for scenario coverage, but keep the user-facing acceptance language anchored to `docs/spec`.

## Non-Goals

- No control-specific accessibility assertions yet.
- No modal or alert component assertions yet.

## Acceptance Checks

- Sequential traversal matches depth-first pre-order behavior.
- Directional traversal uses the nearest eligible candidate algorithm.
- `ui.focus.change` logs previous and next targets for each acquisition path.
- Overlay-style trap close restores the prior eligible focus target.
- The harness remains usable after hard failures when `pcall` is appropriate.
