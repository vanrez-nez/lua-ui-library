# Task 06: Deferred Modal And Alert Boundary

## Goal

Record the explicit boundary between the settled controls spec and the narrower implementation scope of this Phase 07 directory.

## Authority

- `docs/spec/ui-controls-spec.md §6.7 Modal`
- `docs/spec/ui-controls-spec.md §6.8 Alert`
- `docs/spec/ui-controls-spec.md §4B.1-§4B.3`
- `docs/spec/ui-foundation-spec.md §3B`

## Settled Contract Points

- `Modal` and `Alert` are already stable controls in `docs/spec`; they are not open design work.
- Both controls are overlay-bound compounds mounted in the `Stage` overlay layer, not ordinary descendants of base-scene layout.
- Their documented props, required regions, and dismissal or focus behavior are already authoritative even though this directory does not implement them.
- Their documented structure likewise does not imply stable imperative helpers such as `open()`, `close()`, constructor coercion helpers, or action-registration builders.

## Phase Boundary For This Directory

- This Phase 07 task set covers `Text`, `Button`, `Checkbox`, `Switch`, `TextInput`, `TextArea`, and `Tabs`.
- It does not add `Modal` or `Alert` implementation work inside this directory.
- It does not invent overlay helper APIs to compensate for that deferred scope.
- It keeps the other Phase 07 control tasks compatible with the later overlay-control implementation by respecting the current spec boundaries now.

## Acceptance Checks

- The Phase 07 task docs describe `Modal` and `Alert` as deferred implementation scope, not as missing or unresolved spec content.
- The harness scope in this directory does not claim modal or alert coverage.
- No Phase 07 task in this directory freezes a modal-specific or alert-specific helper API ahead of the settled spec.
