# Task 04: Container Ordering, Clipping, And Hit Testing

## Goal

Implement sibling-local z-order, clip enforcement, and hit testing in a way that matches the foundation spec instead of the earlier draft shortcuts.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.1.1 Container`
- `docs/spec/ui-foundation-spec.md §3D Interaction Model`
- `docs/spec/ui-foundation-spec.md Glossary: hit test, disabled, local space, world space`

## Scope

- Sibling ordering by `zIndex` then stable insertion order
- Reverse draw-order hit resolution
- Clip application for rendering
- Clip application for hit testing
- Dual-path clipping implementation choice for Love2D

## Required Behavior

- Draw order resolves by ascending `zIndex`, then stable insertion order.
- Hit testing resolves in reverse draw order among eligible siblings.
- Non-interactive nodes are never hit targets, but they remain structural ancestors for descendant routing and later propagation.
- Disabled nodes are not valid interactive targets, and disabled participation must not leak targetability to descendants in contradiction to the spec's disabled semantics.
- `clipChildren = true` clips both rendering and hit testing to the node's own bounds.

## Implementation Constraints

- The scissor-versus-stencil split is an implementation choice, not a public API.
- Nested clip regions must compose correctly.
- Zero-area clip bounds must produce an empty effective clip region, not a no-op clip.

## Missing Detail Normalization

- The original phase draft's `enabled = false` pass-through behavior is not accepted.
- The task must define one internal helper for "effective target eligibility" so hit testing, later event dispatch, and focus gating share the same semantics.

## Non-Goals

- No event bubbling or capture yet.
- No gesture ownership yet.

## Acceptance Checks

- Reordering a child by `zIndex` changes both draw order and hit-test priority.
- Non-interactive ancestors can still expose interactive descendants to hit resolution.
- A clipped rotated subtree remains clipped in both draw output and point containment checks.
