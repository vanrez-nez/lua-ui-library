# Task 6: Correct Inner Geometry For Inset Shadows And Rounded Borders

## Summary

- Inset shadow clipping currently uses inner bounds with outer radii unchanged.
- The spec requires inset shadows to follow the inner rounded silhouette.

## Depends On

- [02-root-styling-resolution.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/02-root-styling-resolution.md)

## Primary Files

- [lib/ui/render/styling.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/render/styling.lua)
- [docs/spec/ui-styling-spec.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-styling-spec.md)

## Work Items

- Introduce inner-radius derivation based on resolved border widths.
- Apply the correct geometry for:
  - inset-shadow stencil
  - inset-shadow source shape
  - any future inner clipping helpers
- Review whether mixed per-side border widths need more exact inner-corner handling than the current average-width approach.

## Exit Criteria

- Inset shadows do not bulge past the true inner rounded shape.
- Rounded borders and inset shadows visually match when border widths are non-zero.
