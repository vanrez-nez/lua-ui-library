# Phase 6 — ScrollableContainer

## Goals

Implement ScrollableContainer with the full three-state idle/dragging/inertial state machine, momentum/overscroll support, nested scroll consumption, scrollbars, and both-axis scrolling. This is the most stateful single component in the foundation layer and must be fully correct before the text-entry controls in Phase 7 embed it internally.

---

## Dependencies

Requires Phase 5 (Event system with ui.scroll and ui.drag, focus model, Stage as input root, stencil/scissor clipping from Phase 1).

---

## Component

### lib/ui/scroll/scrollable_container.lua

**Classification:** Primitive — viewport clipping, scroll extent/offsets, scroll input interpretation, momentum/overscroll.

---

## Structure

ScrollableContainer has two internal child slots, managed by the library (not consumer-accessible as regular children):
- **Viewport** — a Container with `clipChildren = true` at the configured bounds of the ScrollableContainer. All consumer children are placed inside the Viewport.
- **Content** — a plain Container inside the Viewport that is translated by the negative scroll offsets (`-scrollX`, `-scrollY`). Consumer children are added to the Content node.
- **Horizontal scrollbar** (optional Drawable) — rendered as a sibling of the Viewport, outside clipping. Visible only when `showScrollbars = true`.
- **Vertical scrollbar** (optional Drawable) — same as horizontal.

---

## Content Extent Measurement

During the layout/update pass, ScrollableContainer measures the Content node's bounding box after all children have been laid out. This gives `contentWidth` and `contentHeight` — the total scrollable area dimensions.

Valid scroll offset ranges:
- `scrollX` clamped to `[0, max(0, contentWidth - viewportWidth)]`
- `scrollY` clamped to `[0, max(0, contentHeight - viewportHeight)]`

After each frame's update, offsets are clamped unless `overscroll = true` is active and the container is in the dragging or inertial state.

---

## State Machine

**States:** `idle`, `dragging`, `inertial`.

### Idle state
Entry: initial state; also entered from dragging (no momentum) and from inertial (velocity below stop threshold).

Behaviors in idle:
- Receives `ui.scroll` events (from wheel or keyboard scroll): adjusts the relevant offset by `scrollStep` (or a page amount for Page Up/Down) and clamps. Fires no state transition.
- Receives `ui.drag` with `dragPhase = "start"` on a pointer press inside the viewport: transitions to **dragging**. Records `_dragStartX`, `_dragStartY`, `_dragStartScrollX`, `_dragStartScrollY`.
- When focused, receives `ui.navigate` with direction keys and translates them to scroll steps (same as wheel).

### Dragging state
Entry: from idle on pointer press inside viewport.

Behaviors in dragging:
- Each `ui.drag` with `dragPhase = "move"`: compute the pointer displacement from `_dragStartX/Y`. Set the scroll offsets to `_dragStartScrollX - deltaX` and `_dragStartScrollY - deltaY` (inverted: drag downward scrolls content up). Clamp offsets unless `overscroll = true`, in which case allow overscroll displacement with rubber-band attenuation (displacement beyond the boundary is multiplied by a damping factor less than 1, e.g., 0.35).
- Maintain a velocity window: a circular buffer of the last N (e.g., 5) pointer-move deltas divided by their elapsed time. This is the estimated velocity.
- On `ui.drag` with `dragPhase = "end"`: if `momentum = false`, clamp offsets and transition to **idle**. If `momentum = true`, seed `_velocityX` and `_velocityY` from the velocity window average and transition to **inertial**.

### Inertial state
Entry: from dragging on pointer release with `momentum = true`.

Behaviors in inertial:
- Each `update(dt)`:
  - Integrate velocity into offsets: `scrollX += _velocityX * dt`, `scrollY += _velocityY * dt`.
  - Apply decay: `_velocityX *= momentumDecay ^ dt`. (Decay is applied per-frame as an exponential; `momentumDecay` is a per-second decay factor, typically 0.1–0.3.)
  - If `overscroll = false`: clamp offsets to valid range.
  - If `overscroll = true`: if the offset is outside the valid range, apply a spring-back force toward the boundary instead of hard clamping: `velocity += (clampedOffset - currentOffset) * springConstant * dt`.
  - If the magnitude of velocity falls below a stop threshold (e.g., 10 pixels/second for both axes combined), clamp offsets to valid range and transition to **idle**.
- Receives `ui.drag` with `dragPhase = "start"` (pointer press while coasting): immediately transitions to **dragging** (aborts inertia).

---

## Scroll Event Consumption

ScrollableContainer participates in the event propagation system via its `ui.scroll` listener registered in the capture phase. When a scroll event reaches the container:
1. Check which axes are enabled for the event's axis.
2. If the container has remaining scroll range in the relevant axis (i.e., offset is not already at the boundary in the scroll direction), consume the event by calling `stopPropagation()` and handling it.
3. If the container is already at the boundary in the scroll direction, do not consume; let the event continue to ancestor containers.

This implements nested scroll consumption: the inner container handles the event while it has remaining range; the outer container takes over at the boundary.

---

## Clipping

The Viewport uses `clipChildren = true`. The stencil/scissor dual path from Phase 1 applies. If the ScrollableContainer or any of its ancestors has non-zero world rotation, the stencil path is used for correct clipping. No special handling needed here beyond what Phase 1 established.

---

## Scrollbars

When `showScrollbars = true`, two optional scrollbar Drawables are visible. Each scrollbar:
- Is a thin rectangle positioned at the edge of the ScrollableContainer's bounds (outside the Viewport).
- Has a thumb sub-Drawable representing the visible portion of the content. Thumb size is proportional to `viewportSize / contentSize`. Thumb position is proportional to `scrollOffset / maxScrollOffset`.
- Updated every frame in the update pass from current scroll state.
- Scrollbars are non-interactive in Phase 6 (no drag-to-scroll on the scrollbar itself; that is a future enhancement if desired).

---

## Properties

- `scrollXEnabled` (default true) — allows horizontal scrolling.
- `scrollYEnabled` (default true) — allows vertical scrolling.
- `momentum` (default true) — enables inertial scrolling after drag release.
- `momentumDecay` (default 0.15) — per-second velocity decay factor for inertial state. Lower values = more coasting. Valid range: 0 (no decay) to 1 (instant stop).
- `overscroll` (default false) — allows content to be scrolled past its boundary with rubber-band spring-back.
- `scrollStep` (default 40) — pixel amount per scroll tick (wheel step or arrow key step).
- `showScrollbars` (default false) — renders the scrollbar Drawables.

---

## Consumer Child API

- `scrollableContainer:addContent(node)` — adds a node to the Content container (the scrollable area). This is the public API for adding children; consumers must not add children directly to the ScrollableContainer itself.
- `scrollableContainer:getContentContainer()` — returns the Content container reference, for cases where consumers need to add multiple children or set up a layout within the scrollable area.

---

## Test

**Location:** `test/phase6/`

**Navigation:** Left/right arrow keys switch screens. Chrome drawn with raw Love2D. Each screen shows a debug sidebar (raw Love2D text) reporting: current scrollX, scrollY, contentWidth, contentHeight, viewportWidth, viewportHeight, current state (idle/dragging/inertial), velocityX, velocityY.

**Screen 1 — Vertical scroll**
A vertical list of 50 items (colored rectangles with number labels) inside a ScrollableContainer sized to show 8 items at a time. `scrollYEnabled = true`, `scrollXEnabled = false`. Mouse wheel scrolls. Click and drag scrolls (no momentum). Arrow up/down scroll one step. The debug sidebar updates live. Demonstrates offset clamping at both ends (0 and max).

**Screen 2 — Horizontal scroll**
A horizontal row of 30 wide tiles in a ScrollableContainer sized to show 5 at a time. `scrollXEnabled = true`, `scrollYEnabled = false`. Mouse wheel horizontal axis scrolls (if present); otherwise Shift+wheel simulates horizontal. Left/right arrow keys scroll one step. Drag scrolls horizontally.

**Screen 3 — Both axes**
A large 20×20 grid in a scroll container showing a 5×5 window. Both axes enabled. Dragging in any direction scrolls the appropriate axis or both. Demonstrates correct 2D offset clamping. The debug sidebar shows both X and Y offsets.

**Screen 4 — Momentum and overscroll**
Two toggle buttons (raw Love2D): "Momentum: ON/OFF" and "Overscroll: ON/OFF". A vertical list of 50 items. With momentum on, a fast drag and release shows the list coasting and gradually stopping (inertial state visible in debug). With overscroll on, dragging past the top or bottom boundary shows rubber-band stretch and spring-back. All four combinations (momentum×overscroll) demonstrable.

**Screen 5 — Nested scroll**
An outer vertical ScrollableContainer (tall content) containing an inner horizontal ScrollableContainer (wide content) partway down. The inner container has limited horizontal content. Dragging horizontally while over the inner container: inner container consumes the drag while it has remaining horizontal range; past the boundary, the outer container takes over vertically (if the drag has a vertical component). A "Reached edge" label appears in the debug sidebar when the inner container is at its horizontal boundary.

**Screen 6 — Keyboard and scrollbar**
`showScrollbars = true`. A large list focused by clicking it. Arrow keys scroll by step amount. Page Up/Down scroll by viewport height. Home/End jump to start/end. The scrollbar thumbs update proportionally in real time. The debug sidebar confirms the scroll state matches the visual scrollbar position.

---

## Hard Failures in This Phase

- `addContent` called after the ScrollableContainer is destroyed must raise an error.
- Setting `momentumDecay` to a value outside the valid range (less than 0 or greater than 1) must raise an error at property-set time.
- Nesting a ScrollableContainer inside another without any content — both empty — must be valid and stable (no crash, no infinite loop in extent measurement).
- A ScrollableContainer with both `scrollXEnabled = false` and `scrollYEnabled = false` must be valid; it simply never scrolls. This is a degenerate but valid configuration.
