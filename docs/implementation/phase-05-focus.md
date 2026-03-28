# Phase 5 — Focus System

## Goals

Implement the full logical focus model: focus scopes, sequential traversal, directional traversal, pointer-focus coupling, focus trapping, and the `ui.focus.change` event. After this phase, all keyboard navigation and focus ring rendering are functional. Controls built in Phase 7 depend on this system for accessibility and keyboard interaction.

---

## Dependencies

Requires Phase 4 (Event system, propagation pipeline, Navigate/Dismiss/Activate event delivery, hover tracking, Stage as input root).

---

## Focus State Location

Focus state is stored on Stage, not on individual nodes. Stage holds:
- `_focusOwner` — reference to the currently focused node, or nil.
- `_focusScopeStack` — ordered list of active focus scopes from root to innermost. The last entry is the currently active (innermost) scope.
- `_trapStack` — ordered list of active focus traps. The last entry is the innermost active trap.
- `_preTrapFocusHistory` — stack of focus owners recorded before each trap was activated, for restoration on trap close.

Nodes do not store their own `focused` boolean. The `focused` derived flag is computed during the draw pass: when Stage draws a node, if that node reference equals `_focusOwner`, it sets `focused = true` on the node before calling its `draw()`. After draw, it resets the flag. This ensures no stale `focused=true` values persist on reparented or destroyed nodes.

---

## Focus Scope Model

**What is a focus scope?**
A focus scope is a Container with `focusScope = true`. It defines the boundary within which sequential and directional traversal operate. The root focus scope is Stage itself. Nested focus scopes create sub-boundaries.

**Active scope chain**
The active scope chain is the ordered list of open focus scopes from Stage root to the innermost active scope. An overlay scope (from Modal or Alert in Phase 9) is pushed onto the chain when it opens.

**Scope rules**
- Sequential and directional traversal candidates are drawn only from the currently active (innermost) scope.
- A node is a valid focus candidate only if it is `focusable=true`, `enabled=true`, `visible=true`, and is a descendant of the currently active scope.
- If the active scope has no focusable candidates, traversal wraps without moving focus. No error.

---

## Sequential Traversal

Triggered by `ui.navigate` with `navigationMode = "sequential"` and `direction = "next"` or `"previous"`.

**Algorithm**
1. Collect all focusable candidates within the active scope: depth-first pre-order traversal of the scope's subtree, filtering for `focusable=true, enabled=true, visible=true`.
2. Find the index of the current `_focusOwner` in the list. If `_focusOwner` is nil or not in the list, use index 0 for "next" and (list length + 1) for "previous".
3. For "next": advance to index + 1; wrap to 1 if past the end.
4. For "previous": advance to index − 1; wrap to the end if before 1.
5. Call `stage:requestFocus(candidate)`.

---

## Directional Traversal

Triggered by `ui.navigate` with `navigationMode = "directional"` and `direction = "up"`, `"down"`, `"left"`, or `"right"`.

**Algorithm**
1. Collect all focusable candidates within the active scope (same filter as sequential).
2. Remove the current `_focusOwner` from the candidate list.
3. For each remaining candidate, compute the displacement vector from the center of `_focusOwner`'s world bounds to the center of the candidate's world bounds.
4. Discard candidates whose primary displacement axis does not match the requested direction. (For "right", keep candidates with positive X displacement that is larger in magnitude than their Y displacement.)
5. Among remaining candidates, sort by distance (Euclidean between centers). Ties broken by stable tree order (depth-first pre-order index).
6. If no candidates remain after filtering, directional movement is a no-op (no focus change).
7. Call `stage:requestFocus(bestCandidate)`.

---

## Focus Acquisition API

**`stage:requestFocus(node)`**
Explicit focus request. If `node` is nil, focus is cleared. If `node` is not focusable or not eligible (disabled, invisible, not in active scope), the request is silently ignored. Otherwise:
1. Record the previous focus owner.
2. Set `_focusOwner = node`.
3. Dispatch `ui.focus.change` event (non-cancellable, target-only delivery to the new owner). Payload: `previousTarget` and `nextTarget`.

**Pointer-focus coupling**
When Stage dispatches `ui.activate` from a pointer source (mouse or touch), before propagation begins:
- If the hit node has `pointerFocusCoupling = "before"` and is focusable and enabled: call `stage:requestFocus(hitNode)`.
- The focus change (and `ui.focus.change` event) fires before the `ui.activate` event propagation.
- If the hit node does not have `pointerFocusCoupling = "before"`, focus does not change on pointer activation.

**Keyboard activation**
When Stage dispatches `ui.activate` from a keyboard source (Space or Enter while a control is focused):
- The target of the event is `_focusOwner`.
- Focus does not change as part of keyboard activation.

---

## Focus Trapping

**Activation**
When a Container with `trapFocus = true` and `focusScope = true` becomes active (added to the tree while visible, or made visible), Stage:
1. Records the current `_focusOwner` onto `_preTrapFocusHistory`.
2. Pushes the trap scope onto `_trapStack` and onto `_focusScopeStack`.
3. Moves focus to the first sequential candidate within the trap scope (or the trap scope root if no candidates exist).

**Deactivation**
When the trap scope is destroyed or hidden:
1. The trap is popped from `_trapStack` and `_focusScopeStack`.
2. The recorded pre-trap focus owner is popped from `_preTrapFocusHistory` and `stage:requestFocus()` is called with it (if it is still in the tree and eligible). If not eligible, focus is cleared.

**During active trap**
- Sequential and directional traversal operate only within the trap scope.
- `ui.navigate` events targeting nodes outside the trap are consumed by Stage without delivery (the outer nodes never see them).
- Pointer activation on nodes outside the trap scope is discarded by Stage before hit testing; the backdrop (for Modal) absorbs the pointer event.

---

## `ui.focus.change` Event

- Type: `"ui.focus.change"`.
- Not cancellable — `preventDefault()` has no effect.
- Phase: target only (not captured, not bubbled).
- Delivery target: the new focus owner (`nextTarget`).
- Fires after the focus commit, not before.
- Payload fields: `previousTarget` (may be nil), `nextTarget` (the new owner, same as `target`).

---

## Focus Indicator Protocol

In Phase 5, the base Drawable's `draw()` is updated to check its derived `focused` flag. When `focused = true`, a simple visible ring is drawn: a 2-pixel white rectangle outline offset 2px outside the node's bounds. This is the default focus indicator; controls in Phase 8 will replace it with their skin variant's focus-state appearance.

---

## Container Properties Added in This Phase

- `pointerFocusCoupling` — nil (no coupling, default) or `"before"` (focus before activation default action).
- `focusScope` — boolean (default false); marks this node as defining a nested focus scope.
- `trapFocus` — boolean (default false); when true and `focusScope = true`, activates focus trapping when this node enters the tree while visible.

---

## Test

**Location:** `test/phase5/`

**Navigation:** Left/right arrow keys switch screens (using raw Love2D, not the library's Navigate event). The test harness calls `love.keypressed` without routing through Stage for the screen-switch keys to avoid interference with the focus test scenarios.

**Screen 1 — Sequential traversal**
Eight labeled Drawables arranged in a 4×2 grid, all `focusable=true`. They are added to the tree in reading order (left-to-right, top-to-bottom). Tab cycles through them forward; Shift+Tab cycles backward. The focused Drawable shows the default focus ring (white outline). A counter at the top shows the current focus index in the traversal list and confirms it matches reading order.

**Screen 2 — Directional traversal**
Same eight Drawables but laid out with spatial gaps so directionality is unambiguous. Arrow keys navigate. At the rightmost Drawable in a row, pressing Right moves to the Drawable in the same row one row below (nearest in the right direction if available) or does nothing if none. Demonstrates the nearest-center distance algorithm. Current focus shown by the ring.

**Screen 3 — Focus trap**
A main area with four focusable boxes. A centered "popup" Container with a `trapFocus = true` scope containing three focusable boxes. Space key toggles the popup visible/hidden. While visible: Tab and arrow keys reach only the popup's three boxes; clicking outside the popup shows no focus change; pressing Escape hides the popup and restores the previously focused main-area box. A log panel shows each `ui.focus.change` event with previous and next targets.

**Screen 4 — Pointer-focus coupling**
Six Drawables in two rows. Top row: `pointerFocusCoupling = "before"`. Bottom row: no coupling. Clicking a top-row Drawable moves focus to it (ring appears) before the activate default action fires. Clicking a bottom-row Drawable does not move focus; the ring stays on the last keyboard-focused node. The activate default action still fires (color toggle) for both rows. Log shows whether focus changed per click.

**Screen 5 — Focus change log**
All five traversal and acquisition paths exercised: sequential Tab, directional arrow, pointer coupling (click), explicit `requestFocus` (a button calls it for a specified target), and trap open/restore. Every `ui.focus.change` event is logged with previousTarget tag and nextTarget tag. The log clearly distinguishes all five paths by showing the source in the entry.

---

## Hard Failures in This Phase

- `requestFocus` on a node that is not in the retained tree (not attached to Stage via any ancestor chain) must be silently ignored. Not an error.
- `requestFocus` on a node that is in the tree but has `focusable = false` must be silently ignored.
- Destroying the currently focused node (via `destroy()`) must clear `_focusOwner` on Stage automatically. Stage must not hold a dangling reference to a destroyed node. This requires Container's `destroy()` to notify Stage if the destroyed node was the focus owner.
- Stacking two focus traps and then closing the inner one must restore focus to the node that was focused before the inner trap opened — not before the outer trap opened.
