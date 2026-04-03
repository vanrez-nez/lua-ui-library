# Phase 16 Task 01: Shared Quad Helpers And Foundation Surfaces

## Goal

Implement one reusable normalization path for four-side and four-corner inputs,
then wire Foundation-owned surfaces to it.

## Scope

Primary files:

- `lib/ui/core/insets.lua`
- `lib/ui/core/drawable_schema.lua`
- `lib/ui/layout/layout_node_schema.lua`
- `lib/ui/scene/stage_schema.lua`

Expected new files:

- `lib/ui/core/side_quad.lua`
- `lib/ui/core/corner_quad.lua`

## Work

1. Introduce a shared `SideQuad` helper.
2. Introduce a shared `CornerQuad` helper.
3. Refactor `Insets` to delegate side normalization to the shared helper while preserving its current semantic API.
4. Keep `padding`, `margin`, and `safeAreaInsets` aligned with the spec-owned `SideQuad input`.
5. Add public support for `paddingTop`, `paddingRight`, `paddingBottom`, `paddingLeft` where the accepted Foundation surface now requires them.
6. Add public support for `marginTop`, `marginRight`, `marginBottom`, `marginLeft` where the accepted Foundation surface now requires them.
7. Ensure aggregate-plus-flat merge behavior follows the Foundation override rule.

## Constraints

- Do not duplicate parsing logic between schema files.
- Do not move domain checks such as "non-negative only" into the generic helper unless the spec says that domain belongs to the family itself.
- Preserve deterministic failures for malformed quad shapes.

## Exit Criteria

- One reusable helper exists for side quads.
- One reusable helper exists for corner quads.
- `Insets` no longer owns unique side parsing logic.
- Foundation-owned schema surfaces match the new Foundation spec.
