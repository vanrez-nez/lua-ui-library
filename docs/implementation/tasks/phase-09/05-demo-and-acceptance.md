# Task 05: Phase 09 Demo And Acceptance

## Goal

Build the final verification surface for `Modal`, `Alert`, overlay focus trapping/restoration, and responsive-rule behavior without widening the public API beyond the published specs.

## Spec Anchors

- `docs/spec/ui-controls-spec.md §6.7 Modal`
- `docs/spec/ui-controls-spec.md §6.8 Alert`
- `docs/spec/ui-foundation-spec.md §7.2.5 Focus and overlays`
- `docs/spec/ui-foundation-spec.md §7.3 Responsive Rules`
- `docs/spec/ui-foundation-spec.md §3G Failure Semantics`

## Scope

- Create or revise `test/phase9/`
- Modal negotiated open/close behavior
- Focus trap and restoration behavior
- Alert title/actions validity and `initialFocus`
- Nested overlay stacking behavior
- Percentage sizing, clamps, and responsive re-evaluation
- Manual harness coverage plus automated regression checks where practical

## Screen Normalization

- The modal screen validates the spec-backed prop contract:
  `open`, `onOpenChange`, `dismissOnBackdrop`, `dismissOnEscape`, `trapFocus`, `restoreFocus`, `safeAreaAware`, and `backdropDismissBehavior`.
- The alert screen validates required title/actions semantics and `initialFocus`, not a constructor-centered helper API.
- Overlay orchestration is demonstrated only as nested modal behavior mounted in the overlay layer; it must not present `showOverlay` / `hideOverlay` as stable public API.
- Responsive screens prove declarative reflow and breakpoint changes without implying one frozen public rule schema or resolver algorithm.
- Manual screens may use harness-owned logging and setup helpers, but those helpers remain test-only and must not be described as library API.

## Non-Goals

- No new control families.
- No public scene lifecycle expansion.
- No public overlay registry API.
- No promise of a viewport-only breakpoint model.
- No claim that Phase 09 introduces any stable imperative `open()` / `close()` control API.

## Required Demo Screens

### Screen 1: Modal Open/Close

- Base scene includes one focusable launch button and a small event log.
- Activating the launch button opens a modal mounted in the overlay layer.
- The modal contains body content plus at least two focusable action buttons.
- Escape closes the modal when `dismissOnEscape = true`.
- Closing the modal restores focus to the base launch button when `restoreFocus = true`.
- The log should make focus transitions and action events visible.

### Screen 2: Focus Trap

- Base scene includes several focusable controls that are reachable before the modal opens.
- While the modal is open with `trapFocus = true`, sequential traversal must stay within the modal subtree.
- Pointer interaction with the backdrop must not reach base-scene controls.
- A toggle should switch `dismissOnBackdrop` / `backdropDismissBehavior` into the non-closing case so the backdrop still blocks input while dismissal is suppressed.
- The screen should visibly indicate if focus leaks to the base scene while the trap is active.

### Screen 3: Alert

- Base scene includes a trigger that opens an alert dialog.
- The alert includes:
  required title,
  optional message,
  actions region with at least two activation controls.
- `initialFocus` should move focus to the configured action when present.
- If the harness demonstrates a non-closing alert, Escape and backdrop activation must remain inert when the configured props require that.
- The screen should make the currently focused action obvious.

### Screen 4: Stacked Overlays

- Base scene opens Modal A.
- Modal A contains a trigger that opens Modal B.
- While Modal B is open, base-scene content and Modal A controls must be unreachable through traversal.
- Closing Modal B restores focus to the trigger inside Modal A that opened it.
- Closing Modal A restores focus to the original base-scene trigger.
- The log should make the restoration chain inspectable.

### Screen 5: Percentage Sizing And Clamps

- Demonstrate percentage-based widths and heights against the effective parent region.
- Include at least one child with `minWidth` / `maxWidth` or `minHeight` / `maxHeight` so clamp behavior is visible during resize.
- Show resolved pixel dimensions in the harness so the acceptance result is inspectable rather than inferred.
- Zero-size or near-zero parent cases must degrade to `0` rather than erroring or producing invalid geometry.

### Screen 6: Breakpoint Responsive

- Demonstrate at least three responsive states driven by declarative rules.
- Responsive conditions may reference viewport dimensions, orientation, safe area, or parent dimensions; the harness should not imply viewport width is the only supported input.
- Resizing across thresholds must produce deterministic layout changes with no hard failure.
- The harness should show the active responsive state and current viewport dimensions for inspection.

## Automated Verification Boundary

- Add or extend unit specs for:
  modal mount/detach behavior,
  backdrop and escape dismissal gating,
  focus restoration on close,
  nested modal restoration order,
  alert title/actions hard failures,
  alert `initialFocus` fallback behavior.
- Responsive behavior that is already unit-tested in earlier phase specs should be reused rather than duplicated unless Phase 09 adds a new regression surface.
- Automated coverage should stay centered on spec-visible behavior, not on internal overlay bookkeeping structure.

## Hard-Failure Demonstrations

- The harness should be able to demonstrate the alert-without-actions failure path using `pcall` or equivalent guarded execution so the app remains usable afterward.
- Empty alert title should be demonstrated as a deterministic invalid configuration, again without leaving the entire harness unusable.
- Any demonstration of internal-only overlay helpers is out of scope.

## Acceptance Checks

- Modal content mounts in the overlay layer and blocks base-scene interaction while open.
- Focus cannot leak to base-scene content while a focus-trapped overlay is active.
- Closing an overlay restores focus when configured and possible.
- Nested modal flows preserve the correct restoration chain.
- Alert validates required title and action content and honors `initialFocus` fallback rules.
- Responsive resizing updates layout deterministically without hard failures.
- Percentage sizing and clamp behavior remain stable under resize and zero-parent-edge cases.
- The harness can demonstrate hard-failure paths without leaving the app unusable afterward when `pcall` is appropriate.
