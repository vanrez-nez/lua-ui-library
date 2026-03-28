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

## Required Behavior

- The text-area scroll region can rely on the foundation scroll state model.
- Same-axis interception rules prevent a text area from being nested inside a scroll container that consumes the same axis.
- Horizontal scrolling suppression when wrapping is enabled must remain intact.

## Missing Detail Normalization

- Do not expose a TextArea-specific public scroll API in the foundation scroll component.
- Keep the reuse boundary internal so the control spec can consume it without changing `ScrollableContainer`’s public contract.

## Non-Goals

- No multiline editing implementation here.
- No text-entry lifecycle implementation here.

## Acceptance Checks

- The scroll region can be embedded by the text-entry implementation without requiring new public scroll methods.
- Axis conflicts are detectable and fail deterministically or are prevented by composition rules.
