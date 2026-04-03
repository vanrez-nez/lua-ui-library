# Task 06: Border Paint

## Goal

Implement `_paint_border`. When at least one `borderWidth*` value is non-zero, paint center-aligned borders on each side using the border color, opacity, and line style properties. Support per-side widths, drawing each side independently when widths differ. Save and restore all line state around the paint calls.

## Spec Anchors

- `docs/spec/ui-styling-spec.md §7.1` — flat border property list
- `docs/spec/ui-styling-spec.md §7.2` — width model: center-aligned, per-side, non-negative
- `docs/spec/ui-styling-spec.md §7.3` — opacity composition: `borderColorAlpha * (borderOpacity or 1)`
- `docs/spec/ui-styling-spec.md §7.4` — `borderStyle`, `borderJoin`, `borderMiterLimit` contract

## Scope

- Modify `lib/ui/render/styling.lua`
- Replace the `_paint_border` stub with the full implementation

## Concrete Module Targets

- `lib/ui/render/styling.lua` — modified only

## Implementation Guidance

**Skip condition:**

If all four `borderWidth*` values are nil or `0`, return immediately. No draw calls, no state changes.

**Color and alpha:**

`props.borderColor` is already resolved to `{ r, g, b, a }`.

```
finalAlpha = props.borderColor[4] * (props.borderOpacity or 1)
```

Set graphics color to `{ r, g, b, finalAlpha }` before drawing.

**Line state:**

Before any draw call, save the current line style, line join, and miter limit.

Apply `props.borderStyle`:
- `"smooth"` → `love.graphics.setLineStyle("smooth")` (or adapter equivalent)
- `"rough"` → `love.graphics.setLineStyle("rough")`
- nil → leave at current default

Apply `props.borderJoin`:
- `"miter"` → set join to miter; if `props.borderMiterLimit` is not nil, set miter limit
- `"bevel"` → set join to bevel
- `"none"` → set join to none
- nil → leave at current default

Restore all three values after all border draw calls.

**Center-aligned geometry:**

For each side, the stroke centerline sits on the edge of the bounds. Half the stroke width paints inward, half outward.

Border geometry with corner radius applied uses the stroke centerline radius:
- outer arc radius = `cornerRadius + borderWidth / 2`
- inner arc radius = `cornerRadius - borderWidth / 2`

When all four sides have equal width, draw as a single rounded rectangle stroke using the resolved corner radii and the uniform border width.

When widths differ per side, draw each side as an independent line segment or arc at its respective width. For simplicity, even when widths differ, use the resolved corner radii at the corners of each side's geometry.

**Per-side skip:**

For each side where `borderWidth*` is nil or `0`, skip drawing that side's segment.

## Required Behavior

- All four `borderWidth*` nil → no draw call, no state changes
- `borderWidthTop = 2`, others nil → only top border segment painted
- `borderWidthTop = 2, borderWidthRight = 2, borderWidthBottom = 2, borderWidthLeft = 2` → uniform border, single rounded rectangle stroke
- `borderWidthTop = 4, borderWidthRight = 2, borderWidthBottom = 4, borderWidthLeft = 2` → per-side draw calls
- `borderColor = {0,0,0,1}`, `borderOpacity = 0.5` → border painted at alpha `0.5`
- `borderColor = {0,0,0,0.4}`, `borderOpacity = 0.5` → border painted at alpha `0.2`
- `borderStyle = "smooth"` → line style set to smooth before draw, restored after
- `borderStyle = "rough"` → line style set to rough
- `borderJoin = "miter"`, `borderMiterLimit = 3` → miter join with limit `3` applied
- `borderJoin = "bevel"` → bevel join applied
- Graphics state (color, line style, join, miter limit) is the same before and after `_paint_border`

## Non-Goals

- No dashed or dotted border patterns — the spec explicitly excludes these in this revision.
- No border paint outside the styled bounds affecting layout or hit-testing.
- No per-corner border radius overrides independent of the resolved corner radii.

## Acceptance Checks

- A node with `borderWidthTop = 2` and no other border properties shows only a top border line.
- A node with all four `borderWidth*` set to `2` and `borderColor = {0,0,0,1}` shows a uniform black border.
- `borderOpacity = 0.5` visually halves the border alpha.
- Setting `borderStyle = "rough"` produces visibly aliased border edges.
- `borderJoin = "miter"` with `borderMiterLimit = 2` does not produce spikes beyond the limit.
- Graphics line state is fully restored after `_paint_border` returns.
