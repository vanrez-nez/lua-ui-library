# Task 8: Tighten Failure Semantics And Defensive Checks

## Summary

- Tighten invalid-input handling so styling failures happen at deterministic resolution boundaries instead of leaking into draw-time behavior.

## Depends On

- [02-root-styling-resolution.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/02-root-styling-resolution.md)
- [04-skin-value-coercion.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/04-skin-value-coercion.md)
- [05-background-image-rendering.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/05-background-image-rendering.md)
- [06-inner-geometry.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/06-inner-geometry.md)

## Primary Files

- [lib/ui/render/styling.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/render/styling.lua)
- [lib/ui/core/drawable_schema.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/drawable_schema.lua)
- [lib/ui/render/color.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/render/color.lua)

## Work Items

- Audit all styling value domains against the spec:
  - non-negative sizes
  - opacity in `[0, 1]`
  - border enums
  - finite numeric inputs where required
- Ensure resolution-time failures are deterministic and not Love2D draw-time crashes.
- Review behavior for unsupported or absent graphics adapter functions and keep fallbacks predictable.

## Exit Criteria

- Invalid styling inputs fail at resolution/validation boundaries with actionable errors.
- Valid styling inputs do not depend on undefined graphics behavior.
