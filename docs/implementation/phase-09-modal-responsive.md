# Phase 9 — Modal, Alert, and Responsive Rules

## Goals

Implement Modal and Alert controls, complete the overlay layer wiring through Composer, and finalize the responsive rules system (percentage sizing, min/max clamps, and declarative breakpoints wired end-to-end into the layout pass). After this phase, the library is feature-complete at v0.1.0.

---

## Dependencies

Requires Phase 8 (full theming system, canvas pool, all controls themed). Responsive rules build on Phase 3's BreakpointResolver and layout pass. Overlay layer wiring extends Phase 2's Composer stubs.

---

## Overlay Layer Wiring (Composer)

### lib/ui/scene/composer.lua (extended)

**`showOverlay(name, options)`** — fully implemented:
1. Retrieve or create the named scene (same caching as `gotoScene`).
2. Mount the scene into `stage.overlayLayer`.
3. Fire the full scene lifecycle: `onEnter("before")`, `onEnter("running")`, `onEnter("after")`.
4. The overlay scene is assigned a `zIndex` within the overlay layer. Multiple overlays can coexist; each gets the next available zIndex (incrementing).

**`hideOverlay(name)`** — fully implemented:
1. Fire `onLeave("before")`, `onLeave("running")`, `onLeave("after")`.
2. Unmount the scene from `stage.overlayLayer`.
3. The overlay's zIndex slot is released for future overlays.

**Multiple overlays:**
Overlays stack. Each occupies a distinct zIndex position in the overlay layer. Hit testing and event dispatch check the overlay layer in descending zIndex order — the topmost (highest zIndex) overlay receives events first. A lower overlay does not receive events while a higher overlay is mounted and hit-testable.

---

## Controls

### lib/ui/controls/modal.lua

**Classification:** Composite control — blocking overlay with focus trapping.

**Parts:** `root` (the full overlay node, mounted in the overlay layer), `backdrop` (full-screen Drawable blocking input to underlying content), `surface` (the centered or consumer-positioned content area), `content` (the consumer-provided slot inside the surface).

**Structure**
Modal is not added to the tree as a regular child. Instead:
- `modal:open()` — calls `Composer:showOverlay` with a dedicated single-scene wrapper. This mounts the modal into the overlay layer.
- `modal:close()` — calls `Composer:hideOverlay` to remove it.

The `backdrop` fills the entire Stage viewport. Its `interactive = true` so it blocks pointer events from reaching the base scene layer and the lower z-index overlays. Clicking the backdrop fires `ui.dismiss` on the backdrop itself.

The `surface` is centered within the Stage viewport by default. Its position can be overridden by consumer props. The surface is a Drawable with `focusScope = true` and `trapFocus = true`.

**Lifecycle**
On open:
1. Stage records the current `_focusOwner` into the focus trap history.
2. The surface's `trapFocus` activates, pushing the focus scope onto the trap stack.
3. Focus is moved to the first sequential candidate within the surface (or the surface root if no candidates).

On close:
1. `ui.focus.change` fires as the trap scope deactivates and focus restores.
2. The previously focused node (recorded before the modal opened) receives focus.
3. The modal's nodes are unmounted from the overlay layer.

**Backdrop dismiss**
When the backdrop receives `ui.activate` (pointer click) or the `ui.dismiss` event fires while Modal is the active scope:
- If `dismissible = true` (default): Modal proposes `onOpenChange(false)`.
- If `dismissible = false`: the event is consumed by the backdrop and nothing happens.

**Controlled mode:** `open` prop + `onOpenChange(newValue)` callback.
**Uncontrolled mode:** library owns `open` state. Use `modal:open()` and `modal:close()` methods.

**Properties**
- `open` — boolean (controlled). Nil = uncontrolled.
- `onOpenChange(newValue)` — callback.
- `dismissible` — boolean (default true). Whether clicking the backdrop or pressing Escape closes the modal.
- `backdropDismiss` — boolean (default true). Whether clicking the backdrop proposes dismissal. When false, the backdrop still blocks events but does not close the modal.

---

### lib/ui/controls/alert.lua

**Classification:** Composite control — alert dialog. Specialized Modal.

**Parts:** inherits Modal parts plus `title` (required Text slot), `message` (optional Text slot), `actions` (required Container with at least one Button child).

**Structure**
Alert is a restricted Modal. The surface layout is managed by the library:
- `title` is displayed at the top of the surface.
- `message` (if provided) is displayed below the title.
- `actions` is displayed at the bottom of the surface. Consumer provides the action Buttons; the library manages the actions Container.

**Initial focus**
When Alert opens, focus is set to the first action button in the `actions` container (not the first generic focusable node). This is enforced by the Alert's open lifecycle — it walks the actions container to find the first focusable Button and calls `stage:requestFocus` on it.

**Hard failure conditions**
- `actions` must contain at least one Button-like node (any node with `focusable = true` and `onActivate` set). If zero action nodes are found at open time, Alert raises a hard error.
- `title` must be a non-empty string or a provided Text node. An empty title is a hard failure.

**Constructor**
`Alert.new({ title, message, actions, onOpenChange, dismissible })`:
- `title` — string or Text node.
- `message` — string, Text node, or nil.
- `actions` — list of Button nodes. Each Button's `onActivate` callback is the consumer's responsibility.
- `onOpenChange`, `dismissible` — same as Modal.

**Properties** — same as Modal plus:
- `title` — string or node (required).
- `message` — string or node (optional).

---

## Responsive Rules (Complete)

### Percentage sizing (finalized)
In Phase 3, `resolveSize` was introduced but may not have been fully integrated in all layout pass paths. In Phase 9, all layout families (Row, Column, Flow, Stack, SafeAreaContainer) and the base Container `update()` call `resolveSize` for both width and height before any placement occurs. No layout node may skip percentage resolution.

### Min/max clamps (finalized)
Applied by `resolveSize` after percentage resolution. This was partially present; Phase 9 ensures it is applied consistently by all layout nodes including those that produce "fill" and "content" sizes.

### Breakpoint responsive (finalized)
Phase 3 introduced BreakpointResolver as a utility. In Phase 9, the integration is complete:
1. At the start of Stage's update pass, Stage re-evaluates the current breakpoint for each registered node by comparing the viewport dimensions to each node's `breakpoints` table.
2. When the active breakpoint changes for a node (viewport crossed a threshold since the last frame), the node is marked dirty and its breakpoint overrides are re-applied to its effective property set.
3. Because breakpoints can change child counts or layout configuration, the layout pass runs after all breakpoint re-evaluations.

SafeAreaContainer uses percentage sizing against the safe-area content box. Children inside a SafeAreaContainer that use `"100%"` width or height resolve against the safe-area-inset content box dimensions, not the raw viewport.

---

## Test

**Location:** `test/phase9/`

**Navigation:** Left/right arrow keys switch screens. Chrome drawn with raw Love2D.

**Screen 1 — Modal open/close**
A Button labeled "Open Modal" in the center of the screen. Clicking it opens a Modal with:
- A title: "Confirm action".
- Body text: "Are you sure you want to proceed?".
- Two action Buttons: "Confirm" (logs "confirmed") and "Cancel" (closes the modal).
Tab moves focus between Confirm and Cancel. Space/Enter activates the focused button. Escape closes the modal (`dismissible = true`). When the modal closes, focus returns to the "Open Modal" button. A log panel on the side shows each focus change and action event.

**Screen 2 — Focus trap**
Same modal as Screen 1. While the modal is open:
- Pressing Tab and Shift+Tab only cycles between the two action buttons.
- Arrow keys stay within the modal surface.
- Clicking outside the modal's surface (on the backdrop): fires `ui.dismiss`, modal closes via `onOpenChange(false)`, focus returns to base scene.
- Clicking while `backdropDismiss = false` (a toggle key): backdrop absorbs the click but modal stays open.
- The base scene has several focusable boxes that must remain unreachable while the modal is open; a "focus leaked to base scene" warning label appears if any base scene node receives focus.

**Screen 3 — Alert**
A Button labeled "Delete item". Clicking it opens an Alert:
- Title: "Delete item?"
- Message: "This action cannot be undone."
- Two action Buttons: "Delete" (logs "deleted" and closes) and "Cancel" (closes).
Initial focus is on the "Delete" button, not the "Cancel" button or the title text. Escape dismisses. Tab cycles between Delete and Cancel. A "No-close Alert" toggle opens an Alert with `dismissible = false` — Escape and backdrop click are both inert.

**Screen 4 — Stacked overlays**
A base scene. A Button opens Modal A. Inside Modal A, a Button opens Modal B. While Modal B is open:
- Tab and focus are restricted to Modal B.
- Base scene and Modal A are unreachable.
Closing Modal B: focus returns to the button inside Modal A that opened it. Modal A becomes fully active and focus-trapped again. Closing Modal A: focus returns to the button in the base scene that opened Modal A.
A focus log shows each `ui.focus.change` with previousTarget and nextTarget, confirming the correct restoration chain.

**Screen 5 — Percentage sizing**
A Column filling the full window. It contains five child Drawables:
- 25% width.
- 50% width.
- 75% width.
- 100% width.
- 50% width with `minWidth = 120` and `maxWidth = 400`.
Resizing the window (drag the OS window corner) shows all children reflowing proportionally in real time. The fifth child demonstrates clamping: at small window sizes it hits the minWidth floor; at large sizes it hits the maxWidth ceiling. Each child displays its resolved pixel width numerically.

**Screen 6 — Breakpoint responsive**
A full-screen layout using a Column of Rows. Three defined breakpoints:
- Small: viewport width < 600.
- Medium: viewport width 600–900.
- Large: viewport width > 900.

At Small, the layout is a single-column list (one Row per item). At Medium, a two-column Row grid. At Large, a three-column Row grid. The active breakpoint name is shown in a debug strip at the bottom along with the current viewport width. Resizing the window crosses the thresholds live. A counter in the strip shows how many times layout was triggered by a breakpoint change since the test loaded.

---

## Hard Failures in This Phase

- Opening Modal while another Modal is already fully open must work correctly (stacked overlays); it must not raise an error or produce duplicate overlay layer entries.
- An Alert constructed with zero action buttons must raise a hard error at open time identifying "Alert requires at least one action node."
- An Alert with an empty title string must raise a hard error at construction time: "Alert title must be a non-empty string or a content node."
- Calling `modal:close()` on a Modal that is not currently open must be a no-op (not an error).
- `showOverlay` with an unregistered scene name must raise a hard error (same behavior as `gotoScene`).
- Percentage sizing against a parent with zero content-box size must resolve to 0, not NaN or a crash.
