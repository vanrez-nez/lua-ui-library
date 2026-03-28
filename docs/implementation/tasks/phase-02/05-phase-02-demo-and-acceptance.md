# Task 05: Phase 02 Demo Harness And Acceptance

## Goal

Build a Phase 02 verification harness that demonstrates spec-backed runtime behavior without promoting draft-only helper APIs into the public contract.

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

## Spec-Locked Coverage

- Lifecycle screens should display enter-before, enter-after, leave-before, and leave-after only.
- Transition interruption screens should verify the published final-scene guarantees, especially that intermediate scenes do not execute forbidden enter or leave hooks.
- Overlay screens should demonstrate `Stage` / `Composer` layer ownership and precedence, not a public overlay-scene API commitment.
- Stage synchronization screens should demonstrate viewport, `safeAreaInsets`, and safe-area bounds behavior together.
- Two-pass assertion screens may use `pcall` in the harness so the demo remains usable after the failure.

## Non-Goals

- No full event propagation demo yet.
- No focus trapping demo yet.
- No `Modal` or `Alert` demo yet.

## Acceptance Checks

- Every harness claim maps to a spec-backed runtime behavior or published trace-note clarification.
- Lifecycle logs reflect the stable hook boundaries only.
- Unknown-scene navigation and hook-error paths can be demonstrated deterministically.
