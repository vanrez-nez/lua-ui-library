# Task 05: Phase 02 Demo Harness And Acceptance

## Goal

Build a Phase 2 verification harness that demonstrates the normalized runtime behavior without baking extra lifecycle API into the public contract.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.4.1 Stage`
- `docs/spec/ui-foundation-spec.md §6.4.2 Scene`
- `docs/spec/ui-foundation-spec.md §6.4.3 Composer`
- `docs/spec/ui-foundation-spec.md §3G Failure Semantics`

## Scope

- Create or revise `test/phase2/`
- Lifecycle-order validation
- Transition interruption validation
- Overlay-layer precedence validation
- Scene caching validation
- Two-pass assertion validation

## Screen Normalization

- Lifecycle screens should display enter-before, enter-after, leave-before, and leave-after, not a public `"running"` phase.
- Transition interruption screens should verify the final scene lifecycle guarantees from the spec, especially that intermediate scenes do not execute forbidden enter/leave hooks.
- Overlay screens should demonstrate Stage/Composer layer ownership, not a public overlay-scene API commitment.
- Two-pass assertion screens may use `pcall` in the harness so the demo remains usable after the failure.

## Non-Goals

- No full event propagation demo yet.
- No focus trapping demo yet.
- No Modal or Alert demo yet.

## Acceptance Checks

- Every harness claim can be tied to a spec-backed runtime behavior.
- Lifecycle logs reflect spec hook boundaries only.
- Unknown-scene navigation and hook-error paths can be demonstrated deterministically.
