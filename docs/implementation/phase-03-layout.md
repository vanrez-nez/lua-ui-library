# Phase 3 — Layout Families

## Goals

Introduce five layout containers — Stack, Row, Column, Flow, SafeAreaContainer — and the measurement/placement pass that sits inside Stage's update cycle. Establish the responsive rule infrastructure (percentage sizing, min/max clamping, declarative breakpoints). After this phase, any consumer can compose fully dynamic, responsive layouts without writing manual position arithmetic.

---

## Dependencies

Requires Phase 2 (Stage two-pass model, Scene, Composer, Easing, Insets, Rectangle, Vec2, Matrix).

---

## Shared Utilities Introduced

### lib/ui/layout/breakpoint_resolver.lua
Evaluates a `breakpoints` table against a given viewport size and returns a flat merged property-override table. The `breakpoints` input is a list of entries in ascending order of minimum viewport width (or height). Each entry has a `minWidth` (or `minHeight`) threshold and a `props` table of property overrides. The resolver returns the overrides from the highest-matching entry, or an empty table if no entry matches. Used by all layout families before their measurement step.

### lib/ui/layout/measure.lua
Shared measurement helpers:
- `resolveSize(configured, parentSize, min, max)` — resolves a configured size value that may be a pixel number, a percentage string ("50%"), "fill" (consume remaining space), or "content" (size to children). Returns a pixel value clamped by min and max. "fill" and "content" modes are used by layout families internally.
- `applyInsets(rect, insets)` — returns a new Rectangle shrunk by the given insets table.

---

## Components

### lib/ui/layout/stack.lua

**Classification:** Layout — layered child placement within the parent content box.

**Behavior**
- All children are placed within the same content box. No sequential positioning.
- Each child resolves its own anchor (normalized position within the parent content box) and pivot (rotation/scale center within the child's own bounds) independently.
- Children are drawn in ascending zIndex order with stable insertion-order tie-breaking.
- Hit testing follows reverse draw order.
- `clipChildren` is available and uses the standard Container dual-path clipping.

**Measurement**
- Stack's own size is either configured explicitly or resolves to the bounding box of all children when set to "content".
- Does not impose any size on children; children keep their own configured sizes.

**Properties**
- All Container and Drawable properties apply.
- No layout-specific properties beyond what Container provides.

---

### lib/ui/layout/row.lua

**Classification:** Layout — horizontal sequential placement.

**Behavior**
- Children placed left-to-right (when `direction = "ltr"`) or right-to-left (when `direction = "rtl"`) in insertion order.
- `gap` — pixel spacing between each consecutive pair of children.
- `align` — cross-axis (vertical) alignment for children: start, center, end, stretch.
- `justify` — main-axis (horizontal) distribution: start, center, end, space-between, space-around.
- `wrap` (default false) — when true, children that would overflow the row's content-box width wrap to a new line; gap applies between lines as well.

**Measurement**
- During the layout pass, Row measures each visible child's resolved width and height.
- Children with `width = "fill"` share the remaining space equally after fixed-size and percentage-size children are placed.
- After measuring all children, Row sets each child's `x` and `y` position within the Row's content box according to justify and align rules.
- Consumer-set `x`/`y` on children is overwritten by the layout; `anchorX`/`anchorY` are respected within the Row's cross-axis alignment logic.

**Properties**
- `direction` — "ltr" (default) or "rtl".
- `gap` — number (default 0).
- `align` — "start" (default), "center", "end", "stretch".
- `justify` — "start" (default), "center", "end", "space-between", "space-around".
- `wrap` — boolean (default false).

---

### lib/ui/layout/column.lua

**Classification:** Layout — vertical sequential placement.

**Behavior**
Identical to Row but along the vertical axis. Children placed top-to-bottom in insertion order.

- `gap` — pixel spacing between each consecutive pair of children.
- `align` — cross-axis (horizontal) alignment: start, center, end, stretch.
- `justify` — main-axis (vertical) distribution: start, center, end, space-between, space-around.
- `wrap` (default false) — when true, children that overflow the column's height wrap to a new column.

**Measurement**
Same as Row with axes transposed.

**Properties**
- `gap`, `align`, `justify`, `wrap` — same semantics as Row.

---

### lib/ui/layout/flow.lua

**Classification:** Layout — reading-order wrapped placement.

**Behavior**
- Places children in reading order (left-to-right) within the Flow's content-box width.
- When a child would overflow the current row's remaining width, it wraps to the next row.
- `wrap` (default true) — setting to false disables wrapping (children extend beyond the content-box width).
- `gapX` — horizontal gap between children in the same row.
- `gapY` — vertical gap between rows.
- Children keep their intrinsic configured sizes; Flow does not resize them.
- Row height within a Flow row is the maximum height among children in that row.

**Properties**
- `gapX` — number (default 0).
- `gapY` — number (default 0).
- `wrap` — boolean (default true).

---

### lib/ui/layout/safe_area_container.lua

**Classification:** Layout — derives content area from environment-reported safe area bounds.

**Behavior**
- Reads `stage:getSafeArea()` during the update/layout pass (not every frame — cached and re-read only when the viewport or safe area changes).
- Applies per-edge insets from the safe area to its content box. Each edge is opt-in:
  - `applyTop` (default true)
  - `applyBottom` (default true)
  - `applyLeft` (default true)
  - `applyRight` (default true)
- Children are placed within the inset content area. The SafeAreaContainer itself fills its configured size (usually the full viewport).
- On desktop, `love.window.getSafeArea()` returns zero insets for all edges, so SafeAreaContainer behaves as a plain Container.
- Each SafeAreaContainer instance independently queries the same environment-reported safe area — insets are not relative to parent SafeAreaContainers.
- When no safe area insets are reported (all zero), the container is valid and acts as a passthrough.

**Properties**
- `applyTop`, `applyBottom`, `applyLeft`, `applyRight` — booleans (default true for all).

---

## Responsive Rules

**Percentage sizing**
- `width` and `height` accept a percentage string (e.g., `"50%"`). The `resolveSize` utility in `lib/ui/layout/measure.lua` converts this to a pixel value by multiplying against the parent's content-box dimension for the relevant axis.
- Percentage resolution happens during the layout pass, before measurement. The parent must have a resolved pixel size before its children can resolve percentage sizes.

**Min/max clamping**
- After a size is resolved (from configured value, percentage, or layout-assigned value), it is clamped by `minWidth`/`maxWidth`/`minHeight`/`maxHeight` if those are set.
- Clamps are applied by every layout family and by Container itself.

**Breakpoints**
- Any Container (or subclass) can carry a `breakpoints` table. The BreakpointResolver is consulted at the start of each layout pass for that node.
- When the active breakpoint changes (viewport crosses a threshold), the affected node and all its layout descendants mark themselves dirty and re-layout on the next update pass.
- Breakpoints are evaluated against the Stage viewport, not the parent container size.
- Property overrides from breakpoints are applied to the node's effective properties before measurement. The underlying configured properties on the node are not modified.

---

## Layout Pass Integration with Stage

Stage's `update(dt)` method now runs in two sub-passes:
1. **Layout pass** — walks the tree top-down; each layout node resolves breakpoint overrides, measures children, and places them. This sets `x`/`y` on children.
2. **Transform pass** — walks the tree; each node recomputes its local Matrix from `x`, `y`, scale, rotation, skew, anchor, pivot. Then computes the world Matrix from parent's world Matrix.

Layout pass must complete before the transform pass because layout sets `x`/`y`, which the transform pass reads.

---

## Test

**Location:** `test/phase3/`

**Navigation:** Left/right arrow keys switch screens. Chrome drawn with raw Love2D. Screens 2 and 3 also use number keys (1–5) to switch sub-modes live.

**Screen 1 — Stack**
Two Stack containers side by side. Left stack: four children with different zIndex values and overlapping bounds; number keys 1–4 cycle through assigning different zIndex values to demonstrate live re-sort. Right stack: same children with `clipChildren=true`; children extend beyond the parent boundary and are clipped.

**Screen 2 — Row and Column**
Row on the left, Column on the right. Each has five visible children with distinct colors and size labels. Number keys toggle through justify modes (start, center, end, space-between, space-around); letter keys toggle align modes (start, center, end, stretch). Gap can be increased/decreased with plus/minus keys. Changes apply live.

**Screen 3 — Flow**
A Flow with 20 tiles of varying widths. A horizontal drag handle at the bottom of the screen adjusts the Flow's parent width from 150px to the full window width. Plus/minus keys adjust gapX; Shift+plus/minus adjust gapY. A "W" key toggles wrap on/off. The tile placement updates live on every frame as the parent width changes.

**Screen 4 — SafeAreaContainer**
A SafeAreaContainer filling the window. Debug rectangles paint the four safe-area inset regions in red. The main content area (inside the insets) is painted green. Per-edge apply flags are toggled with keys T (top), B (bottom), L (left), R (right). On desktop all insets are zero so the entire window is green; the test still exercises the code path and shows the toggle behavior.

**Screen 5 — Nested layouts**
A Column containing three Rows, each Row containing a Column, each inner Column containing a Flow of small tiles. Children at each level use percentage widths ("33%", "50%", "100%"). Window resize causes the layout to reflow through all levels. Width of the root Column is set to "100%" of the viewport. A counter in the corner shows how many layout passes ran since the last resize.

**Screen 6 — Breakpoints**
Three defined breakpoints: small (minWidth 0), medium (minWidth 600), large (minWidth 900). A Row of colored panels switches between 1, 2, and 3 children based on the active breakpoint — the breakpoint override replaces a "childCount" property that the Row's factory function reads when re-building children. The window can be resized to cross the thresholds. A debug strip at the bottom shows the current viewport width and active breakpoint name.

---

## Hard Failures in This Phase

- A Row or Column child with `width = "fill"` inside a Row or Column that itself has `width = "content"` creates a circular measurement dependency. This must raise a hard error identifying the circular dependency rather than looping infinitely.
- A Tabs trigger without a matching panel (introduced in Phase 7) is deferred — but the layout pass must not crash on an unknown layout type; it must pass through unknown node types without error.
- A percentage-sized node with no resolvable parent content-box size (e.g., root node with no configured size) must fall back to zero width/height, not crash.
