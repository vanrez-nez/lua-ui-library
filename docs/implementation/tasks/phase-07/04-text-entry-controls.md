# Task 04: Text Entry Controls

## Goal

Implement `TextInput` and `TextArea` on the settled text-entry contract, including negotiated value and selection ownership, composition handling, clipboard behavior, and `TextArea`-owned scrolling.

## Authority

- `docs/spec/ui-controls-spec.md §6.5 TextInput`
- `docs/spec/ui-controls-spec.md §6.6 TextArea`
- `docs/spec/ui-controls-spec.md §4C.2 Public State Ownership Matrix`
- `docs/spec/ui-foundation-spec.md §3D`

## Settled Contract Points

- `TextInput` exposes `value`, `onValueChange`, `selectionStart`, `selectionEnd`, `onSelectionChange`, `placeholder`, `disabled`, `readOnly`, `maxLength`, `inputMode`, `submitBehavior`, and `onSubmit`.
- `TextInput` supports active text-entry ownership distinct from logical focus, native text input while active, committed text insertion, composition candidates, selection, and clipboard operations when available.
- `TextArea` inherits the full `TextInput` contract and adds `wrap`, `rows`, `scrollXEnabled`, `scrollYEnabled`, and `momentum`.
- `TextArea` owns its internal scroll region and keeps same-axis scroll interception scoped to that internal field content.

## Implementation Guardrails

- Do not reintroduce a public `defaultValue` prop. Uncontrolled initial value is the spec-owned uncontrolled default.
- Raw host key handling, clipboard plumbing, and native text-input activation wiring remain internal beneath the logical input contract.
- Controlled selection requires both boundaries together; a one-sided controlled selection is invalid.
- `TextArea` newline insertion replaces submit behavior for multiline editing.
- When `wrap = true`, horizontal scrolling is suppressed regardless of `scrollXEnabled`.

## Acceptance Checks

- `readOnly` still allows focus, selection, and copy, but blocks mutation.
- `maxLength` truncates typed or pasted insertion without raising an error.
- Losing focus while composing discards the candidate without committing text.
- `TextArea` inserts newline on confirm input and does not treat that command as `onSubmit`.
- `rows` and internal scroll behavior remain compatible with the `ScrollableContainer` contract without exposing new public scroll helpers.
