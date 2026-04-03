# Task 9: Add Spec-Focused Tests

## Summary

- Current coverage verifies the resolver in isolation but not end-to-end styling resolution and painting.

## Depends On

- [02-root-styling-resolution.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/02-root-styling-resolution.md)
- [03-token-normalization.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/03-token-normalization.md)
- [04-skin-value-coercion.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/04-skin-value-coercion.md)
- [05-background-image-rendering.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/05-background-image-rendering.md)
- [06-inner-geometry.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/06-inner-geometry.md)
- [07-part-styling-integration.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/07-part-styling-integration.md)

## Primary Files

- [spec/theme_resolution_and_render_helpers_spec.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/spec/theme_resolution_and_render_helpers_spec.lua)
- [spec/styling_resolution_spec.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/spec/styling_resolution_spec.lua)
- [spec/styling_renderer_spec.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/spec/styling_renderer_spec.lua)
- [spec/control_part_styling_spec.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/spec/control_part_styling_spec.lua)

## Work Items

- Add or expand specs to cover:
  - root resolution precedence
  - boolean false precedence
  - skin coercion of color inputs
  - theme/default fallback into root styling
  - `Texture` background image rendering path
  - `Sprite` background image rendering path
  - inset shadow inner-radius behavior
  - token/property-name normalization
  - part styling resolution with variants
- Use fake graphics objects where possible to verify draw calls deterministically.

## Suggested Files

- `spec/styling_resolution_spec.lua`
- `spec/styling_renderer_spec.lua`
- `spec/control_part_styling_spec.lua`

## Exit Criteria

- The failing cases identified in the review are each covered by an automated spec.
- The test suite protects against regressions in root styling, part styling, and image-backed backgrounds.
