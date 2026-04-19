local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Rule = require('lib.ui.utils.rule')
local Motion = require('lib.ui.motion')
local GraphicsValidation = require('lib.ui.render.graphics_validation')
local Enums = require('lib.ui.core.enums')
local Enum = require('lib.ui.utils.enum')
local CustomRules = require('lib.ui.schema.custom_rules')

local enum_has = Enum.enum_has

local function validate_alignment(key, value, _, level)
    if not Types.is_string(value) or not enum_has(Enums.Alignment, value) then
        Assert.fail(
            'Drawable.' .. key .. ' must be "start", "center", "end", or "stretch"',
            level or 1
        )
    end
    return value
end

local function validate_border_width(key, value, level)
    CustomRules.validate_side_quad(
        key,
        value,
        CustomRules.validate_non_negative_finite,
        level or 1
    )
end

local function validate_corner_radius(key, value, level)
    CustomRules.validate_corner_quad(
        key,
        value,
        CustomRules.validate_non_negative_finite,
        level or 1
    )
end

local DRAWABLE_SCHEMA = {
    padding = CustomRules.padding({ default = 0 }),
    paddingTop = Rule.number({ min = 0 }),
    paddingRight = Rule.number({ min = 0 }),
    paddingBottom = Rule.number({ min = 0 }),
    paddingLeft = Rule.number({ min = 0 }),
    margin = CustomRules.margin({ default = 0 }),
    marginTop = Rule.number(),
    marginRight = Rule.number(),
    marginBottom = Rule.number(),
    marginLeft = Rule.number(),
    alignX = Rule.custom(validate_alignment, { default = Enums.Alignment.START }),
    alignY = Rule.custom(validate_alignment, { default = Enums.Alignment.START }),
    skin = Rule.table(),
    shader = Rule.custom(GraphicsValidation.validate_root_shader),
    opacity = CustomRules.opacity(GraphicsValidation.ROOT_OPACITY_DEFAULT),
    blendMode = Rule.enum(
        GraphicsValidation.ROOT_BLEND_MODE_VALUES,
        { default = GraphicsValidation.ROOT_BLEND_MODE_DEFAULT }
    ),
    mask = Rule.table(),
    motionPreset = Rule.custom(Motion.validate_motion_preset),
    motion = Rule.custom(Motion.validate_motion),

    -- background
    backgroundColor = CustomRules.color(),
    backgroundOpacity = CustomRules.opacity(),
    backgroundGradient = Rule.custom(GraphicsValidation.validate_gradient),
    backgroundImage = Rule.custom(GraphicsValidation.validate_texture_or_sprite_source),
    backgroundRepeatX = Rule.boolean(),
    backgroundRepeatY = Rule.boolean(),
    backgroundOffsetX = Rule.number(),
    backgroundOffsetY = Rule.number(),
    backgroundAlignX = Rule.enum(GraphicsValidation.SOURCE_ALIGN_VALUES),
    backgroundAlignY = Rule.enum(GraphicsValidation.SOURCE_ALIGN_VALUES),

    -- border
    borderColor = CustomRules.color(),
    borderOpacity = CustomRules.opacity(),
    borderWidth = Rule.custom(validate_border_width),
    borderWidthTop = Rule.number({ min = 0 }),
    borderWidthRight = Rule.number({ min = 0 }),
    borderWidthBottom = Rule.number({ min = 0 }),
    borderWidthLeft = Rule.number({ min = 0 }),
    borderStyle = Rule.enum(Enums.StrokeStyle),
    borderJoin = Rule.enum(Enums.StrokeJoin),
    borderMiterLimit = CustomRules.positive_finite(),
    borderPattern = Rule.enum(Enums.StrokePattern),
    borderDashLength = CustomRules.positive_finite({ max = 255 }),
    borderGapLength = Rule.number({ min = 0, max = 255 }),
    borderDashOffset = Rule.number(),

    -- corner radius
    cornerRadius = Rule.custom(validate_corner_radius),
    cornerRadiusTopLeft = Rule.number({ min = 0 }),
    cornerRadiusTopRight = Rule.number({ min = 0 }),
    cornerRadiusBottomRight = Rule.number({ min = 0 }),
    cornerRadiusBottomLeft = Rule.number({ min = 0 }),

    -- shadow
    shadowColor = CustomRules.color(),
    shadowOpacity = CustomRules.opacity(),
    shadowOffsetX = Rule.number(),
    shadowOffsetY = Rule.number(),
    shadowBlur = Rule.number({ min = 0 }),
    shadowInset = Rule.boolean(),
}

return DRAWABLE_SCHEMA
