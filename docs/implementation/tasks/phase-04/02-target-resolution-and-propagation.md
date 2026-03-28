# Task 02: Target Resolution And Propagation

## Goal

Implement event target resolution and the capture/target/bubble pipeline in the order and with the cancellation semantics required by the foundation spec.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §7.1.1 Event object contract`
- `docs/spec/ui-foundation-spec.md §7.1.2 Target resolution rules`
- `docs/spec/ui-foundation-spec.md §7.1.3 Default actions`

## Scope

- Overlay-first target resolution
- Base-scene fallback target resolution
- Reverse draw-order descendant walking
- Capture, target, and bubble phase delivery
- Default-action execution after propagation

## Required Behavior

- Target resolution checks the active overlay layer before the base scene layer.
- Within a sibling set, higher z-order is considered before lower z-order.
- Propagation phases fire in capture, target, then bubble order.
- `preventDefault()` suppresses the component default action but not propagation.
- Errors thrown by listeners propagate upward and halt the current delivery.

## Normalization Rules

- Target eligibility must consider effective visibility and clipping, not only local node flags.
- If no valid target exists, the raw event is silently dropped.
- Listener ordering on a single node must be deterministic, but the concrete listener API surface stays provisional unless separately documented.

## Non-Goals

- No focus traversal implementation beyond the event pipeline boundary.
- No public hover propagation event.

## Acceptance Checks

- Overlay nodes win over base-scene nodes in overlap regions.
- Capture listeners fire before target and bubble listeners.
- `stopPropagation()` and `stopImmediatePropagation()` halt propagation exactly as specified.
