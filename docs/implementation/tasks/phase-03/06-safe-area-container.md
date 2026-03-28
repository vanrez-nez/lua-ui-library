# Task 06: SafeAreaContainer

## Goal

Implement `SafeAreaContainer` against environment-reported safe-area bounds, not an ad hoc inset-only interpretation.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.2.8 SafeAreaContainer`
- `docs/spec/ui-foundation-spec.md §6.4.1 Stage`

## Scope

- Implement `lib/ui/layout/safe_area_container.lua`
- Derive content region from current safe-area bounds
- React to safe-area bounds changes
- Support per-edge inset application

## Required Behavior

- `SafeAreaContainer` derives content area from Stage-provided safe-area bounds.
- It updates when safe-area bounds change.
- Nested SafeAreaContainers apply relative to the same environment-reported safe area, not parent-adjusted insets.
- When all edge flags are false, no inset adjustment is applied.

## Missing Detail Normalization

- Desktop zero-inset behavior is fine as an implementation outcome, but the normative model remains bounds-based.
- Filling the viewport may be a common usage pattern, but it should not be documented as the component’s only or default size behavior unless the spec says so.

## Non-Goals

- No viewport ownership beyond what Stage already provides.
- No overlay behavior.

## Acceptance Checks

- Safe-area changes mark layout dirty and re-derive the content region.
- Zero-inset environments behave the same as plain non-inset layout.
- Nested SafeAreaContainers do not compound insets relative to parent content.
