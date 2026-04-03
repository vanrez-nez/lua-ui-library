# Phase 16 Task 02: Styling Schema And Resolution

## Goal

Bring the styling public surface and runtime resolution path into line with the
new quad-family model.

## Scope

Primary files:

- `lib/ui/core/drawable_schema.lua`
- `lib/ui/render/styling_contract.lua`
- `lib/ui/render/styling.lua`
- `lib/ui/themes/default.lua`

## Work

1. Add `borderWidth` support that uses the shared `SideQuad input` contract.
2. Add `cornerRadius` support that uses the shared `CornerQuad input` contract.
3. Preserve flat member props:
   - `borderWidthTop/Right/Bottom/Left`
   - `cornerRadiusTopLeft/TopRight/BottomRight/BottomLeft`
4. Resolve aggregate-plus-flat styling inputs into canonical expanded props before rendering.
5. Keep renderer-facing props member-expanded only.
6. Review the default token table and document or implement the final policy for aggregate token keys vs member keys.

## Constraints

- The renderer must not become a second parser for public shorthand forms.
- Styling precedence remains field-by-field.
- Per-member styling props override the aggregate prop for their own member at the same precedence layer.

## Exit Criteria

- `Drawable` accepts aggregate and flat styling quad props as documented.
- Styling assembly expands aggregate inputs into canonical member props.
- `borderWidth` and `cornerRadius` behave consistently with the new spec.
- Token/default handling no longer contradicts the accepted styling property model.
