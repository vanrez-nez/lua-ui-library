# Task 03: Background — Color-Backed Paint

## Goal

Implement the color-backed background paint path in `_paint_background`. When `props.backgroundColor` is present and no higher-priority source (`backgroundImage` or `backgroundGradient`) is set, paint a filled rounded rectangle using the resolved color and opacity.

## Spec Anchors

- `docs/spec/ui-styling-spec.md §6.2` — `backgroundColor` and `backgroundOpacity` properties
- `docs/spec/ui-styling-spec.md §6.3` — color-backed background semantics and opacity composition
- `docs/spec/ui-styling-spec.md §5.2` — alpha composition: `colorAlpha * opacity`
- `docs/spec/ui-styling-spec.md §6.1` — source selection priority order

## Scope

- Modify `lib/ui/render/styling.lua`
- Implement `_paint_background` with source selection and the color-backed path
- Gradient and image paths remain stubs — they are implemented in tasks 04 and 05

## Concrete Module Targets

- `lib/ui/render/styling.lua` — modified only

## Implementation Guidance

**Source selection:**

At the start of `_paint_background`, check sources in priority order:

1. If `props.backgroundImage` is not nil → call image stub (returns immediately for now)
2. Else if `props.backgroundGradient` is not nil → call gradient stub (returns immediately for now)
3. Else if `props.backgroundColor` is not nil → proceed with color-backed path
4. Else → return, nothing to paint

**Color-backed path:**

`props.backgroundColor` is already a resolved `{ r, g, b, a }` table — `Color.resolve` ran at schema validation time. Read `r`, `g`, `b`, `a` directly.

Compute the final alpha:
```
finalAlpha = a * (props.backgroundOpacity or 1)
```

Set the graphics color to `{ r, g, b, finalAlpha }`.

Draw a filled rounded rectangle covering the full bounds using the resolved corner radii. The geometry is:
- origin at `bounds.x`, `bounds.y`
- size `bounds.width` by `bounds.height`
- corner radii from `resolved_radii.tl`, `.tr`, `.br`, `.bl`

Use the graphics adapter's rounded rectangle fill call. If the adapter does not have a single call for independent per-corner radii, construct geometry manually or use the closest available call.

Restore the graphics color to its pre-call state after painting.

**Skip condition:**

If the computed `finalAlpha` is `0`, skip the draw call entirely — painting a fully transparent shape is a no-op but still a draw call that should be avoided.

## Required Behavior

- `backgroundColor = {1, 0, 0, 1}`, `backgroundOpacity = nil` → painted with alpha `1`
- `backgroundColor = {1, 0, 0, 1}`, `backgroundOpacity = 0.5` → painted with alpha `0.5`
- `backgroundColor = {1, 0, 0, 0.8}`, `backgroundOpacity = 0.5` → painted with alpha `0.4`
- `backgroundColor = {1, 0, 0, 1}`, `backgroundOpacity = 0` → no draw call (alpha is `0`)
- `backgroundColor` nil, `backgroundOpacity = 0.5` → nothing painted (no source)
- `backgroundGradient` set, `backgroundColor` also set → gradient path takes priority, color path not reached (gradient stub returns early for now)
- `backgroundImage` set → image path takes priority (image stub returns early for now)
- All corners `0` → rectangle with no rounding
- Corners set to valid resolved values → rounded rectangle with those radii

## Non-Goals

- No gradient implementation in this task — gradient stub is sufficient.
- No image implementation in this task — image stub is sufficient.
- No clipping to stencil — clipping for gradient and image is handled in tasks 04 and 05.

## Acceptance Checks

- A Drawable with `backgroundColor = {0.2, 0.6, 1}` renders a filled rectangle matching the bounds.
- Setting `backgroundOpacity = 0.5` visually halves the opacity of the painted background.
- Setting `backgroundOpacity = 0` results in no visible paint.
- A Drawable with no background properties produces no output from `_paint_background`.
- Source selection correctly skips the color path when gradient or image is also set.
