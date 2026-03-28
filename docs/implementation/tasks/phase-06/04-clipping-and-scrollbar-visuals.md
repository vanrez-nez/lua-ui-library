# Task 04: Clipping And Scrollbar Visuals

## Goal

Implement viewport clipping and optional scrollbar parts without turning the current visual or handle treatment into hard public contract.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.3.1 ScrollableContainer`
- `docs/spec/ui-foundation-spec.md §7.4 Render Effects And Shaders`
- `docs/spec/ui-foundation-spec.md §8.5 Structure Vs. Appearance Boundary`

## Scope

- Viewport clipping
- Stencil/scissor reuse from the foundation clipping system
- Optional scrollbar visuals and handles
- Scrollbar part placement and update from current scroll state

## Required Behavior

- The viewport clips descendant drawing and hit testing.
- Scrollbar parts, when present, remain non-focusable.
- Any implemented scrollbar-handle dragging must stay within the `scrollbars` role and must not introduce a separate public API surface.
- The component remains valid when scrollbars are disabled.

## Implementation Boundary

- Exact scrollbar thickness, placement, thumb interpolation, visibility heuristics, and handle hit policy should remain internal unless separately standardized.
- The choice to use thin rectangles or other primitives is a rendering decision, not a new public contract.

## Non-Goals

- No public scrollbar geometry API.
- No separate public imperative scrollbar-handle API.

## Acceptance Checks

- Rotated and non-rotated clipping both preserve scroll bounds correctly.
- Scrollbar visuals, and any implemented drag handles, update from scroll state without changing the public API.
- Disabling scrollbars does not alter content scrolling behavior.
