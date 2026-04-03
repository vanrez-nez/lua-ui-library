# Task 04: Background — Gradient-Backed Paint

## Goal

Implement the gradient-backed background paint path. When `props.backgroundGradient` is present and no higher-priority source (`backgroundImage`) is set, paint a linear gradient across the full background bounds using a mesh-backed approach with evenly distributed color stops. The background is clipped to the resolved rounded corner geometry.

## Spec Anchors

- `docs/spec/ui-styling-spec.md §6.4` — `backgroundGradient` shape contract, linear kind, horizontal and vertical directions
- `docs/spec/ui-styling-spec.md §6.3` — `backgroundOpacity` composition with per-stop alpha
- `docs/spec/ui-styling-spec.md §5.2` — alpha composition formula

## Scope

- Modify `lib/ui/render/styling.lua`
- Replace the gradient stub in `_paint_background` with the full implementation
- Port the `lerp` scalar function from `reference/color.lua` as a local function

## Concrete Module Targets

- `lib/ui/render/styling.lua` — modified only

## Implementation Guidance

**Port `lerp`:**

Add a local function `lerp(a, b, s)` that returns `a + s * (b - a)`. This is the scalar form from `reference/color.lua`, adapted to operate in `[0, 1]` space rather than `[0, 255]`. No other code from the reference module is imported. This function is used for CPU-side color interpolation during mesh construction.

**Color stop layout:**

Given N colors in `props.backgroundGradient.colors`, distribute them evenly across the gradient axis. For N stops:
- Stop `i` (0-indexed) is at position `i / (N - 1)` along the axis (so stop 0 is at the start, stop N-1 is at the end).
- For `direction = "horizontal"`: the axis runs from `bounds.x` to `bounds.x + bounds.width`. Position translates to `bounds.x + t * bounds.width`.
- For `direction = "vertical"`: the axis runs from `bounds.y` to `bounds.y + bounds.height`. Position translates to `bounds.y + t * bounds.height`.

**Mesh construction:**

Build a mesh with one quad (two triangles) per adjacent pair of stops. For N stops there are N-1 quads. Each quad has four vertices at the corners of the strip between stop `i` and stop `i+1`.

For a horizontal gradient, quad `i` spans from `x = position(i)` to `x = position(i+1)`, with `y` covering `bounds.y` to `bounds.y + bounds.height`. The left two vertices get color stop `i`'s RGBA, the right two vertices get stop `i+1`'s RGBA. The GPU interpolates across the quad.

For a vertical gradient, the same logic applies with the axis transposed.

Per-vertex alpha:
```
vertexAlpha = stopColor[4] * (props.backgroundOpacity or 1)
```

Apply `backgroundOpacity` to each stop's alpha before assigning to the mesh vertices. The interpolated alpha across the mesh will then naturally incorporate `backgroundOpacity`.

**Clipping to rounded corner geometry:**

The gradient mesh is rectangular and exceeds the rounded corners. Apply a stencil pass to clip the mesh to the rounded corner silhouette produced by `resolved_radii`. Draw the rounded rectangle shape into the stencil buffer, then draw the gradient mesh with stencil test enabled, then clear the stencil. Save and restore stencil state around this sequence.

**Skip condition:**

If `backgroundOpacity` is `0`, all vertex alphas are `0` — skip the draw call.

## Required Behavior

- `backgroundGradient = { kind="linear", direction="horizontal", colors={{1,0,0,1},{0,0,1,1}} }` → smooth red-to-blue gradient left to right
- `backgroundGradient = { kind="linear", direction="vertical", colors={{1,0,0,1},{0,0,1,1}} }` → smooth red-to-blue gradient top to bottom
- Three-stop gradient `{ {1,0,0,1}, {0,1,0,1}, {0,0,1,1} }` → red → green → blue with even distribution
- `backgroundOpacity = 0.5` → all stop alphas halved
- Stop with alpha `0.5`, `backgroundOpacity = 0.5` → effective alpha `0.25` at that stop vertex
- `backgroundImage` set alongside `backgroundGradient` → image takes priority, gradient not painted
- Rounded corners applied → gradient visually clips to rounded silhouette

## Non-Goals

- No radial gradient support in this phase — `kind = "radial"` was rejected at schema time.
- No gamma correction for gradient stops unless explicitly added as a named enhancement. The port document mentions it as optional — leave it out.
- No image path implementation in this task.

## Acceptance Checks

- Two-stop horizontal gradient renders a smooth red-to-blue fill.
- Two-stop vertical gradient renders correctly oriented.
- Three-stop gradient distributes colors evenly with correct stop positions.
- `backgroundOpacity` visually scales the gradient's alpha.
- Gradient clips correctly to rounded corners — no color bleeds into corner cutouts.
- `lerp(a, b, 0)` returns `a`, `lerp(a, b, 1)` returns `b`, `lerp(a, b, 0.5)` returns the midpoint.
