# Phase 2 — Runtime Hardening (Stage, Scene, Composer)

## Goals

Rewrite Stage, Scene, and Composer from scratch to implement the full spec lifecycle contracts. No new component types are introduced. No event system yet — this phase is purely about the runtime orchestration layer: two-pass enforcement, scene lifecycle hooks, transition interruption, and overlay stubs.

---

## Dependencies

Requires Phase 1 (Container, Drawable, Stage skeleton, Vec2, Matrix, Rectangle, Easing).

---

## Shared Utilities Introduced

### lib/ui/core/easing.lua (finalized here)
The easing utility from Phase 1 is used here for scene transitions. Ensure all transition types (fade, slide variants) reference functions from this module rather than inlining any math.

---

## Components

### lib/ui/scene/stage.lua (full rewrite)

**Two-pass enforcement**
Stage maintains a boolean flag `_updateRan` that is set to true at the end of `update(dt)` and cleared at the end of `draw()`. At the beginning of `draw()`, if `_updateRan` is false, Stage raises a hard error:

> "Stage.draw() called without a preceding Stage.update() in this frame. The two-pass contract requires update to complete before draw begins."

This enforces the spec's update-before-draw guarantee across all subsequent phases.

**Frame traversal**
- `update(dt)`: walks `baseSceneLayer` then `overlayLayer` (order does not matter for update). Resolves dirty transforms and, from Phase 3 onward, layout passes.
- `draw()`: draws `baseSceneLayer` first, then `overlayLayer`. This order ensures overlay always renders above the base scene regardless of z-order values.

**Input dispatch stub**
Stage provides a `deliverInput(rawEvent)` method that is a no-op in this phase. Love2D input callbacks wire into this stub starting Phase 4. Scene/Composer no longer forward input directly.

**Viewport and safe area**
- `getViewport()` returns a Rectangle of the current window dimensions.
- `getSafeArea()` calls `love.window.getSafeArea()` and returns the four inset values. Cached per frame (re-read at the start of each update pass).
- `love.resize` callback updates the cached viewport and triggers a layout dirty pass from Phase 3 onward. In Phase 2 it simply updates the cached rectangle.

---

### lib/ui/scene/scene.lua (full rewrite)

**Classification:** Runtime utility — screen-level subtree with explicit lifecycle hooks.

**Creation**
- `Scene.new(params)` constructs a Scene. The `params` table may contain any initial configuration. After construction the scene is not attached to the tree and receives no updates or draws.
- `Scene:onCreate(params)` — override hook called once immediately after construction. Used for one-time setup such as creating child nodes.

**Lifecycle phases**
Both `onEnter` and `onLeave` are called in three explicit phases to support transition coordination:

- `onEnter("before")` — called before the transition begins. The scene is about to become visible. Safe to prepare resources.
- `onEnter("running")` — called when the transition is actively playing (or immediately if no transition). The scene is visible.
- `onEnter("after")` — called after the transition completes. The scene is fully active and interactive.

- `onLeave("before")` — called before the outgoing transition begins. The scene is still active.
- `onLeave("running")` — called during the outgoing transition. The scene is partially visible.
- `onLeave("after")` — called after the transition completes. The scene is hidden and may be cached or destroyed.

All six hooks are optional overrides. The base implementation is a no-op.

**Visibility and update gating**
- `show()` — sets `visible = true`; the scene receives `update` and `draw` calls from Stage.
- `hide()` — sets `visible = false`; the scene is skipped by Stage traversal.
- Scenes receive update and draw calls only when `visible = true`. Composer controls visibility.

**Destruction**
- `Scene:destroy()` — removes all children from the scene's subtree, fires no lifecycle hooks, and severs the node from the tree. After destruction the scene must not be used.

**Update and draw**
- `Scene:update(dt)` — called by Stage during the update pass when visible. Recurses to children.
- `Scene:draw()` — called by Stage during the draw pass when visible. Recurses to children.

---

### lib/ui/scene/composer.lua (full rewrite)

**Classification:** Runtime utility — manages scene registration, activation, transitions, and overlay layer.

**Scene registration and caching**
- `Composer:register(name, sceneClass)` — associates a name with a Scene subclass. The scene instance is created lazily on first activation.
- `Composer:removeScene(name)` — destroys the cached instance if one exists; the next activation of that name creates a fresh instance.
- Scenes are mounted into `stage.baseSceneLayer` when active; dismounted (removed from the layer) on leave.

**Scene activation**
- `Composer:gotoScene(name, options)` — activates the named scene. If `name` is the currently active scene, the full lifecycle still fires (not a no-op).
- `options` may contain `transition` (a transition definition table) and `params` (passed to the incoming scene's `onCreate` if the scene has not been created yet).
- Lifecycle sequence for a non-interrupted transition:
  1. Current scene `onLeave("before")`
  2. Transition begins (if any); both scenes mounted and visible
  3. Current scene `onLeave("running")`; incoming scene `onEnter("before")` and `onEnter("running")`
  4. Transition completes
  5. Previous scene `onLeave("after")`; previous scene hidden/unmounted
  6. Incoming scene `onEnter("after")`

**Transition interruption**
- If `gotoScene` is called while a transition is in progress, the current incoming scene immediately becomes the new current scene (transition finalized instantly), and the new navigation begins from that point. The interrupted outgoing scene receives `onLeave("after")` immediately before the new transition starts.

**Overlay stubs**
- `Composer:showOverlay(name, options)` — stub; mounts the named scene into `stage.overlayLayer` and fires `onEnter` hooks. Fully wired in Phase 9 when Modal and Alert use it.
- `Composer:hideOverlay(name)` — stub; dismounts and fires `onLeave` hooks.

---

### lib/ui/scene/transitions.lua (full rewrite)

Transition definitions consumed by Composer. Each transition is a table with:
- `duration` — total transition time in seconds (0 means instant).
- `easing` — function name from `lib/ui/core/easing.lua` (default `smoothstep`).
- `update(progress, outCanvas, inCanvas, width, height)` — called each frame during the transition with a 0–1 progress value and Love2D Canvas objects containing the rendered output of each scene. Issues draw commands to composite them.

Built-in transitions:
- `fade` — crossfade: outgoing scene fades from 1 to 0, incoming from 0 to 1.
- `slideLeft` — incoming scene slides in from the right; outgoing slides off to the left.
- `slideRight` — incoming slides from left; outgoing slides off to the right.
- `slideUp` — incoming slides from bottom; outgoing slides off upward.
- `slideDown` — incoming slides from top; outgoing slides off downward.
- `slideFade` — combination of slideLeft and fade.

Transitions use the canvas pool from Phase 1's utility set (introduced alongside Phase 2 if the pool was deferred — it must exist before transitions run).

---

## Test

**Location:** `test/phase2/`

**Navigation:** Left/right arrow keys switch between the five screens. Chrome drawn with raw Love2D.

**Screen 1 — Lifecycle log**
Three scenes (A, B, C). Each scene displays a distinctive background color and its name. Every lifecycle hook call (scene name + hook name + phase) is appended to a scrollable log list rendered on the right side of the screen. Navigation buttons (raw Love2D rects + text) labeled "Go A", "Go B", "Go C" trigger `gotoScene`. The log makes it possible to verify the exact order: leave-before, leave-running, enter-before, enter-running, leave-after, enter-after.

**Screen 2 — Transition interruption**
One base scene. A "Go B (slow)" button starts a 2-second fade transition to Scene B. A "Go C (interrupt)" button is available and can be clicked during the transition. The log shows: A onLeave before, A onLeave running, B onEnter before, B onEnter running — then when interrupted — B onLeave after (fast), C onEnter sequence begins. The visual result is that C appears cleanly without any corrupted mid-transition state.

**Screen 3 — Overlay mounting**
A base scene with a colored background and some child Drawables. A key press calls `showOverlay("overlay")`, which mounts a semi-transparent dark rectangle over the entire screen via the overlay layer. A second key press calls `hideOverlay`. Demonstrates that the overlay always renders above the base scene without modifying the base scene's children.

**Screen 4 — Scene cache**
Scene B contains a counter label that increments every second via its update loop. Navigating away and back to B shows the counter has persisted (scene was cached). Pressing a "Destroy B" key calls `removeScene("B")`. Navigating back to B creates a fresh instance; the counter resets to zero.

**Screen 5 — Two-pass assertion**
Left half shows a green "UPDATE ✓" indicator each frame and a green "DRAW ✓" indicator. Right half has a "Trigger violation" button that, when pressed, calls `stage:draw()` directly without calling `stage:update()` first. The app catches the error and displays a red "TWO-PASS VIOLATION CAUGHT" message with the error text. The app remains interactive after catching the error (the test harness wraps the call in pcall).

---

## Hard Failures in This Phase

- `gotoScene` with an unregistered name must raise a hard error immediately (not silently fail or create a nil scene).
- A Scene subclass that errors inside an `onEnter` or `onLeave` hook must propagate the error to the Composer; transitions must not silently absorb lifecycle errors.
- `removeScene` on a name that has no cached instance must be a no-op (not an error).
- Calling `stage:draw()` without a prior `stage:update()` in the same frame must raise the two-pass violation error.
