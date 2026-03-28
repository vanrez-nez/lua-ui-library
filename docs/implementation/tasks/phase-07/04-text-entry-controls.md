# Task 04: Text Entry Controls

## Goal

Implement `TextInput` and `TextArea` on the spec-backed text-entry contract, including controlled state, selection, composition, clipboard, and scroll behavior.

## Spec Anchors

- `docs/spec/ui-controls-spec.md:735-909`
- `docs/spec/ui-controls-spec.md:1168-1173`
- `docs/spec/ui-controls-spec.md:1201-1203`

## Scope

- Implement `lib/ui/controls/text_input.lua`
- Implement `lib/ui/controls/text_area.lua`
- Preserve the documented public props, callbacks, and state models

## Required Behavior

- `TextInput` exposes `value`, `selectionStart`, `selectionEnd`, `placeholder`, `disabled`, `readOnly`, `maxLength`, `inputMode`, `submitBehavior`, and `onSubmit`.
- Uncontrolled text state remains library-owned without inventing a new stable imperative getter/setter API.
- Composition candidate handling follows the documented compose/input split.
- `TextArea` inherits the `TextInput` contract and adds `wrap`, `rows`, `scrollXEnabled`, `scrollYEnabled`, and `momentum`.
- `TextArea` keeps its scroll region scoped to the internal field content.

## Internal-Only Boundaries

- `defaultValue` is not a spec-stabilized public prop in this revision.
- Raw platform key handling and `love.keyboard.setTextInput` wiring should stay internal behind the logical input boundary.

## Non-Goals

- No rich-text authoring.
- No multiline submit semantics for `TextArea`.
- No externally managed native text-input lifecycle.

## Acceptance Checks

- `maxLength` truncates input silently rather than failing.
- `readOnly` still allows focus, selection, and copy.
- `TextArea` newline insertion does not trigger submit.
- Composition cancellation discards the candidate without committing text.
