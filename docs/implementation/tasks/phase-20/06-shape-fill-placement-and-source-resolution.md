# Task 06: Shape Fill Placement And Source Resolution

## Goal

Implement the local-bounds placement model for shape fill sources so textured and gradient fills resolve against shape-local geometry instead of Drawable box semantics.

## Current implementation notes

- Shape rendering currently has no concept of active source descriptors, intrinsic source dimensions, stretch mode, or tiling mode.
- `lib/ui/render/styling.lua` already contains background placement logic for alignment, offsets, tiling, and sprite-region quads, but it is written against Drawable bounds and rounded-rect clipping.

## Work items

- Build a shape-local fill placement resolver that takes:
  - the shape's local bounds AABB
  - the active fill source descriptor
  - repeat flags
  - offsets
  - alignment
- Implement stretch mode:
  - active when `fillRepeatX == false` and `fillRepeatY == false`
  - source scales to the full local bounds AABB
  - `fillAlign*` and `fillOffset*` are ignored
- Implement tiling mode:
  - active when either repeat flag is `true`
  - source uses intrinsic dimensions
  - `fillAlign*` positions the initial tile
  - `fillOffset*` shifts the tiling origin after alignment
  - non-repeating axes use a single intrinsic-size tile and do not stretch
- Implement gradient placement:
  - always spans the full local bounds AABB
  - `horizontal` means left-to-right
  - `vertical` means top-to-bottom
  - ignores `fillAlign*`, `fillOffset*`, and repeat flags
- Implement sprite placement so all placement math uses the sprite region dimensions, never the underlying texture dimensions.

## Implementation notes

- `lib/ui/render/graphics_source.lua` already provides intrinsic dimensions and Texture/Sprite draw-source resolution. Reuse it here; placement itself is the new work.
- `lib/ui/render/styling.lua` is a reference for alignment, offsets, and tiling loops, but it still assumes Drawable bounds and rounded-rect clipping. Do not import those ownership assumptions into the shape resolver.
- Sprite placement must continue to use sub-region width and height only. The underlying texture size is not a valid placement input in any mode.

## File targets

- new shape fill resolver module(s)
- `lib/ui/render/styling.lua` helper extractions from task 01
- `lib/ui/graphics/sprite.lua`
- `lib/ui/graphics/texture.lua`

## Acceptance criteria

- Stretch mode and tiling mode are both resolved from shape-local bounds.
- Gradient fill placement ignores alignment, offsets, and repeat flags.
- Sprite placement always uses sub-region width and height for placement math.
- Placement logic is shared across all concrete shape classes instead of being re-implemented per shape.
