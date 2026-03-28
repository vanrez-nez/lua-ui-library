# Task 03: Focus Trapping And Restoration

## Goal

Implement focus trapping and restoration as runtime behavior that is spec-backed for overlays, without generalizing it into a new public foundation prop contract.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §7.2.1 Focus scopes`
- `docs/spec/ui-foundation-spec.md §7.2.5 Focus and overlays`
- `docs/spec/ui-foundation-spec.md §3D.4 Focus Model`

## Scope

- Trap stack bookkeeping
- Pre-trap focus history
- Focus restoration on trap close
- Overlay-specific scope restriction

## Required Behavior

- When an overlay with trapFocus becomes active, the previous focused node is recorded.
- Focus moves into the overlay according to overlay-specific rules.
- Traversal is restricted to the active trap scope.
- Closing or destroying the trap restores focus if the previous node remains eligible.

## Spec Gap Handling

- The phase doc uses a generic `Container` trap model. The spec only stabilizes trap behavior in overlay contexts.
- Implement the runtime support internally, but do not treat generic trap flags on `Container` as stable public API.
- Overlay-specific rules may be different for Modal and Alert later; keep the support flexible.

## Non-Goals

- No stabilized generic overlay API.
- No modal or alert component contract yet.

## Acceptance Checks

- Nested traps restore focus to the immediately prior owner, not the outer trap owner.
- Trap close clears trap bookkeeping without dangling references.
- Focus outside the trap is not eligible while the trap is active.
