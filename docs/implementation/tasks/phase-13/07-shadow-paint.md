# Task 07: Shadow Paint

## Goal

Implement `_paint_outer_shadow` and `_paint_inset_shadow`. Outer shadow is drawn before background using an offscreen canvas blur pass. Inset shadow is drawn after border, clipped to the node interior so blur falloff does not escape. Both use `canvas_pool` for the offscreen canvas.

## Spec Anchors

- `docs/spec/ui-styling-spec.md §9.1` — shadow property list
- `docs/spec/ui-styling-spec.md §9.2` — outer shadow shape, offset, blur; inset shadow shape, clipping requirement
- `docs/spec/ui-styling-spec.md §5.2` — alpha composition: `shadowColorAlpha * (shadowOpacity or 1)`
- `docs/spec/ui-styling-spec.md §11A` — paint order: outer shadow at step 1, inset shadow at step 4

## Scope

- Modify `lib/ui/render/styling.lua`
- Replace the `_paint_outer_shadow` and `_paint_inset_shadow` stubs with full implementations
- Require `lib/ui/render/canvas_pool.lua`

## Concrete Module Targets

- `lib/ui/render/styling.lua` — modified only

## Implementation Guidance

**Skip condition (both):**

If `props.shadowColor` is nil, return immediately from the respective function. A shadow without a color has nothing to paint.

**Alpha:**

```
finalAlpha = props.shadowColor[4] * (props.shadowOpacity or 1)
```

**Outer shadow:**

1. Acquire a canvas from `canvas_pool` sized to at least `bounds.width + 2 * blur + |offsetX|` by `bounds.height + 2 * blur + |offsetY|`, where `blur = props.shadowBlur or 0`. The canvas must be large enough to contain the blurred shape without clipping.
2. Set the canvas as the render target.
3. Draw the rounded shadow shape at the offset position: origin at `shadowOffsetX` relative to the shadow canvas's coordinate space, with corner radii from `resolved_radii`. Fill with the shadow color at full alpha (compositing with `finalAlpha` happens at composite step).
4. Apply the blur pass to the canvas. The spec calls for a canvas-based blur; use a single-pass Gaussian approximation or repeated box blur. Blur radius = `props.shadowBlur or 0`. If blur is `0`, no blur pass is needed.
5. Composite the blurred canvas back onto the main render target at `{ 1, 1, 1, finalAlpha }`, positioned so the shadow shape aligns with `bounds` plus the offset.
6. Release the canvas back to `canvas_pool`.
7. The shadow shape is drawn behind the background — this is enforced by paint order in `Styling.draw`, not by z-ordering within this function.

**Inset shadow:**

1. Acquire a canvas from `canvas_pool` sized to the node's interior bounds (bounds inset by the border width on each side).
2. Set the canvas as the render target.
3. Draw the inset shadow shape into the canvas: the shadow fills the area that is NOT covered by the rounded inner silhouette. This is commonly implemented as a full canvas fill masked by the inverse of the inner rounded rectangle (fill the canvas, then cut out the inner shape using a stencil).
4. Apply blur pass if `props.shadowBlur > 0`.
5. Composite back onto the main render target, clipped to the interior bounds via a stencil or scissor region. The clip prevents blur falloff from painting outside the interior.
6. Release the canvas.

**State management:**

Save and restore canvas, color, and stencil state around both shadow functions. The main render target must be restored after compositing the offscreen canvas.

**Interior bounds for inset shadow:**

The interior is the bounds inset by the border widths:
- `innerX = bounds.x + (props.borderWidthLeft or 0)`
- `innerY = bounds.y + (props.borderWidthTop or 0)`
- `innerWidth = bounds.width - (props.borderWidthLeft or 0) - (props.borderWidthRight or 0)`
- `innerHeight = bounds.height - (props.borderWidthTop or 0) - (props.borderWidthBottom or 0)`

If any dimension is `<= 0`, skip the inset shadow.

## Required Behavior

- `shadowColor` nil → no draw call, canvas not acquired
- `shadowColor = {0,0,0,1}`, `shadowOpacity = 0.5`, `shadowInset = false` → outer shadow at alpha `0.5`
- `shadowOffsetX = 4, shadowOffsetY = 4` → shadow visually offset right and down
- `shadowOffsetX = -4` → shadow visually offset left
- `shadowBlur = 0` → hard-edged shadow, no blur pass
- `shadowBlur = 6` → soft blurred shadow edge
- `shadowInset = true` → inset shadow visible inside the node, not visible outside
- Inset shadow with `shadowBlur = 4` → blur falloff does not escape the interior bounds
- Outer shadow does not overwrite the background (paint order ensures it is behind)
- Canvas is released to the pool after each shadow draw, not leaked

## Non-Goals

- No multiple simultaneous shadows — the spec limits to one shadow per node in this revision.
- No `shadowSpread` property — explicitly excluded from this revision.
- No inner glow effect distinct from inset shadow.
- No shadow on transparent nodes with no background — shadow still renders per the spec if `shadowColor` is set.

## Acceptance Checks

- A node with `shadowColor = {0,0,0,1}`, `shadowOffsetX = 4`, `shadowOffsetY = 4`, `shadowBlur = 6`, `shadowInset = false` → visible soft shadow below and to the right of the node.
- A node with `shadowInset = true`, same color, offset, and blur → visible inset shadow inside the node, no bleed outside.
- `shadowBlur = 0` produces a crisp, hard-edged shadow.
- Canvas pool is not exhausted by repeated shadow draws (canvases are returned after each draw).
- Outer shadow is visually behind the background (painted at step 1, before background at step 2).
- Inset shadow is visually inside the border (painted at step 4, after border at step 3).
