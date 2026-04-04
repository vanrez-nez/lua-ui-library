-- UI Styling Contract
--
-- This module centralizes the stable styling-property vocabulary owned by
-- docs/spec/ui-styling-spec.md. It is intentionally narrow:
-- - it defines the flat styling property families carried by Drawable roots
-- - it documents that resolved styling is paint-ready and field-by-field
-- - it does not invent aliases, grouped style objects, or implicit selectors
--
-- Spec anchors:
-- - ui-styling-spec §4B: styling resolution is field-by-field and deterministic
-- - ui-styling-spec §4C: Drawable is the base root styling carrier
-- - ui-styling-spec §14: no undocumented shorthand, alias, convenience schema,
--   or grouped style object is implied beyond the flat property families
-- - ui-foundation-spec §8.4: token binding is explicit; there is no implicit
--   CSS-like or descendant-based token matching

local StylingContract = {}

-- The root styling carrier uses the flat property families defined by
-- docs/spec/ui-styling-spec.md §§6-9.
StylingContract.ROOT_PROPERTY_KEYS = {
    -- background (§6.2)
    'backgroundColor', 'backgroundOpacity', 'backgroundGradient', 'backgroundImage',
    'backgroundRepeatX', 'backgroundRepeatY', 'backgroundOffsetX', 'backgroundOffsetY',
    'backgroundAlignX', 'backgroundAlignY',

    -- border (§7.1)
    'borderColor', 'borderOpacity', 'borderWidth', 'borderWidthTop', 'borderWidthRight',
    'borderWidthBottom', 'borderWidthLeft', 'borderStyle', 'borderJoin', 'borderMiterLimit',
    'borderPattern', 'borderDashLength', 'borderGapLength',

    -- corner radius (§8)
    'cornerRadius', 'cornerRadiusTopLeft', 'cornerRadiusTopRight', 'cornerRadiusBottomRight', 'cornerRadiusBottomLeft',

    -- shadow (§9.1)
    'shadowColor', 'shadowOpacity', 'shadowOffsetX', 'shadowOffsetY', 'shadowBlur', 'shadowInset',
}

-- docs/spec/ui-styling-spec.md §12
StylingContract.MOTION_CAPABLE_KEYS = {
    'backgroundColor', 'backgroundOpacity',
    'borderColor', 'borderOpacity',
    'borderWidth',
    'borderWidthTop', 'borderWidthRight', 'borderWidthBottom', 'borderWidthLeft',
    'cornerRadius', 'cornerRadiusTopLeft', 'cornerRadiusTopRight', 'cornerRadiusBottomRight', 'cornerRadiusBottomLeft',
    'shadowColor', 'shadowOpacity', 'shadowOffsetX', 'shadowOffsetY', 'shadowBlur',
}

-- docs/spec/ui-foundation-spec.md §8.4
StylingContract.TOKEN_KEY_FORMAT = '<component>.<part>.<property>[.<variant>]'

return StylingContract
