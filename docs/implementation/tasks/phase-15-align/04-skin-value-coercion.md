# Task 4: Validate And Coerce Skin-Sourced Styling Inputs

## Summary

- Direct node props are schema-validated, but skin-provided values are currently copied raw into render props.
- This breaks accepted public input forms such as hex, named colors, and HSL when supplied through skins.

## Depends On

- [01-resolution-contract.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/01-resolution-contract.md)
- [02-root-styling-resolution.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/02-root-styling-resolution.md)

## Primary Files

- [lib/ui/render/styling.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/render/styling.lua)
- [lib/ui/core/drawable_schema.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/drawable_schema.lua)
- [lib/ui/render/color.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/render/color.lua)

## Work Items

- Introduce a styling normalization/coercion step for resolved values before paint.
- Reuse existing validators and `Color.resolve` rather than re-implementing parsing.
- Ensure skin, token, and default values are normalized into the same resolved runtime shape expected by the renderer.
- Apply the same deterministic failure semantics to non-instance sources.

## Exit Criteria

- `backgroundColor = "#fff"` provided via a skin resolves correctly.
- Invalid skin color strings fail deterministically.
- The renderer only sees normalized values.
