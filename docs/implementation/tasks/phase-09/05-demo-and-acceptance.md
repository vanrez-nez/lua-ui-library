# Task 05: Phase 09 Demo And Acceptance

## Goal

Build the final verification harness for Modal, Alert, overlay focus trapping, and responsive-rule integration.

## Spec Anchors

- `docs/spec/ui-controls-spec.md §6.7 Modal`
- `docs/spec/ui-controls-spec.md §6.8 Alert`
- `docs/spec/ui-foundation-spec.md §7.2 Focus`
- `docs/spec/ui-foundation-spec.md §7.3 Responsive Rules`

## Scope

- Create or revise `test/phase9/`
- Modal open/close behavior
- Focus trap and restoration behavior
- Alert initial-focus and dismissal behavior
- Stacked overlay behavior
- Percentage sizing and breakpoint responsiveness

## Screen Normalization

- The modal screen should validate the spec-backed props and focus-restoration behavior, not the phase doc’s custom `open()` / `close()` API.
- The alert screen should validate required title/actions and `initialFocus`, not a constructor-specific action list API.
- The responsive screens should prove declarative reflow and breakpoint changes without implying an unspecified public resolver schema.
- Overlay stacking should be demonstrated as nested modal behavior, not as a separate public overlay registry contract.

## Non-Goals

- No new control families.
- No public scene lifecycle expansion.
- No claim that Phase 09 introduces any API outside the spec.

## Acceptance Checks

- Focus cannot leak to base-scene content while a focus-trapped overlay is active.
- Closing an overlay restores focus when configured and possible.
- Responsive resizing updates layout deterministically without hard failures.
- The harness can demonstrate hard-failure paths without leaving the app unusable afterward when `pcall` is appropriate.
