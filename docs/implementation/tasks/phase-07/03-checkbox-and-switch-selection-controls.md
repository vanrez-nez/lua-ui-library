# Task 03: Checkbox And Switch Selection Controls

## Goal

Implement `Checkbox` and `Switch` on the settled selection-control contract, including negotiated ownership, structural content regions, and the published toggle and drag rules.

## Authority

- `docs/spec/ui-controls-spec.md §6.3 Checkbox`
- `docs/spec/ui-controls-spec.md §6.4 Switch`
- `docs/spec/ui-controls-spec.md §4C.2 Public State Ownership Matrix`
- `docs/spec/ui-controls-spec.md §8.1-§8.3`

## Settled Contract Points

- `Checkbox` uses `checked`, `onCheckedChange`, `disabled`, `label`, and `toggleOrder`.
- `Checkbox` supports `checked`, `unchecked`, and `indeterminate`, and `toggleOrder` is the public toggle contract.
- `Checkbox` label and description are structural content regions; the label may participate in activation, while the description must not.
- `Switch` uses `checked`, `onCheckedChange`, `disabled`, `dragThreshold`, and `snapBehavior`.
- `Switch` supports tap and drag semantics, with drag resolution governed by `dragThreshold` and `snapBehavior`.
- `Switch` label and description remain structural content regions that do not participate in the drag gesture.

## Implementation Guardrails

- Do not preserve draft-only public props such as `defaultChecked` or `allowIndeterminate`.
- Uncontrolled behavior uses the spec-owned uncontrolled defaults; it does not imply a public `default*` prop surface.
- Nested interactive controls inside label or description regions remain unsupported.
- Midpoint-only drag resolution is not the public `Switch` contract.

## Acceptance Checks

- `Checkbox` follows the default order `unchecked -> checked -> unchecked` when `toggleOrder` is nil.
- `Checkbox` with current state `indeterminate` and nil `toggleOrder` resolves the next state to `checked`.
- `Switch` ignores tap and drag input while disabled.
- Drag release honors `dragThreshold` and `snapBehavior`, including the no-change case when the gesture stays below threshold and does not cross the midpoint.
