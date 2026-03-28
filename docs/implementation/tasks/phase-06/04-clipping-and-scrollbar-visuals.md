# Task 04: Clipping And Scrollbar Visuals

## Goal

Implement viewport clipping and scrollbar rendering without turning the current visual treatment into hard public contract.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.3.1 ScrollableContainer`
- `docs/spec/ui-foundation-spec.md §7.4 Render Effects And Shaders`
- `docs/spec/ui-foundation-spec.md §8.5 Structure Vs. Appearance Boundary`

## Scope

- Viewport clipping
- Stencil/scissor reuse from the foundation clipping system
- Optional scrollbar visuals
- Scrollbar part placement and update from current scroll state

## Required Behavior

- The viewport clips descendant drawing and hit testing.
- Scrollbar parts, when present, remain non-focusable decorations or visual helpers in practice.
- The component remains valid when scrollbars are disabled.

## Implementation Boundary

- Exact scrollbar thickness, placement, thumb interpolation, and visibility heuristics should remain internal unless separately standardized.
- The choice to use thin rectangles or other primitives is a rendering decision, not a new public contract.

## Non-Goals

- No drag-to-scroll on the scrollbar itself in this phase.
- No public scrollbar geometry API.

## Acceptance Checks

- Rotated and non-rotated clipping both preserve scroll bounds correctly.
- Scrollbar visuals update from scroll state without changing the public API.
- Disabling scrollbars does not alter content scrolling behavior.
