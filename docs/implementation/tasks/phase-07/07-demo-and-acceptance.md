# Task 07: Phase 07 Demo And Acceptance

## Goal

Build or revise the Phase 07 harness so it proves the normalized control behavior without depending on non-spec APIs.

## Spec Anchors

- `docs/spec/ui-controls-spec.md:392-1240`
- `docs/spec/ui-controls-spec.md:1175-1235`
- `docs/spec/ui-foundation-spec.md:594-633`

## Scope

- Create or revise `test/phase7/`
- Verify Text, Button, Checkbox, Switch, TextInput, TextArea, and Tabs
- Keep Modal/Alert out of Phase 07 coverage

## Screen Normalization

- Text screens should show `textAlign` and `textVariant` behavior rather than a new drawable alignment prop.
- Button screens should show pressed-state ownership and activation ordering.
- Checkbox and Switch screens should show negotiated state behavior, label/description content, and drag semantics.
- TextInput and TextArea screens should show controlled and uncontrolled behavior, selection, composition, clipboard, and scroll behavior.
- Tabs screens should show roving focus, manual activation, and disabled trigger skipping.

## Non-Goals

- No stable imperative builder-method coverage.
- No Modal or Alert screens.
- No theming-token resolution yet.

## Acceptance Checks

- Every screen maps to a spec-backed public control contract.
- The harness does not rely on `setContent`, `addTab`, or other non-stabilized helper APIs.
- Hard failure cases can be observed without making the harness unusable after the failure is caught where appropriate.
