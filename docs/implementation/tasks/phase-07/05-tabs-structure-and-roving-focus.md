# Task 05: Tabs Structure And Roving Focus

## Goal

Implement `Tabs` as the spec-backed single-selection control with structural trigger/panel registration and roving focus.

## Spec Anchors

- `docs/spec/ui-controls-spec.md:1068-1160`
- `docs/spec/ui-controls-spec.md:322-326`
- `docs/spec/ui-controls-spec.md:1191-1203`

## Scope

- Implement `lib/ui/controls/tabs.lua`
- Expose `value`, `onValueChange`, `orientation`, `activationMode`, `listScrollable`, `loopFocus`, and `disabledValues`
- Maintain the required `list` and `panels` regions with mapped `trigger` and `panel` parts

## Required Behavior

- Trigger focus movement does not activate the tab.
- Activation is manual and only occurs on confirm input.
- Exactly one active panel is visible; inactive panels remain valid but non-participating.
- Disabled triggers are skipped during sequential and directional traversal.
- Duplicate trigger values and unmatched trigger/panel pairs hard-fail deterministically.

## Internal-Only Boundaries

- `tabs:addTab` and `tabs:setTriggerDisabled` are not spec-stabilized public methods.
- A `Row`-backed list implementation is acceptable internally, but it must not become the public contract.
- `defaultValue` is not a spec-stabilized public prop in this revision.

## Non-Goals

- No swipe-based panel switching.
- No closable, reorderable, or multi-select tabs.
- No stable imperative builder surface.

## Acceptance Checks

- The focused trigger and active value remain distinct until activation occurs.
- Tab traversal enters the trigger list and leaves it according to the spec behavior.
- The active panel resolves correctly when the active value changes or becomes invalid.
