# Task 03: Input Routing And Nested Consumption

## Goal

Handle scroll and drag input according to the foundation spec while keeping event plumbing and key mappings internal.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §3D.1 Input Abstraction Model`
- `docs/spec/ui-foundation-spec.md §3D.2 Event Contract`
- `docs/spec/ui-foundation-spec.md §3D.3 Input-To-State-Proposal Mapping`
- `docs/spec/ui-foundation-spec.md §6.3.1 ScrollableContainer`

## Scope

- Scroll input handling
- Drag start/move/end handling
- Keyboard scroll handling when focused
- Programmatic scroll requests
- Nested scroll consumption behavior

## Required Behavior

- `Scroll` inputs adjust offsets within the active scroll owner.
- Drag start inside the viewport enters the dragging state.
- Drag move updates offsets from pointer delta.
- Drag release with momentum disabled clamps and returns to idle.
- Programmatic scroll requests follow the same offset, clamp, and overscroll rules without implying synthetic public event emission.
- Nested scroll containers stop propagating scroll input while they still have remaining range in the relevant direction.

## Settled Boundary

- Do not freeze `ui.navigate` as the public scroll entry point.
- Do not freeze a specific key map for wheel, arrow, page, home, or end behavior unless the implementation needs it internally.
- Event-listener phase wiring, capture order, and propagation stop mechanics should remain implementation detail unless the spec later exposes them as public API surface.
- Do not document helper names for programmatic scrolling unless a later spec revision explicitly standardizes them.

## Non-Goals

- No direct public promise about velocity window size.
- No direct public promise about rubber-band coefficients.
- No direct public promise about programmatic scroll helper names.

## Acceptance Checks

- The inner scroll container consumes scroll input while it has remaining range.
- The ancestor takes over only when the nested container reaches the relevant boundary.
- Focused scrolling works without coupling the public API to `ui.navigate`.
- Programmatic scrolling respects the same range and suppression rules as touch, wheel, and keyboard input.
