# Phase 13: Styling Paint Pipeline

## Purpose

Implement the core styling renderer that paints background, border, and shadow for any styled node. This module is called from the draw cycle (Phase 14) and produces visual output aligned to the spec paint order and all documented contracts.

## Authority

- `docs/spec/ui-styling-spec.md` §6 Background Contract
- `docs/spec/ui-styling-spec.md` §7 Border Contract
- `docs/spec/ui-styling-spec.md` §8 Corner Radius Contract
- `docs/spec/ui-styling-spec.md` §9 Shadow Contract
- `docs/spec/ui-styling-spec.md` §11A Paint Order

---

## Scope

### File

`lib/ui/render/styling.lua`

Exposes one primary function:

```
Styling.draw(props, bounds, graphics)
```

- `props`: resolved styling property table (see Phase 14 for how it is assembled)
- `bounds`: `{ x, y, width, height }` of the painted node
- `graphics`: graphics adapter (same adapter pattern used elsewhere in the library)

---

## Paint Order

Must be enforced in this sequence per spec §11A:

1. Outer shadow (when `shadowInset == false`)
2. Background
3. Border
4. Inset shadow (when `shadowInset == true`)

Content and descendants are not part of this module — they are rendered after by the normal draw cycle.

---

## Corner Radius Resolution

Corner radius is shared across background, border, and shadow. Resolve once per draw call.

Given `cornerRadiusTopLeft`, `cornerRadiusTopRight`, `cornerRadiusBottomRight`, `cornerRadiusBottomLeft` and the painted `bounds`:

**Overflow protection (proportional scale-down):**
- Top side: if `cornerRadiusTopLeft + cornerRadiusTopRight > bounds.width`, compute scale `= bounds.width / (tl + tr)` and multiply both by it
- Bottom side: same for `cornerRadiusBottomLeft + cornerRadiusBottomRight`
- Left side: if `cornerRadiusTopLeft + cornerRadiusBottomLeft > bounds.height`, scale proportionally
- Right side: same for `cornerRadiusTopRight + cornerRadiusBottomRight`

Apply all scale-downs before painting. Use the resolved (possibly scaled) radii for all subsequent steps.

---

## Background

### Source Selection

Evaluate in priority order. Use the first that resolves:

1. `backgroundImage` present → image-backed
2. `backgroundGradient` present → gradient-backed
3. `backgroundColor` present → color-backed
4. No background painted

### Color-Backed

```
resolvedAlpha = colorAlpha * (backgroundOpacity or 1)
```

Draw a filled rounded rectangle using resolved radii and the computed RGBA.

### Gradient-Backed

Only `linear` kind is supported in this revision.

- `direction = "horizontal"`: gradient runs left to right
- `direction = "vertical"`: gradient runs top to bottom

Colors are evenly distributed across the background box in the resolved direction. For N colors, each occupies `1 / (N - 1)` of the axis.

Implementation approach: use a mesh-backed rendering path. Generate a quad mesh along the gradient axis with one vertex pair per color stop, assign RGBA at each vertex, let the GPU interpolate.

```
resolvedPixelAlpha = interpolatedStopAlpha(x, y) * (backgroundOpacity or 1)
```

The alpha at each gradient stop participates in the interpolation before `backgroundOpacity` is applied.

Background is clipped to the resolved rounded corner geometry.

**Port from `reference/color.lua`:** The `lerp` scalar function `a + s * (b - a)` can be ported directly for any CPU-side color interpolation needed during mesh construction. No class structure or metatable should be imported — extract the arithmetic only. Operates in `[0, 1]` space (unlike the reference which uses `[0, 255]`).

### Image-Backed

- `backgroundImage` must be a `Texture` or `Sprite` — validated in schema (Phase 12)
- Apply `backgroundAlignX/Y` to position the source within the bounds
- Apply `backgroundOffsetX/Y` as pixel offsets after alignment
- Apply `backgroundRepeatX/Y` to tile the source across the bounds
- `resolvedAlpha = sourceAlpha * (backgroundOpacity or 1)`

Background is clipped to the resolved rounded corner geometry.

---

## Border

### Skip condition

If all four `borderWidth*` values resolve to zero (or nil), skip border paint entirely.

### Geometry

Border is center-aligned on the styled bounds:
- Half of each side's width paints inward from the bounds edge
- Half paints outward

For a center-aligned border with corner radius applied to the stroke centerline:
- Outer arc = `cornerRadius + borderWidth / 2`
- Inner arc = `cornerRadius - borderWidth / 2`

### Paint

```
resolvedAlpha = borderColorAlpha * (borderOpacity or 1)
```

Apply `borderStyle` via `love.graphics.setLineStyle`:
- `"smooth"` → antialiased
- `"rough"` → aliased

Apply `borderJoin` via `love.graphics.setLineJoin`:
- `"miter"` → miter join; apply `borderMiterLimit` when present via `love.graphics.setMiterLimit`
- `"bevel"` → bevel join
- `"none"` → no join cap geometry

Per-side border widths are all supported. When widths differ per side, each side is drawn independently at its resolved width.

Save and restore line style, join, and miter limit state around the border draw calls.

---

## Shadow

### Outer Shadow (`shadowInset = false`)

Drawn before background (step 1 in paint order).

Shape follows the outer rounded silhouette of the node (resolved corner radii).

Offset by `shadowOffsetX`, `shadowOffsetY`.

Blur via canvas-based approach: draw the shadow shape onto an offscreen canvas, apply a blur pass, composite back.

```
resolvedAlpha = shadowColorAlpha * (shadowOpacity or 1)
```

Use `lib/ui/render/canvas_pool.lua` (introduced in Phase 8) for the offscreen canvas.

### Inset Shadow (`shadowInset = true`)

Drawn after border (step 4 in paint order).

Shape follows the inner rounded silhouette (resolved corner radii, inset by border width).

**Clipping:** Inset shadow paint is clipped to the node's interior bounds (the area inward from the border edge). Shadow blur falloff must not paint outside this region. Enforce via a stencil or scissor pass.

```
resolvedAlpha = shadowColorAlpha * (shadowOpacity or 1)
```

---

## Reference Reuse Summary

| From `reference/color.lua` | Reuse approach |
|---|---|
| `lerp` scalar function | Port directly for gradient vertex color interpolation in `[0, 1]` space |
| `gamma_to_linear` algorithm | Optionally adapt for perceptual gradient accuracy — convert stops before interpolation, convert back after |
| `is_color` pattern | Already ported in Phase 11; use `Color.resolve()` instead |
| `color.opacity` pattern | The multiplication `c[4] * v` is the same as the spec formula; implement inline, not imported |
| Any class/metatable structure | Do NOT import |

---

## Key Normalizations

- `Styling.draw` is stateless per call — no persistent state between frames
- All color inputs are resolved through `Color.resolve()` (Phase 11) before painting
- `canvas_pool` is reused for shadow blur — do not allocate a new canvas per frame
- Border geometry does not affect layout measurement or hit-testing

---

## Verification

- Node with `backgroundColor = {0.2, 0.4, 0.8}` and `backgroundOpacity = 0.5` → painted alpha `0.2 * 0.5 = 0.1` equivalent for the color
- Node with `backgroundGradient = { kind="linear", direction="horizontal", colors={{1,0,0},{0,0,1}} }` → smooth red-to-blue horizontal gradient
- Node with `backgroundImage = someTexture` → texture drawn at `alignX="center"`, `alignY="center"` by default
- Node with all four `cornerRadius*` set to a value exceeding half the bounds → proportional scale-down, no overlap
- Node with `borderWidthTop = 2`, all others zero → only top border painted
- Node with `borderJoin = "miter"` and `borderMiterLimit = 2` → miter limit applied
- Node with `shadowInset = false` → outer shadow visible behind background
- Node with `shadowInset = true` → inset shadow visible inside border, no bleed outside interior bounds
- Node with no background, border, or shadow properties → nothing painted, no errors
