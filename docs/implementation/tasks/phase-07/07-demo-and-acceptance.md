# Task 07: Phase 07 Demo And Acceptance

## Goal

Build or revise the Phase 07 harness so it demonstrates the settled control contracts without depending on draft-only APIs.

## Authority

- `docs/spec/ui-controls-spec.md §6.1-§6.9`
- `docs/spec/ui-controls-spec.md §8.1-§8.4`
- `docs/spec/ui-foundation-spec.md §3D`

## Coverage Scope

- Verify `Text`, `Button`, `Checkbox`, `Switch`, `TextInput`, `TextArea`, and `Tabs`.
- Keep `Modal` and `Alert` out of Phase 07 harness coverage.
- Exercise controlled and uncontrolled behavior only through the spec-backed public surfaces for each control.

## Screen Normalization

- `Text` coverage should show `textAlign`, `textVariant`, wrapping, and deterministic font-failure handling rather than draft-only text props.
- `Button` coverage should show negotiated pressed-state behavior, disabled suppression, activation ordering, and empty-content validity.
- `Checkbox` and `Switch` coverage should show negotiated checked-state behavior, structural label or description content, toggle-order behavior, and drag-threshold or snap resolution.
- `TextInput` and `TextArea` coverage should show controlled value and selection behavior, placeholder rules, composition, clipboard handling, submit versus newline behavior, and internal scrolling.
- `Tabs` coverage should show manual activation, roving focus, disabled-trigger skipping, overflow-safe list behavior, and invalid-value recovery.

## Harness Guardrails

- Do not rely on `setContent(...)`, `addTab(...)`, `setTriggerDisabled(...)`, or any other non-stabilized helper as if it were public API.
- Do not rely on public `defaultChecked`, `defaultValue`, or similar draft-only props. If a demo needs pre-seeded state, use spec-backed controlled state or internal test fixture setup without documenting a new public prop.
- Hard failure cases may be demonstrated through isolated fixtures, but the harness should catch or sandbox them where appropriate so the rest of the coverage remains usable.
- Provisional Phase 07 visuals are acceptable, but they must map onto the stable part and state boundaries from the controls spec.

## Acceptance Checks

- Every demo screen maps directly to a spec-backed control contract.
- The harness distinguishes focused versus active versus controlled state where those concepts differ.
- Text-entry demos keep host-plumbing details internal and only expose the public logical behavior.
- Tabs demos do not imply automatic activation on focus movement.
