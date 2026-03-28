# Phase 8 — Theming and Render Effects

## Goals

Wire the full token/skin/theme resolution pipeline into every control. Implement nine-slice rendering, stateful variant resolution, canvas isolation for opacity/blend/shader effects, and write a complete default token set covering all controls in all states. After this phase, consumers can theme the entire library by providing a single token override table, and controls render with proper visual polish.

---

## Dependencies

Requires Phase 7 (all controls built with hardcoded placeholder visuals). Phase 8 replaces those placeholders with token-resolved skin rendering.

---

## Shared Utilities Introduced

### lib/ui/render/nine_slice.lua
Implements nine-slice texture drawing. Takes a Love2D Image (or Texture), a source region rectangle, and four inset values (top, right, bottom, left cut lines measured from edges). From these, computes 9 Quad objects dividing the source into corners, edges, and center. Caches the quads keyed by `(texture, regionX, regionY, regionW, regionH, top, right, bottom, left)` — quads are recreated only when the definition changes.

Drawing: given a destination rectangle (target width and target height), issues 9 `love.graphics.draw` calls:
- Four corners: drawn at natural pixel size (no stretch). Scale corners down proportionally if target size is smaller than the sum of opposing corner insets.
- Four edges: stretched along one axis only.
- Center: stretched along both axes.
- If target size is smaller than the sum of opposing corner insets, edge and center cells are omitted.

### lib/ui/render/canvas_pool.lua
Manages a pool of Love2D Canvas objects organized by size bucket. Size buckets round up to the nearest 64 pixels in each dimension (to avoid creating a unique canvas for every possible size).

- `pool:acquire(width, height)` — returns a canvas of at least the requested size from the pool, or creates a new one if none available.
- `pool:release(canvas)` — returns a canvas to the pool for reuse.
- Canvases are released after each frame where they are no longer needed. A canvas that has been in the pool unreleased for more than 60 frames is eligible for garbage collection.

---

## Theme System

### lib/ui/themes/theme.lua
The Theme object. Holds a flat Lua table (`tokens`) using the three naming schemas:
- `global.<class>.<role>` — library-wide defaults (e.g., `global.color.primary`, `global.spacing.base`).
- `<component>.<part>.<property>` — component and part-specific defaults (e.g., `button.root.fillColor`, `checkbox.box.borderColor`).
- `<component>.<part>.<property>.<variant>` — state-variant overrides (e.g., `button.root.fillColor.hovered`, `button.root.fillColor.disabled`).

All twelve token classes are valid values: color, spacing, radius, border, font, timing, texture, atlas, quad, nineSlice, shader, opacity, blendMode.

### lib/ui/themes/resolver.lua
The token resolver. Takes a resolution context (component name, part name, active variant, instance overrides, active theme, library default token table) and returns a resolved token value following the six-level precedence order:

1. Variant-specific instance override: instance `skinOverrides[partName][propName][variantName]`
2. Base instance override: instance `skinOverrides[partName][propName]`
3. Variant-specific part skin override: global part-skin table for `[variantName]`
4. Base part skin override: global part-skin table base entry
5. Active theme token: `activeTheme.tokens[component.part.property.variant]` or `activeTheme.tokens[component.part.property]`
6. Library default token: hardcoded default table entry

The resolver is a pure function (no side effects). Every skinnable component calls it once per part per draw pass for each property it needs.

### lib/ui/themes/default.lua (full rewrite)
The complete library default token table. Contains entries for all nine controls, all named parts, and all state variants. Every token that any control or utility reads must have a value here.

Token coverage required:
- `Text`: content color (body, heading, caption roles), font, fontSize for each role.
- `Button`: root fill color (base, hovered, pressed, focused, disabled), root border color and width, root corner radius, content area padding, focus ring color and offset.
- `Checkbox`: box fill color (base, checked, indeterminate, disabled), box border color and width, indicator color (checked, indeterminate), label color, description color, spacing between box and label.
- `Switch`: track fill color (unchecked, checked, dragging, disabled), thumb fill color (unchecked, checked, disabled), thumb size, track height, animation duration (timing token).
- `TextInput`: field background color (base, focused, disabled, readOnly, composing), field border color and width, caret color, selection highlight color, placeholder color, corner radius, padding, caret blink interval (timing token).
- `TextArea`: inherits TextInput tokens; additionally scroll region appearance tokens.
- `Tabs`: list background, trigger fill (base, active, focused, disabled), indicator color and height, panel background, gap between trigger and panel.
- `Modal`: backdrop color (opacity), surface fill color, surface corner radius, surface shadow (color, offset, blur — applied via shader in a later enhancement), content padding.
- `Alert`: inherits Modal tokens; additionally title color and font, message color and font, actions gap, minimum action button width.

---

## Stateful Variant Resolution

Each control evaluates its active state flags in a defined priority order and resolves the highest-priority active state as the current variant. The variant is a string used as the final suffix in the token naming schema.

Variant priority orders (highest to lowest):
- `Button`: "disabled" > "pressed" > "hovered" > "focused" > "base"
- `Checkbox`: "disabled" > "indeterminate" > "checked" > "focused" > "base"
- `Switch`: "disabled" > "dragging" > "checked" > "focused" > "base"
- `TextInput`: "disabled" > "readOnly" > "composing" > "focused" > "base"
- `TextArea`: same as TextInput
- `Tabs` trigger: "disabled" > "active" > "focused" > "base"
- `Tabs` panel: "active" > "inactive"
- `Modal`: "mounted" and "unmounted" only in this revision
- `Alert`: same as Modal

The resolver applies the variant suffix to token lookups. If a variant-specific token is not found, it falls back to the base token, then to library defaults. This means partial theme overrides work correctly — only the tokens you override are changed; others fall through to defaults.

---

## Part-Level Skin Rendering

Each named control part can be rendered in one of the following modes, determined by the resolved skin configuration:

- **Solid fill**: `love.graphics.setColor` + `love.graphics.rectangle("fill", ...)` with optional corner radius via rx/ry.
- **Stroked shape**: `love.graphics.setColor` + `love.graphics.rectangle("line", ...)` with optional line width.
- **Texture draw**: `love.graphics.draw(image, x, y, ...)`.
- **Quad draw**: `love.graphics.draw(image, quad, x, y, ...)`.
- **Nine-slice draw**: uses the nine-slice utility. The skin configuration must provide the image, source region, and four inset values.
- **Text draw**: `love.graphics.setFont` + `love.graphics.print` or `printf`.
- **Shader-modified draw**: activates a Love2D Shader before drawing, deactivates after. Applies to any of the above draw modes.
- **Custom renderer**: if a part's skin configuration includes a `renderer` function, that function is called instead of any built-in mode. The function receives the part bounds and resolved token values.

---

## Canvas Isolation for Render Effects

A Drawable activates canvas isolation when any of the following are true and non-default:
- `opacity < 1`
- `blendMode` is set to a non-default mode
- `shader` is set on the node and the shader requires the fully composited subtree as input

**Isolation process:**
1. Compute the world AABB of the Drawable's subtree.
2. Acquire a canvas from the canvas pool at the AABB size.
3. Call `love.graphics.setCanvas(canvas)` to redirect drawing.
4. Clear the canvas.
5. Draw all children to the canvas (the normal draw traversal, but output goes to canvas).
6. Call `love.graphics.setCanvas()` to restore the previous render target.
7. Set `love.graphics.setColor` to the node's opacity (RGBA with alpha = opacity).
8. If `blendMode` is set, activate it via `love.graphics.setBlendMode`.
9. If `shader` is set, activate it via `love.graphics.setShader`.
10. Draw the canvas back to the screen at the AABB position.
11. Restore blend mode and shader to previous state.
12. Release the canvas back to the pool.

**Inline rendering (no isolation):**
When none of the isolation conditions apply, children are drawn directly without a canvas. This is the common path and has no extra overhead.

---

## Focus Ring via Theme

In Phase 5, the base Drawable drew a hardcoded white focus ring. In Phase 8, the focus ring is replaced by the resolved focus indicator token: the ring color, width, and offset are read from the active theme's focus indicator tokens. Each control may override this with its own skin variant ("focused" variant provides the full focused-state skin, not just the ring).

---

## Test

**Location:** `test/phase8/`

**Navigation:** Left/right arrow keys switch screens. Chrome drawn with raw Love2D.

**Screen 1 — Token override**
Three identical Buttons rendered side by side. Each Button has a different local instance skin override applied at construction:
- Dark theme: dark fill, subtle border, low contrast.
- Light theme: white fill, strong border, dark text.
- Colorful theme: vivid primary fill, no border.
No theme files are swapped; the overrides are supplied via the instance `skinOverrides` table. Demonstrates the highest two levels of the resolution chain (instance variant override and base instance override).

**Screen 2 — Nine-slice**
A single test image with a clearly patterned nine-slice definition (corner decorations at each edge). The image is rendered at five sizes arranged vertically:
1. Smaller than source (corners scale down, edges and center omitted if below threshold).
2. Exact source size.
3. 2× wider than source.
4. 2× taller than source.
5. 4× both dimensions.
Corner pixels must not stretch. Edge pixels must stretch only on their axis. Center stretches both axes. A side panel shows the nine-slice inset values and the destination size for each rendering.

**Screen 3 — Stateful variant live toggle**
A single Button and a single Checkbox displayed with a key panel below each. Keys force each state flag:
- H: toggle hovered.
- P: toggle pressed.
- F: toggle focused.
- D: toggle disabled.
Both controls update their visual rendering immediately as flags are forced. The variant name resolved for the current combination is displayed in a label. Demonstrates priority: when D and F are both active, "disabled" variant is active, not "focused".

**Screen 4 — Canvas isolation**
A Column of three Drawables inside a parent Container. The parent's `opacity` is set to 0.5. Toggle key I switches between:
- Isolation enabled: the subtree composites as a group, then the group is drawn at 50% opacity. All children appear uniformly semi-transparent.
- Isolation disabled: each child draws at 50% opacity individually (incorrect behavior — overlapping children are more opaque where they overlap).
The visual difference is clear when children overlap or when a child has the same color as the background. A second toggle demonstrates `blendMode = "add"` applied to an isolated container.

**Screen 5 — Shader effect**
A parent Container with a grayscale shader applied (all descendants rendered gray). Inside it, a child Container with a hue-rotation shader. The child activates canvas isolation because its shader requires the composited subtree. Result: the child's subtree is hue-rotated and then appears gray within the parent. A toggle removes the parent shader to show the hue-rotated colors without the gray override.

**Screen 6 — All controls themed**
One screen showing all nine controls (Text, Button, Checkbox, Switch, TextInput, TextArea, Tabs, Modal trigger, Alert trigger) rendered with a non-default full theme override. The override changes primary colors to an orange palette. All controls must reflect the orange theme consistently, confirming full token coverage across the entire library.

---

## Hard Failures in This Phase

- A token key referenced by a control that has no entry in the active theme and no entry in the library default token table must raise a hard error identifying the missing token key. This prevents silent invisible rendering.
- A nine-slice definition where the sum of left + right insets exceeds the source region width (or top + bottom exceeds height) must raise a hard error at definition time. This is an invalid nine-slice configuration.
- `canvas_pool:release(canvas)` called with a canvas that was never acquired from this pool instance must be silently ignored (not an error — defensive release is acceptable).
- A custom renderer function registered for a part that raises a Lua error must propagate the error through the draw pass. It must not be silently swallowed.
