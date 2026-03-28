# Task 03: Alert Control Contract

## Goal

Implement `Alert` as a specialized `Modal` with the stronger content and initial-focus requirements defined by the spec.

## Spec Anchors

- `docs/spec/ui-controls-spec.md §6.8 Alert`
- `docs/spec/ui-controls-spec.md §4B.1 Control Validity Rules`
- `docs/spec/ui-controls-spec.md §4B.3 Control Slot Declarations`
- `docs/spec/ui-controls-spec.md §4C.2 Public State Ownership Matrix`

## Scope

- `lib/ui/controls/alert.lua`
- Required `title` and `actions`
- Optional `message`
- `variant`
- `initialFocus`
- Inheritance of Modal state and accessibility contract

## Required Behavior

- Alert is announced as an alert dialog and uses the title as the accessible name.
- The actions container must contain at least one activation control.
- When `initialFocus` is present, the identified action receives focus on open.
- When `initialFocus` is absent or invalid, the first action becomes focused.
- Alert inherits the full Modal contract unless this task narrows it only where the spec says so.

## Missing Detail Normalization

- Avoid freezing a custom constructor signature as public API.
- Keep alert action ordering and container management aligned to the required slot contract, not to an implementation-specific list API.
- If the implementation uses additional internal validation for title content, keep that validation consistent with the accessible-name requirement rather than turning it into a broader public rule.

## Non-Goals

- No public overlay registry behavior.
- No public running-phase lifecycle.
- No extra modal taxonomies beyond the documented Alert variants.

## Acceptance Checks

- Missing actions hard-fail at the point the spec-backed contract can know they are invalid.
- Initial focus follows the spec’s alert rules.
- Nested interactive content inside actions remains valid when the container contract permits it.
