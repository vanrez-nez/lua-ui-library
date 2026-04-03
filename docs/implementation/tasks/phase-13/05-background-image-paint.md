# Task 05: Background — Image-Backed Paint

## Goal

Implement the image-backed background paint path. When `props.backgroundImage` is present, draw the `Texture` or `Sprite` source within the node's bounds, applying alignment, pixel offset, tiling, and opacity. The painted region is clipped to the resolved rounded corner geometry.

## Spec Anchors

- `docs/spec/ui-styling-spec.md §6.5` — image placement properties: `backgroundAlignX/Y`, `backgroundOffsetX/Y`, `backgroundRepeatX/Y`
- `docs/spec/ui-styling-spec.md §6.3` — `backgroundOpacity` composition
- `docs/spec/ui-styling-spec.md §5.5` — accepted source types: `Texture` or `Sprite` only
- `docs/spec/ui-styling-spec.md §5.2` — alpha composition formula

## Scope

- Modify `lib/ui/render/styling.lua`
- Replace the image stub in `_paint_background` with the full implementation

## Concrete Module Targets

- `lib/ui/render/styling.lua` — modified only

## Implementation Guidance

**Source dimensions:**

Retrieve the pixel dimensions of `props.backgroundImage`. For a `Texture`, use its width and height. For a `Sprite`, use the frame dimensions. These are the "natural" dimensions of the source before any positioning.

**Alignment:**

Compute the base draw position from `backgroundAlignX` and `backgroundAlignY` (both default to `"start"` when nil):

- `backgroundAlignX = "start"` → `drawX = bounds.x`
- `backgroundAlignX = "center"` → `drawX = bounds.x + (bounds.width - sourceWidth) / 2`
- `backgroundAlignX = "end"` → `drawX = bounds.x + bounds.width - sourceWidth`

Apply the same logic vertically with `backgroundAlignY`.

**Pixel offset:**

Add `backgroundOffsetX` and `backgroundOffsetY` (both default to `0`) to the computed draw position after alignment.

**Tiling:**

If `backgroundRepeatX` is true, tile the source across the full width of the bounds starting from the aligned and offset position. Cover from `bounds.x` to `bounds.x + bounds.width`, painting the source repeatedly at intervals of `sourceWidth`.

If `backgroundRepeatY` is true, tile vertically in the same way.

If both are true, tile in a grid.

For tiling, the first tile starts at the computed position after alignment and offset. Tiles outside the bounds area are not painted — the clipping step handles containment.

**Opacity:**

```
finalAlpha = sourceAlpha * (props.backgroundOpacity or 1)
```

Set the graphics color to `{1, 1, 1, finalAlpha}` before drawing the source (using white as a color multiplier so the source's own colors are not altered, only the alpha).

**Clipping:**

Apply a stencil pass to clip all drawn tiles to the rounded corner silhouette produced by `resolved_radii`. Save and restore stencil state. This is the same stencil pattern used in the gradient path.

**Skip condition:**

If `props.backgroundOpacity` is `0`, skip painting.

## Required Behavior

- Image with `backgroundAlignX = "center"`, `backgroundAlignY = "center"` → image centered within bounds
- Image with `backgroundAlignX = "end"`, `backgroundAlignY = "end"` → image anchored to bottom-right
- Image with `backgroundAlignX = "start"`, `backgroundAlignY = "start"` (default) → image at top-left
- `backgroundOffsetX = 10`, `backgroundOffsetY = -5` → position shifted by 10 pixels right and 5 pixels up from aligned position
- `backgroundRepeatX = true` → image tiled horizontally, fully covering width
- `backgroundRepeatX = true`, `backgroundRepeatY = true` → image tiled in grid
- `backgroundOpacity = 0.5` → image drawn at half opacity
- `backgroundOpacity = 0` → no draw calls
- Rounded corners → image visually clips to rounded silhouette, no bleed into corners

## Non-Goals

- No scaling or stretching of the source image to fit the bounds — the spec does not define a `backgroundSize` property in this revision.
- No cover or contain fit modes — those are a future extension.
- No animated sprite advancement — the renderer draws whatever the current sprite frame is; sprite state management is the consumer's responsibility.

## Acceptance Checks

- Image drawn with default alignment appears at the top-left of the bounds.
- Center alignment produces a visually centered image within bounds.
- `backgroundRepeatX = true` tiles the image horizontally across the full width.
- `backgroundOpacity = 0.5` produces a visually transparent version of the image.
- Tiled image clips correctly to rounded corners — tiles do not bleed into corner cutouts.
- Source priority: when `backgroundImage` is set, gradient and color paths are not reached.
