# Task 2: Replace `Styling.assemble_props` With Real Spec Resolution

## Summary

- `Styling.assemble_props` currently resolves only `node[key]` and `skin[key]`.
- Theme tokens and library defaults never participate in root styling resolution.

## Depends On

- [01-resolution-contract.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/01-resolution-contract.md)

## Primary Files

- [lib/ui/render/styling.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/render/styling.lua)
- [lib/ui/themes/runtime.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/themes/runtime.lua)
- [lib/ui/themes/resolver.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/themes/resolver.lua)
- [lib/ui/core/drawable.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/drawable.lua)

## Work Items

- Refactor [`lib/ui/render/styling.lua`](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/render/styling.lua) so prop assembly uses [`ThemeRuntime.resolve`](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/themes/runtime.lua) or an equivalent single resolution entry point.
- Preserve boolean false semantics for `backgroundRepeatX`, `backgroundRepeatY`, and `shadowInset`.
- Support:
  - direct instance value
  - instance override table where applicable
  - skin value
  - active theme token
  - library default
- Keep the result field-by-field and deterministic.

## Exit Criteria

- A `Drawable` with no direct styling props can still resolve styling from the active theme and defaults.
- A direct `false` value wins over skin/theme/default rather than falling through.
- Missing required styling tokens fail only where the spec expects failure.
