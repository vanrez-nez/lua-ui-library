local Rule = require('lib.ui.utils.rule')
local Motion = require('lib.ui.motion')
local GraphicsValidation = require('lib.ui.render.graphics_validation')
local Enums = require('lib.ui.core.enums')
local CustomRules = require('lib.ui.schema.custom_rules')
local StyleScope = require('lib.ui.render.style_scope')

local opacity_rule = Rule.number({
    min = 0,
    max = 1,
    default = GraphicsValidation.ROOT_OPACITY_DEFAULT
})

local DRAWABLE_SCHEMA = {
    padding = CustomRules.padding({ default = 0 }),
    paddingTop = Rule.number({ min = 0, optional = true }),
    paddingRight = Rule.number({ min = 0, optional = true }),
    paddingBottom = Rule.number({ min = 0, optional = true }),
    paddingLeft = Rule.number({ min = 0, optional = true }),
    margin = CustomRules.margin({ default = 0 }),
    marginTop = Rule.number({ optional = true }),
    marginRight = Rule.number({ optional = true }),
    marginBottom = Rule.number({ optional = true }),
    marginLeft = Rule.number({ optional = true }),
    alignX = Rule.enum(Enums.Alignment, { default = Enums.Alignment.START }),
    alignY = Rule.enum(Enums.Alignment, { default = Enums.Alignment.START }),
    style_scope = Rule.custom(StyleScope.assert, { optional = true }),
    style_variant = Rule.string({ optional = true }),
    skin = Rule.table({ optional = true }),
    shader = Rule.custom(GraphicsValidation.validate_root_shader, { optional = true }),
    opacity = opacity_rule,
    blendMode = Rule.enum(
        GraphicsValidation.ROOT_BLEND_MODE_VALUES,
        { default = GraphicsValidation.ROOT_BLEND_MODE_DEFAULT }
    ),
    mask = Rule.table({ optional = true }),
    motionPreset = Rule.custom(Motion.validate_motion_preset, { optional = true }),
    motion = Rule.custom(Motion.validate_motion, { optional = true }),

    -- background
    backgroundColor = Rule.optional(CustomRules.color()),
    backgroundOpacity = opacity_rule,
    backgroundGradient = Rule.custom(GraphicsValidation.validate_gradient, { optional = true }),
    backgroundImage = Rule.custom(GraphicsValidation.validate_texture_or_sprite_source, { optional = true }),
    backgroundRepeatX = Rule.boolean({ optional = true }),
    backgroundRepeatY = Rule.boolean({ optional = true }),
    backgroundOffsetX = Rule.number({ optional = true }),
    backgroundOffsetY = Rule.number({ optional = true }),
    backgroundAlignX = Rule.enum(GraphicsValidation.SOURCE_ALIGN_VALUES, { optional = true }),
    backgroundAlignY = Rule.enum(GraphicsValidation.SOURCE_ALIGN_VALUES, { optional = true }),

    -- border
    borderColor = Rule.optional(CustomRules.color()),
    borderOpacity = opacity_rule,
    borderWidth = Rule.optional(CustomRules.border_width()),
    borderWidthTop = Rule.number({ min = 0, optional = true }),
    borderWidthRight = Rule.number({ min = 0, optional = true }),
    borderWidthBottom = Rule.number({ min = 0, optional = true }),
    borderWidthLeft = Rule.number({ min = 0, optional = true }),
    borderStyle = Rule.enum(Enums.StrokeStyle, { optional = true }),
    borderJoin = Rule.enum(Enums.StrokeJoin, { optional = true }),
    borderMiterLimit = Rule.number({ min = 0, optional = true }),
    borderPattern = Rule.enum(Enums.StrokePattern, { optional = true }),
    borderDashLength = Rule.number({ min = 0, max = 255, optional = true }),
    borderGapLength = Rule.number({ min = 0, max = 255, optional = true }),
    borderDashOffset = Rule.number({ optional = true }),

    -- corner radius
    cornerRadius = Rule.optional(CustomRules.corner_quad()),
    cornerRadiusTopLeft = Rule.number({ min = 0, optional = true }),
    cornerRadiusTopRight = Rule.number({ min = 0, optional = true }),
    cornerRadiusBottomRight = Rule.number({ min = 0, optional = true }),
    cornerRadiusBottomLeft = Rule.number({ min = 0, optional = true }),

    -- shadow
    shadowColor = Rule.optional(CustomRules.color()),
    shadowOpacity = opacity_rule,
    shadowOffsetX = Rule.number({ optional = true }),
    shadowOffsetY = Rule.number({ optional = true }),
    shadowBlur = Rule.number({ min = 0, optional = true }),
    shadowInset = Rule.boolean({ optional = true }),
}

return DRAWABLE_SCHEMA
