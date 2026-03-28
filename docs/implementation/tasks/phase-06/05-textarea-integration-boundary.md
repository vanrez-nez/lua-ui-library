# Task 05: TextArea Integration Boundary

## Goal

Prepare the scroll container contract for internal reuse by `TextArea` without exposing a new public coupling surface.

## Spec Anchors

- `docs/spec/ui-controls-spec.md §6.6 TextArea`
- `docs/spec/ui-controls-spec.md §4B.3 Control Slot Declarations`
- `docs/spec/ui-controls-spec.md §4C.5 Control Derived State`
- `docs/spec/ui-foundation-spec.md §6.3.1 ScrollableContainer`

## Scope

- Internal reuse of the scroll state model for the text-area scroll region
- Axis-interception rules for text-entry content
- Support for internal vertical scrolling and wrap-dependent horizontal scrolling
- Preserve `TextArea`'s narrower public scroll prop surface

## Required Behavior

- The text-area scroll region can rely on the foundation scroll state model.
- Same-axis interception rules from the controls spec remain a composition prohibition, not an invitation to add recovery-only APIs.
- Horizontal scrolling suppression when wrapping is enabled must remain intact.
- `TextArea` reuse must not cause foundation-only props such as `overscroll`, `scrollStep`, `showScrollbars`, or `momentumDecay` to leak onto the `TextArea` public surface unless the controls spec is amended.

## Settled Boundary

- Do not expose a TextArea-specific public scroll API in the foundation scroll component.
- Keep the reuse boundary internal so the control spec can consume it without changing `ScrollableContainer`’s public contract.

## Non-Goals

- No multiline editing implementation here.
- No text-entry lifecycle implementation here.

## Acceptance Checks

- The scroll region can be embedded by the text-entry implementation without requiring new public scroll methods.
- Axis conflicts are prevented or rejected according to the controls-spec composition rules.
