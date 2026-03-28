# Task 05: Phase 05 Demo And Acceptance

## Goal

Build a Phase 5 verification harness that proves focus traversal, explicit focus request, pointer coupling, trap restoration, and the focus-change event without over-claiming unsupported public API.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §7.2 Focus`
- `docs/spec/ui-foundation-spec.md §3D.4 Focus Model`
- `docs/spec/ui-foundation-spec.md §7.2.5 Focus and overlays`

## Scope

- Create or revise `test/phase5/`
- Sequential traversal demo
- Directional traversal demo
- Focus restoration demo
- Pointer-focus coupling demo
- `ui.focus.change` logging

## Screen Normalization

- Demonstrate focus movement and restoration as runtime behavior, but avoid presenting `requestFocus` as a stable public handle if it remains an internal helper.
- The focus-trap screen should be framed as overlay behavior support, not as a generic public `Container` trap prop commitment.
- Pointer coupling should be shown as a contract decision, not as a generic foundation prop guarantee.

## Non-Goals

- No control-specific accessibility assertions yet.
- No modal or alert component assertions yet.

## Acceptance Checks

- Sequential traversal matches depth-first pre-order behavior.
- Directional traversal uses the nearest eligible candidate algorithm.
- `ui.focus.change` logs previous and next targets for each acquisition path.
- The harness remains usable after hard failures when `pcall` is appropriate.
