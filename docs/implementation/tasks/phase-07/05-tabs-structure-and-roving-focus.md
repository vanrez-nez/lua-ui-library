# Task 05: Tabs Structure And Roving Focus

## Goal

Implement `Tabs` as the settled structural and value-driven control with manual activation, trigger-panel pairing, and roving focus.

## Authority

- `docs/spec/ui-controls-spec.md §6.9 Tabs`
- `docs/spec/ui-controls-spec.md §4B.1-§4B.3`
- `docs/spec/ui-controls-spec.md §4C.2`
- `docs/spec/ui-foundation-spec.md §3B`

## Settled Contract Points

- The public `Tabs` surface is `value`, `onValueChange`, `orientation`, `activationMode`, `listScrollable`, `loopFocus`, and `disabledValues`.
- `Tabs` is structural: one `list` region, one `panels` region, and mapped `trigger` / `panel` pairs registered within one owning root.
- Trigger focus movement stays separate from activation.
- `activationMode` is `"manual"` in this revision; any other value is invalid.
- Inactive panels remain part of the control structure but must not participate in ordinary focus traversal or pointer targeting.

## Implementation Guardrails

- Keep helper registration or mutation methods such as `addTab(...)` or `setTriggerDisabled(...)` internal if they exist at all.
- Do not add a public `defaultValue` prop. Uncontrolled initial value resolution follows the spec-owned active-value rules.
- The trigger list may use scrollable composition internally, but scrolling must not change the active value.
- Duplicate values and unmatched trigger/panel mappings are deterministic hard failures, not soft warnings.

## Acceptance Checks

- Directional focus movement skips disabled triggers and respects `loopFocus`.
- Confirm activation proposes a new active value only after focus has already moved to the intended trigger.
- When all triggers are disabled, no active value resolves and the control remains valid without failing.
- When the active value becomes invalid because structure changes, replacement resolution follows the published value rules instead of leaving the root in a split state.
