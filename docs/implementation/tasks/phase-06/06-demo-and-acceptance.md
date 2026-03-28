# Task 06: Phase 06 Demo And Acceptance

## Goal

Build a Phase 6 verification harness that demonstrates spec-backed scrolling behavior without freezing implementation-specific scroll math.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.3.1 ScrollableContainer`
- `docs/spec/ui-foundation-spec.md §3D Interaction Model`
- `docs/spec/ui-foundation-spec.md §3E.2 Overflow And Constraint Behavior`

## Scope

- Create or revise `test/phase6/`
- Vertical, horizontal, two-axis, momentum, overscroll, nested-scroll, and scrollbar demos

## Screen Normalization

- Keep vertical, horizontal, and two-axis demonstrations.
- Keep nested scroll consumption demonstration.
- Keep momentum and overscroll demonstrations, but do not present the current damping or threshold values as spec-stable contract.
- If scrollbar handle behavior is demonstrated, present it as component behavior rather than as a separate public helper surface.
- The sidebar may display runtime state and derived values, but it should not imply that implementation-specific velocity math is public API.

## Non-Goals

- No `ui.navigate`-as-scroll public contract.
- No public child-attachment API demo.
- No demo language that implies scrollbars are permanently visual-only when the current spec leaves their handle behavior internal.

## Acceptance Checks

- Empty content remains valid and non-scrolling.
- Both axes disabled remains valid and inert.
- Momentum and overscroll behavior are observable but do not depend on undocumented internal parameters in the harness contract.
- The harness does not present implementation helper names or provisional APIs as settled public contract.
