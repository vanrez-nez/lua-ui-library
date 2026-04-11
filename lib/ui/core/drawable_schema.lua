local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Rule = require('lib.ui.utils.rule')
local SideQuad = require('lib.ui.core.side_quad')
local CornerQuad = require('lib.ui.core.corner_quad')
local Motion = require('lib.ui.motion')
local GraphicsValidation = require('lib.ui.render.graphics_validation')
local SpacingSchema = require('lib.ui.core.spacing_schema')

local ALIGNMENT_VALUES = {
    start = true,
    center = true,
    ['end'] = true,
    stretch = true,
}

local function validate_alignment(key, value, ctx, level)
    if not Types.is_string(value) or not ALIGNMENT_VALUES[value] then
        Assert.fail(
            'Drawable.' .. key .. ' must be "start", "center", "end", or "stretch"',
            level or 1
        )
    end
    return value
end

local function normalize_border_width(value, key, _, level)
    return SideQuad.normalize(value, {
        label = key,
        validate_member = SpacingSchema.check_non_negative_finite,
    }, level)
end

local function normalize_corner_radius(value, key, _, level)
    return CornerQuad.normalize(value, {
        label = key,
        validate_member = SpacingSchema.check_non_negative_finite,
    }, level)
end

local DRAWABLE_SCHEMA = {
    padding = SpacingSchema.padding_rule({ default = 0 }),
    paddingTop = SpacingSchema.non_negative_finite_rule(),
    paddingRight = SpacingSchema.non_negative_finite_rule(),
    paddingBottom = SpacingSchema.non_negative_finite_rule(),
    paddingLeft = SpacingSchema.non_negative_finite_rule(),
    margin = SpacingSchema.margin_rule({ default = 0 }),
    marginTop = SpacingSchema.finite_number_rule(),
    marginRight = SpacingSchema.finite_number_rule(),
    marginBottom = SpacingSchema.finite_number_rule(),
    marginLeft = SpacingSchema.finite_number_rule(),
    alignX = Rule.custom(validate_alignment, { default = 'start' }),
    alignY = Rule.custom(validate_alignment, { default = 'start' }),
    skin = Rule.table(),
    shader = Rule.custom(GraphicsValidation.validate_root_shader),
    opacity = Rule.opacity(GraphicsValidation.ROOT_OPACITY_DEFAULT),
    blendMode = Rule.enum(
        GraphicsValidation.ROOT_BLEND_MODE_VALUES,
        GraphicsValidation.ROOT_BLEND_MODE_DEFAULT
    ),
    mask = Rule.table(),
    motionPreset = Rule.custom(Motion.validate_motion_preset, { tier = 'heavy' }),
    motion = Rule.custom(Motion.validate_motion, { tier = 'heavy' }),

    -- background
    backgroundColor = Rule.color(),
    backgroundOpacity = Rule.opacity(),
    backgroundGradient = Rule.custom(GraphicsValidation.validate_gradient, { tier = 'always' }),
    backgroundImage = Rule.custom(GraphicsValidation.validate_texture_or_sprite_source, { tier = 'heavy' }),
    backgroundRepeatX = Rule.boolean(),
    backgroundRepeatY = Rule.boolean(),
    backgroundOffsetX = SpacingSchema.finite_number_rule(),
    backgroundOffsetY = SpacingSchema.finite_number_rule(),
    backgroundAlignX = Rule.enum(GraphicsValidation.SOURCE_ALIGN_VALUES),
    backgroundAlignY = Rule.enum(GraphicsValidation.SOURCE_ALIGN_VALUES),

    -- border
    borderColor = Rule.color(),
    borderOpacity = Rule.opacity(),
    borderWidth = Rule.normalize(normalize_border_width),
    borderWidthTop = SpacingSchema.non_negative_finite_rule(),
    borderWidthRight = SpacingSchema.non_negative_finite_rule(),
    borderWidthBottom = SpacingSchema.non_negative_finite_rule(),
    borderWidthLeft = SpacingSchema.non_negative_finite_rule(),
    borderStyle = Rule.enum({ 'smooth', 'rough' }),
    borderJoin = Rule.enum({ 'none', 'miter', 'bevel' }),
    borderMiterLimit = Rule.number({ min_exclusive = 0, finite = true }),
    borderPattern = Rule.enum({ 'solid', 'dashed' }),
    borderDashLength = Rule.number({ min_exclusive = 0, max = 255, finite = true }),
    borderGapLength = Rule.number({ min = 0, max = 255, finite = true }),
    borderDashOffset = SpacingSchema.finite_number_rule(),

    -- corner radius
    cornerRadius = Rule.normalize(normalize_corner_radius),
    cornerRadiusTopLeft = SpacingSchema.non_negative_finite_rule(),
    cornerRadiusTopRight = SpacingSchema.non_negative_finite_rule(),
    cornerRadiusBottomRight = SpacingSchema.non_negative_finite_rule(),
    cornerRadiusBottomLeft = SpacingSchema.non_negative_finite_rule(),

    -- shadow
    shadowColor = Rule.color(),
    shadowOpacity = Rule.opacity(),
    shadowOffsetX = SpacingSchema.finite_number_rule(),
    shadowOffsetY = SpacingSchema.finite_number_rule(),
    shadowBlur = SpacingSchema.non_negative_finite_rule(),
    shadowInset = Rule.boolean(),
}

return DRAWABLE_SCHEMA
