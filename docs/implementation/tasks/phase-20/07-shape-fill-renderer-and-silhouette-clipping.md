# Task 07: Shape Fill Renderer And Silhouette Clipping

## Goal

Add a shared renderer for gradient-backed and texture-backed shape fill that clips to the shape silhouette and composes fill before stroke.

## Current implementation notes

- `lib/ui/shapes/draw_helpers.lua` currently supports only flat-color polygon fill and stroke rendering.
- `lib/ui/render/styling.lua` already has rounded-rect stencil helpers and a gradient mesh path that can be generalized.
- Concrete shapes already expose local silhouette points that can be used as the clipping geometry.

## Work items

- Introduce a shared shape fill renderer instead of adding gradient or texture logic separately to each shape class.
- Reuse or extract generic stencil helpers so arbitrary shape silhouettes can be written into stencil, not just rounded rectangles.
- Add a gradient fill path for shapes:
  - build a mesh or equivalent geometry over the local bounds AABB
  - apply the gradient across the full local bounds
  - clip the result to the silhouette
- Add a texture fill path for shapes:
  - resolve `Texture` or `Sprite` draw source
  - support stretch placement and tiling placement
  - clip all fill output to the silhouette
- Detect draw-time unusable texture or sprite sources and raise a hard error instead of sampling undefined data or falling back to a lower-priority fill source.
- If the active renderer cannot produce a semantically correct gradient or textured silhouette-clipped fill path, raise a hard error instead of degrading to flat color or un-clipped drawing.
- Preserve the required paint order:
  1. resolve active fill source
  2. clip fill to silhouette
  3. draw stroke on top
- Keep flat-color fill on the existing direct polygon path with no mesh, UV, or stencil overhead unless another active state requires it.
- Do not trigger subtree isolation merely because the active source is textured or gradient-backed.

## Implementation notes

- `lib/ui/shapes/draw_helpers.lua` is still flat-color-only. Non-flat fill needs a shared renderer, not another round of per-shape branching.
- `lib/ui/render/styling.lua` already has stencil-writing and gradient-mesh patterns, but those helpers are rounded-rectangle-specific. Extract only the geometry-agnostic parts or add new neutral helpers for arbitrary silhouettes.
- The missing hard-failure paths from the compliance review land here: unsupported renderer path for active gradient/texture fill and draw-time unusable texture-source detection.

## File targets

- `lib/ui/shapes/draw_helpers.lua`
- new shape fill renderer module(s)
- `lib/ui/render/styling.lua`
- `lib/ui/shapes/rect_shape.lua`
- `lib/ui/shapes/circle_shape.lua`
- `lib/ui/shapes/triangle_shape.lua`
- `lib/ui/shapes/diamond_shape.lua`

## Acceptance criteria

- All non-flat fill pixels outside the silhouette are discarded before the shape-local result is handed to the root compositor.
- Stroke still renders after fill and remains shape-owned.
- Flat-color fill remains the fast path.
- Textured or gradient fill does not participate in root compositing state derivation.
