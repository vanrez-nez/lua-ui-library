# Task 5: Fix `backgroundImage` Rendering For `Texture` And `Sprite`

## Summary

- The schema accepts `Texture` and `Sprite`, but the renderer tries to draw the wrapper object directly.
- `Sprite` requires region-aware drawing via the texture drawable plus quad.

## Depends On

- [02-root-styling-resolution.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/02-root-styling-resolution.md)
- [04-skin-value-coercion.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/04-skin-value-coercion.md)

## Primary Files

- [lib/ui/render/styling.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/render/styling.lua)
- [lib/ui/graphics/image.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/graphics/image.lua)
- [lib/ui/graphics/texture.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/graphics/texture.lua)
- [lib/ui/graphics/sprite.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/graphics/sprite.lua)

## Work Items

- Update the image-backed background paint path in [`lib/ui/render/styling.lua`](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/render/styling.lua).
- Reuse the same source-unwrapping logic already present in [`lib/ui/graphics/image.lua`](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/graphics/image.lua), or extract a shared helper.
- Support:
  - `Texture`
  - `Sprite`
  - repeat X/Y
  - align X/Y
  - offset X/Y
  - rounded clipping
- Verify repeated sprite backgrounds still tile the sprite region, not the full texture.

## Exit Criteria

- `Texture` backgrounds paint correctly.
- `Sprite` backgrounds paint only the selected region.
- Alignment and tiling behave per spec.
