# Phase 4 — Event System

## Goals

Introduce the three-phase event propagation pipeline, the logical input translation layer, hit testing with z-order awareness, and hover tracking. After this phase, every node in the tree can participate in structured input handling without touching Love2D APIs directly. Stage becomes the single entry point for all platform input.

---

## Dependencies

Requires Phase 3 (Layout families, Container with hitTest, Stage two-pass model, BreakpointResolver).

---

## Shared Utilities Introduced

### lib/ui/event/event.lua

The event object type shared by all propagation. Fields:

**Core propagation fields (all events)**
- `type` — string name of the event (e.g., "ui.activate", "ui.scroll").
- `phase` — "capture", "target", or "bubble". Set by the dispatcher as propagation advances.
- `target` — the node that is the ultimate recipient (the deepest hit node for spatial events, the focused node for logical events).
- `currentTarget` — the node whose listener is currently being called. Changes as propagation walks the path.
- `path` — ordered list of nodes from Stage root to the target, inclusive.
- `timestamp` — time in seconds (from love.timer.getTime()) at the moment the raw input was received.
- `defaultPrevented` — boolean, initially false.
- `propagationStopped` — boolean, initially false. Set by `stopPropagation()`.
- `immediatePropagationStopped` — boolean, initially false. Set by `stopImmediatePropagation()`.

**Spatial event fields** (pointer events: Activate from pointer, drag events, hover)
- `pointerType` — "mouse" or "touch".
- `x`, `y` — position in Stage (world) space.
- `localX`, `localY` — position in `currentTarget`'s local space. Recalculated as `currentTarget` changes during propagation.
- `button` — pointer button index (mouse) or touch ID (touch).

**Navigate event fields**
- `direction` — "up", "down", "left", "right", "next", "previous". "next" and "previous" correspond to Tab/Shift+Tab sequential mode.
- `navigationMode` — "sequential" (Tab traversal) or "directional" (arrow keys).

**Scroll event fields**
- `deltaX`, `deltaY` — scroll deltas in pixels. Positive deltaY means scroll down (content moves up).
- `axis` — "vertical", "horizontal", or "both".

**Drag event fields**
- `dragPhase` — "start", "move", or "end".
- `originX`, `originY` — position where the drag began, in Stage space.
- `deltaX`, `deltaY` — cumulative movement from origin.

**Text event fields** (TextInput and TextCompose)
- `text` — the committed or candidate text string.
- `rangeStart`, `rangeEnd` — for TextCompose events, the byte range of the composition candidate within the active text field. Not used by TextInput events.

**Focus change event fields**
- `previousTarget` — the node that previously owned focus, or nil if none.
- `nextTarget` — the node that will own focus after this event.

**Methods**
- `stopPropagation()` — sets `propagationStopped = true`. After the current listener returns, no further listeners on subsequent nodes in the path fire. The current node's remaining listeners still fire.
- `stopImmediatePropagation()` — sets both `propagationStopped` and `immediatePropagationStopped = true`. No further listeners fire, including remaining listeners on the current node.
- `preventDefault()` — sets `defaultPrevented = true`. The component's default action does not execute after propagation completes, but propagation itself continues.

---

## Stage Input Dispatch

### lib/ui/scene/stage.lua (extended)

**Single entry point**
All Love2D input callbacks are forwarded to `stage:deliverInput(rawEvent)`. No Scene or component reads Love2D state directly. The raw event table is a simple Lua table created by the test harness or the main love callbacks with a `kind` field indicating the Love2D event type, plus any relevant fields (x, y, button, key, scancode, text, etc.).

**Translation to logical intents**

| Raw Love2D event | Conditions | Logical intent |
|---|---|---|
| mousepressed / touchpressed | — | Activate (spatial, on pointer press); Drag start deferred until movement detected |
| mousereleased / touchreleased | No drag started | Activate (spatial, on release, confirmed click) |
| mousereleased / touchreleased | Drag was active | Drag end |
| mousemoved / touchmoved | Button held + moved beyond drag threshold | Drag start, then Drag move |
| mousemoved / touchmoved | No button held | Hover (pointer-enter/pointer-leave synthetic; no propagation event dispatched, just state update) |
| wheelmoved | — | Scroll (deltaX, deltaY, axis derived from which delta is larger) |
| keypressed | key = "tab", shift not held | Navigate (direction="next", mode="sequential") |
| keypressed | key = "tab", shift held | Navigate (direction="previous", mode="sequential") |
| keypressed | key in {up, down, left, right} | Navigate (direction from key, mode="directional") |
| keypressed | key = "escape" | Dismiss |
| keypressed | key = "return" or "kpenter" | Submit |
| keypressed | key in {pageup, pagedown, home, end} | Scroll (step or page amounts, vertical) |
| keypressed | key = "space" while a focusable control is focused | Activate (non-spatial, keyboard origin) |
| textinput | — | TextInput |
| textedited | — | TextCompose |

The drag threshold is 4 pixels of movement before a Drag start fires. Within the threshold, pointer-move events are buffered but no Drag events dispatch. This prevents accidental drags from clicks.

**Hit testing for spatial events**
1. Walk `overlayLayer` children in descending zIndex order (highest first), recursing into each; find the deepest node that passes `interactive=true, enabled=true, visible=true, containsPoint(wx,wy)`.
2. If no hit in the overlay layer, walk `baseSceneLayer` the same way.
3. The first result is the target. The path is built as the ancestor chain from Stage root to the target (inclusive on both ends).
4. If no node is hit, the event is dropped silently. No propagation occurs.

**Propagation pipeline**
1. **Capture phase**: walk `path` from index 1 (root) to the second-to-last entry (parent of target). For each node, call all capture-phase listeners for this event type. If `propagationStopped = true` after any listener, stop immediately.
2. **Target phase**: call all listeners (capture and bubble) on the target node. If `immediatePropagationStopped = true` after any listener, stop immediately within the target phase.
3. **Bubble phase**: walk `path` from the second-to-last entry back to index 1. For each node, call all bubble-phase listeners. If `propagationStopped = true` after any listener, stop.
4. **Default action**: if `defaultPrevented = false`, the component's registered default action executes. The default action is a function registered by the component itself (not a listener; it runs exactly once per event).
5. **Focus change** (Navigate and Activate events only): if focus changed as a result of the default action, `ui.focus.change` fires after the default action completes.

**Logical events for Navigate and Dismiss**
These are not spatial; no hit testing. The target is the currently focused node. If no node owns focus, Dismiss and Navigate are delivered to Stage itself (which may have a default dismiss handler).

**Hover tracking**
During `mousemoved` with no button held, Stage resolves the current hit node and compares to the previously tracked hover node. If different:
- The previous hover node (if any) has its `hovered` flag cleared and a synthetic `ui.pointer-leave` internal notification dispatched (not a named event; used internally by controls for state machines).
- The new hover node has its `hovered` flag set and a synthetic `ui.pointer-enter` internal notification dispatched.
`hovered` is a derived interaction-state flag on Container, readable by controls.

**Listener API on Container**
- `node:on(eventType, fn)` — registers a listener that fires on both target and bubble phases. When called during capture phase, does not fire.
- `node:off(eventType, fn)` — removes a previously registered listener.
- `node:capture(eventType, fn)` — registers a listener that fires only during the capture phase.
- `node:bubble(eventType, fn)` — registers a listener that fires only during the bubble phase (and target phase).
- Listeners are called in registration order. Multiple listeners for the same event type on the same node fire in registration order.
- Listeners added or removed during active propagation take effect on the next event delivery, not the current one.

**Named events dispatched in this phase**
- `ui.activate`
- `ui.navigate`
- `ui.dismiss`
- `ui.scroll`
- `ui.drag`

Text events (`ui.text.input`, `ui.text.compose`) and focus events (`ui.focus.change`) arrive in Phase 5.

---

## Test

**Location:** `test/phase4/`

**Navigation:** Left/right arrow keys switch screens. Chrome drawn with raw Love2D. Each screen uses event logging — a scrollable panel (raw Love2D) showing the last 20 event entries.

**Screen 1 — Capture, target, bubble log**
Three nested Drawables: Outer (200×200), Middle (140×140, centered inside Outer), Inner (80×80, centered inside Middle). Each registers listeners on all three phases for `ui.activate`. Clicking anywhere inside Inner shows three capture entries (Outer-capture, Middle-capture, Inner-capture), then three target/bubble entries (Inner-target, Middle-bubble, Outer-bubble). A checkbox labeled "Stop at Middle bubble" calls `stopPropagation()` in Middle's bubble listener; the log shows the truncated path.

**Screen 2 — preventDefault**
A single Drawable labeled "Color Changer". Its default action for `ui.activate` flips its background color between two values. A checkbox labeled "Prevent default" calls `preventDefault()` when checked. Clicking while prevention is active shows: all listeners still fire and are logged, but the color does not change. Clicking while prevention is inactive shows the color changing.

**Screen 3 — Overlay precedence**
Three base scene Drawables in a row, and two overlay Drawables positioned to overlap the first and third base scene Drawables. Clicking the overlap regions logs the target as the overlay node. A key labeled "H" hides the overlay layer (sets overlay children to `visible=false`); clicking the same regions now logs the base scene nodes as targets. Key H toggles visibility back.

**Screen 4 — Hit test z-order**
Four sibling Drawables at the same (x, y) position with zIndex values 1–4. Clicking the stack always logs the node with zIndex 4 as the target (topmost). Number keys 1–4 move that node's zIndex to 0 (sending it to the bottom), making the next-highest node the target. The log entry shows the target node's zIndex each time.

**Screen 5 — Navigate and dismiss**
A single Drawable in the center of the screen, set as the current focus owner via `stage:requestFocus()` (introduced in Phase 5 but stubbed here). Arrow key presses fire `ui.navigate` events; the log shows each event's direction and navigationMode. Escape fires `ui.dismiss`; the Drawable "closes" (hides itself) and logs the dismissal. A "Reopen" button (raw Love2D) resets visibility.

**Screen 6 — Scroll and drag**
Left half: a Drawable labeled "Scroll target"; mouse wheel over it logs `ui.scroll` events with deltaX, deltaY, and axis. Right half: a movable Drawable. Pressing and dragging it logs `ui.drag` events with dragPhase (start/move/end), originX/Y, and cumulative deltaX/deltaY. The drag threshold (4px) is visible: events only start after the pointer moves 4px from the press origin.

---

## Hard Failures in This Phase

- A listener that throws a Lua error during propagation must propagate that error upward and halt the current event delivery. Propagation must not silently swallow errors.
- Delivering an event with an unrecognized type string is valid; it propagates normally. No hard failure.
- A rawEvent with no valid target (no hit node found) must be silently dropped — not an error.
- Registering the same listener function twice for the same event type on the same node must result in it being called twice per event (no de-duplication). This matches the standard DOM behavior and simplifies the implementation.
