# Task 3: Normalize Token Catalogs To Spec-Owned Styling Fields

## Summary

- Default tokens use mixed vocabularies such as `fillColor`, `radius`, and `borderWidth`.
- Those do not directly satisfy the styling property family defined by the spec.
- The docs/spec set stabilizes the token naming schema, but not every concrete
  part-property binding currently present in `lib/ui/themes/default.lua`.

## Depends On

- [01-resolution-contract.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/01-resolution-contract.md)

## Primary Files

- [lib/ui/themes/default.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/themes/default.lua)
- [lib/ui/themes/resolver.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/themes/resolver.lua)
- [lib/ui/render/styling.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/render/styling.lua)

## Work Items

- Re-check `docs/spec` before changing any concrete token key. Only bindings
  that are actually documented by the library should be treated as stable.
- Audit [`lib/ui/themes/default.lua`](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/themes/default.lua).
- Replace ambiguous token/property names with either:
  - spec-owned styling field names, or
  - a documented control-part token layer that is normalized into spec-owned styling props before render.
- Do not rename keys such as `textArea.scroll region.*` unless the docs/spec
  show they are invalid. `scroll region` is a documented stable part name in
  [`docs/spec/ui-controls-spec.md`](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-controls-spec.md).
- Make per-side and per-corner defaults explicit where needed.

## Exit Criteria

- No token required for styling render depends on unofficial property names like `fillColor` or `radius`.
- Default tokens can fully drive the renderer without translation bugs.
- If the necessary part-property bindings are not yet documented in `docs/spec`,
  the implementation is left unchanged and the gap is called out explicitly
  rather than normalized by guesswork.
