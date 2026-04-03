# Task 1: Define The Public Styling Resolution Contract In Code

## Summary

- Decide one canonical runtime shape for resolved styling props.
- Decide how component/part/variant-specific token values map onto spec-owned flat styling properties.
- Document the mapping boundary between:
  - public styling props
  - control-level part semantics
  - theme token keys

## Depends On

- None.

## Primary Files

- [lib/ui/render/styling.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/render/styling.lua)
- [lib/ui/themes/runtime.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/themes/runtime.lua)
- [lib/ui/themes/resolver.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/themes/resolver.lua)
- [docs/spec/ui-styling-spec.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-styling-spec.md)

## Work Items

- Add a small design note or inline module comments near the styling assembly/resolution path.
- Explicitly define whether token keys remain control-specific internally or are normalized into spec-owned flat props before rendering.
- Remove ambiguity around root styling versus named part styling.

## Exit Criteria

- A developer can point to one code path that owns styling resolution for root and part styling.
- The property names consumed by the renderer are the same property names defined by the styling spec.
