# Task 01: Shared Graphics Capability Helpers

## Goal

Extract the validator and source-resolution logic that is currently embedded in Drawable-specific modules so both `Drawable` and `Shape` can consume the same graphics capability contracts.

## Current implementation notes

- `lib/ui/core/drawable_schema.lua` already validates gradient objects and `Texture | Sprite` background sources.
- `lib/ui/render/styling.lua` already knows how to derive drawable sources, sprite quads, intrinsic dimensions, alignment, offsets, tiling loops, and stencil state.
- `lib/ui/core/shape_schema.lua` currently re-implements only color and numeric validators.

## Work items

- Introduce shared helper module(s) under `lib/ui/render/` or another neutral namespace for:
  - root opacity validation
  - root `blendMode` enum validation with `"normal"` as the default value
  - gradient object validation using the styling spec's shared value-type contract
  - `Texture | Sprite` source validation
  - draw-source resolution for `Texture` and `Sprite`, including quad creation for sprite regions
  - intrinsic dimension access for `Texture` and `Sprite`
- Move Drawable background validation and draw-source plumbing to those helpers instead of keeping a private copy inside `drawable_schema.lua` and `styling.lua`.
- Keep the helpers contract-focused:
  - no styling inheritance logic
  - no shape-specific naming aliases
  - no primitive-family branching
- Preserve the existing `Sprite` behavior where out-of-bounds regions clip with a warning and non-positive dimensions fail hard.

## Implementation notes

- The shared helper boundary is now `lib/ui/render/graphics_validation.lua` and `lib/ui/render/graphics_source.lua`. Later tasks should extend those modules instead of adding new Drawable-private validators or source resolvers.
- `mask` stays outside these helpers. Do not add `mask` validation, capability declarations, or source-resolution behavior to the shared graphics-capability layer.
- Keep the normalized `"normal"` blend-mode default as a helper-level contract until task `03` updates `container.lua` to treat it as a true no-op fast path. Wiring `"normal"` directly into the retained runtime too early would force unnecessary isolation.

## File targets

- `lib/ui/core/drawable_schema.lua`
- `lib/ui/core/shape_schema.lua`
- `lib/ui/render/styling.lua`
- new shared helper module(s), likely under `lib/ui/render/`
- `lib/ui/graphics/texture.lua`
- `lib/ui/graphics/sprite.lua`

## Acceptance criteria

- Drawable and Shape schemas consume the same gradient and graphics-source validators.
- The accepted root `blendMode` set is normalized to the spec surface:
  - `"normal"`
  - `"add"`
  - `"subtract"`
  - `"multiply"`
  - `"screen"`
- `Texture` and `Sprite` source resolution is no longer duplicated between background rendering and the new shape fill path.
- Helper extraction does not add styling ownership or skin participation to `Shape`.
