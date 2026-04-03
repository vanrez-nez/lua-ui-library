# Phase 1 — Core Foundation

## Goals

Establish the primitive building blocks that every subsequent phase depends on. Write Container and Drawable from scratch, establish the two-path clipping system (scissor for non-rotated, stencil for rotated), and give Stage its structural slots. No event system yet — just the retained tree, transforms, visibility, z-order, and content-box model.

---

## Shared Utilities Introduced

### lib/ui/core/vec2.lua
Two-dimensional value type. Supports addition, subtraction, scalar multiplication, negation, equality, length, normalization, lerp, dot product, and distance. No mutable state — operations always return new values.

### lib/ui/core/matrix.lua
Affine transform stored as six scalars (a, b, c, d, tx, ty). Supports composition (multiply two matrices), point transformation, inverse, and construction from position/rotation/scale/skew inputs. Used for local-to-world and world-to-local conversions throughout the tree.

### lib/ui/core/rectangle.lua
Axis-aligned bounding rectangle (x, y, width, height). Supports inset, expand, union, intersection, contains-point, and four-corner extraction. Used for content boxes, clip regions, AABB queries, and canvas size calculation.

### lib/ui/core/insets.lua
Normalizes padding and margin inputs into a consistent four-value table (top, right, bottom, left). Accepts a single scalar (all sides equal), a two-value pair (vertical, horizontal), or a four-value table. Shared by Container, Drawable, all layout families, and SafeAreaContainer so no component duplicates this logic.

### lib/ui/core/color.lua
Small helpers: multiply an RGBA table by an alpha scalar, blend two RGBA tables, resolve a color token to a normalized RGBA tuple (handles both {r,g,b,a} tables and packed hex integers). Used by theming and skin rendering from Phase 8 onward, but introduced here so later phases can depend on it without circular imports.

### lib/ui/core/easing.lua
Collection of easing functions: linear, smoothstep, easeInQuad, easeOutQuad, easeInOutQuad, easeOutCubic, easeOutExpo. Each takes a progress value between 0 and 1 and returns a transformed value in the same range. Replaces the inlined smoothstep in Composer and will be used by transitions, inertial scroll decay, and Switch thumb animation.

---

## Components

### lib/ui/core/container.lua

**Classification:** Primitive — structural node, no visual output.

**Identity and tree membership**
- Every `Container` has a stable object identity for its lifetime, but the authoritative public contract now also includes per-node `id`, `name`, and `tag` plus subtree lookup semantics. This planning document no longer defines the public identity contract; `docs/spec/ui-foundation-spec.md §6.1.1` does.
- A Container may have zero or one parent. Adding it to a new parent removes it from its previous parent.
- `addChild(node)`, `removeChild(node)`, `getChildren()` — manages the ordered child list.
- `destroy()` — severs tree membership for this node and all descendants; after this call the node must not be added to any tree.
- Implementation planning should assume cached attachment-root references and an internal root-level `id` index are acceptable implementation details, while tag indexing remains deferred.

**Transform**
- Local transform inputs: `x`, `y` (position), `scaleX`, `scaleY`, `rotation` (radians), `skewX`, `skewY`, `anchorX`, `anchorY` (0–1 normalized position within parent content box), `pivotX`, `pivotY` (0–1 normalized rotation/scale center within own bounds).
- Computed from inputs into a local Matrix on each update cycle when dirty.
- World transform is the composition of all ancestor local transforms down to this node.
- `getWorldTransform()` — returns the composed Matrix.
- `worldToLocal(wx, wy)` and `localToWorld(lx, ly)` — coordinate conversions using the world matrix.

**Dirty propagation**
- Any change to a transform input marks the node dirty and propagates dirtiness up to all layout-family ancestors that need to re-measure.
- Dirty state is resolved during the Stage update pass before the draw pass.

**Visibility and z-order**
- `visible` boolean — when false, the node and all descendants are skipped for update, draw, and hit testing.
- `zIndex` integer (default 0) — siblings are drawn in ascending zIndex order; ties broken by stable insertion order.
- When zIndex on any child changes, the parent's child list is re-sorted immediately.

**Size and clamps**
- `width`, `height` — configured size. In Phase 1 these are absolute pixel values. Layout-managed nodes will have these overwritten by their parent layout node in Phase 3.
- `minWidth`, `maxWidth`, `minHeight`, `maxHeight` — applied as clamps after the configured size (or layout-assigned size) is resolved. Nil means no clamp.

**Flags**
- `interactive` (default true) — when false, the node is excluded from hit testing and never becomes a propagation target.
- `enabled` (default true) — when false, the node participates in hit testing for parent routing purposes but cannot become a target itself; it propagates through to children.
- `focusable` (default false) — marks this node as eligible to own logical focus. Consumed by the focus system in Phase 5.
- `clipChildren` (default false) — when true, activates the clipping dual path described below.
- `focusScope` (default false) — consumed by Phase 5.
- `trapFocus` (default false) — consumed by Phase 5.

**Clipping dual path**
When `clipChildren = true`:
- If world rotation is zero (or negligibly small): apply a Love2D scissor rectangle matching the node's world AABB during the draw traversal of children. Restore the previous scissor after.
- If world rotation is non-zero: write the node's four world-space corners as a polygon into the stencil buffer. Draw children with the stencil test active (pass where stencil equals the current depth). Decrement and restore the stencil state after the subtree.
Both paths must compose correctly when clip regions are nested — scissors intersect, stencil depths increment.

**Hit testing**
- `hitTest(wx, wy)` — walks the subtree in reverse draw order (highest zIndex first, stable insertion reversed within ties). Returns the first node that passes: `interactive=true`, `enabled=true`, `visible=true`, and the world point falls within the node's world bounds. If the hit node is not interactive but is enabled, hit testing descends into its children.
- `containsPoint(wx, wy)` — returns true if the world point is inside this node's world bounds rectangle.

**Update and draw stubs**
- `update(dt)` — resolves dirty transforms for this node, recurses to children in zIndex order.
- `draw()` — recurses to children in zIndex order, applying clipping dual path when `clipChildren=true`.
- No visual output in Container itself.

---

### lib/ui/core/drawable.lua

**Classification:** Primitive — extends Container with visual presentation and content-box model. No interaction semantics.

**Content-box model**
- `padding` — insets applied via the insets utility; shrinks the content box inside the node's bounds.
- `margin` — external space consumed around the node; layout families read margin to compute gaps. Margin does not affect the node's own bounds.
- Content box: the rectangle after padding is subtracted from bounds. Exposed as `getContentRect()` returning a Rectangle in local space.

**Alignment**
- `alignX`: start, center, end, stretch — aligns content horizontally within the content box.
- `alignY`: start, center, end, stretch — aligns content vertically within the content box.
- `stretch` in either axis causes content to fill the available content-box dimension; other values position content at the appropriate edge or center.

**Deferred visual fields (no-ops until Phase 8)**
- `opacity` (default 1.0) — stored but not applied to rendering until Phase 8 activates canvas isolation.
- `blendMode` (default nil/inherit) — stored but not applied until Phase 8.
- `shader` (default nil) — stored but not applied until Phase 8.
- `mask` (default nil) — stored but not applied until Phase 8.

**Derived flag**
- `focused` — set by Stage during the draw pass when this node is the current focus owner. Readable in draw() for rendering focus indicators. Not stored as persistent state on the node; assigned fresh each draw pass.

**Draw stub**
- `draw()` calls the Container draw traversal. Subclasses override to add visual output before or after calling the parent.

---

### lib/ui/scene/stage.lua

**Classification:** Runtime utility — root of the retained tree; drives the two-pass frame model.

**Structure**
- Stage contains exactly two direct children: `baseSceneLayer` (a plain Container) and `overlayLayer` (a plain Container). Composer mounts scenes into `baseSceneLayer`. Modal and Alert mount into `overlayLayer` in Phase 9.
- `overlayLayer` always draws and hit-tests above `baseSceneLayer` regardless of z-order.

**Two-pass model**
- `update(dt)` — resolves all dirty transforms and layout (layout pass added in Phase 3); sets an internal flag to indicate update has completed for this frame.
- `draw()` — traverses the retained tree and issues draw commands; asserts that update has already run this frame (hard failure if not). Clears the update-completed flag after the draw pass so the assertion resets for the next frame.
- No state changes are permitted during draw. Any code that modifies node state during draw is a violation of this contract.

**Safe area**
- `getSafeArea()` — calls `love.window.getSafeArea()` and returns the result as an insets table (top, right, bottom, left inset amounts). On desktop Love2D returns zero insets, which is valid.
- `getViewport()` — returns a Rectangle matching the current Love2D window dimensions.

**Resize handling**
- Stage listens for `love.resize` and updates its viewport rectangle. Layout nodes that depend on viewport dimensions mark themselves dirty when viewport changes.

---

## Test

**Location:** `test/phase1/`

**Structure:** A single Love2D project (`main.lua`, `conf.lua`). Navigation chrome — a screen name bar at the top and a key-hint strip at the bottom — is drawn with raw Love2D calls, never using the library. Left/right arrow keys (or comma/period) switch screens. The current screen name and number are displayed at all times.

**Screen 1 — Z-order and scissor clip**
Five overlapping sibling Containers at the same position, each with a different background color, with zIndex values 1 through 5. Number keys 1–5 reassign the focused child's zIndex to the pressed value, live-demonstrating re-sort. A second group alongside has a parent with `clipChildren=true` (non-rotated); children extend beyond the parent boundary and are clipped by the scissor.

**Screen 2 — Stencil clip on rotated parent**
A parent Container rotated at 30 degrees with `clipChildren=true`. Four child Containers positioned to overflow all four edges of the rotated parent. A toggle key (T) switches between forced scissor mode and stencil mode, making the difference visible: scissor clips to the axis-aligned bounding box (incorrect), stencil clips to the rotated polygon (correct). Default is stencil mode.

**Screen 3 — Interactive and enabled flags**
A 3×2 grid of Drawables with every combination of `interactive` and `enabled`. When the mouse hovers over a node, that node highlights if it is the actual hit-test result. A side panel shows the current hit node's label and its flag values. Demonstrates that non-interactive nodes pass through to the node below.

**Screen 4 — Min/max size clamps**
Three Containers with different clamp configurations: one with only minWidth, one with only maxWidth, one with both. A horizontal drag bar (raw Love2D draw) adjusts a shared parent width from 50px to 600px. The three children show their clamped widths numerically alongside their visual sizes.

**Screen 5 — Drawable alignment**
A 4×3 grid of Drawables with all combinations of alignX (start, center, end, stretch) and alignY (start, center, end, stretch). Each Drawable has padding shown as a colored inset and a small filled rect representing the content. Labels show the alignment mode. All Drawables are the same outer size so differences are purely from alignment.

**Screen 6 — Overlay layer**
Three children in `baseSceneLayer` and two children in `overlayLayer`. The overlay children's positions overlap the base scene children. Clicking demonstrates that the overlay children receive pointer events even though their z-index values are lower than some base scene children. A key hides/shows the overlay layer to show the base scene children alone.

---

## Hard Failures in This Phase

- Adding a Container to a second parent without first removing it from the current parent must remove it silently from the current parent (not crash or duplicate).
- Calling `draw()` before `update()` in the same frame must raise an explicit error with a message indicating the two-pass violation.
- Setting `clipChildren=true` on a node that has no defined size (zero or nil width/height) must be treated as a no-op clip with no crash.
