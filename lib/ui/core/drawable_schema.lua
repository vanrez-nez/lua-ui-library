local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Rule = require('lib.ui.utils.rule')
local Motion = require('lib.ui.motion')
local GraphicsValidation = require('lib.ui.render.graphics_validation')
local Enums = require('lib.ui.core.enums')
local Enum = require('lib.ui.utils.enum')
local CustomRules = require('lib.ui.schema.custom_rules')

local enum_has = Enum.enum_has
local non_negative_number_rule = Rule.number({ min = 0 })
local root_opacity_rule = Rule.number({
    min = 0,
    max = 1,
    default = GraphicsValidation.ROOT_OPACITY_DEFAULT,
})
local opacity_rule = Rule.number({ min = 0, max = 1 })

local function validate_alignment(key, value, _, level)
    if not Types.is_string(value) or not enum_has(Enums.Alignment, value) then
        Assert.fail(
            'Drawable.' .. key .. ' must be "start", "center", "end", or "stretch"',
            level or 1
        )
    end
    return value
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
    opacity = root_opacity_rule,
    blendMode = Rule.enum(
        GraphicsValidation.ROOT_BLEND_MODE_VALUES,
        { default = GraphicsValidation.ROOT_BLEND_MODE_DEFAULT }
    ),
    mask = Rule.table(),
    motionPreset = Rule.custom(Motion.validate_motion_preset),
    motion = Rule.custom(Motion.validate_motion),

    -- background
    backgroundColor = CustomRules.color(),
    backgroundOpacity = opacity_rule,
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
    borderOpacity = opacity_rule,
    borderWidth = CustomRules.side_quad(non_negative_number_rule),
    borderWidthTop = Rule.number({ min = 0 }),
    borderWidthRight = Rule.number({ min = 0 }),
    borderWidthBottom = Rule.number({ min = 0 }),
    borderWidthLeft = Rule.number({ min = 0 }),
    borderStyle = Rule.enum(Enums.StrokeStyle),
    borderJoin = Rule.enum(Enums.StrokeJoin),
    borderMiterLimit = Rule.number({ min = 0 }),
    borderPattern = Rule.enum(Enums.StrokePattern),
    borderDashLength = Rule.number({ min = 0, max = 255 }),
    borderGapLength = Rule.number({ min = 0, max = 255 }),
    borderDashOffset = Rule.number(),

    -- corner radius
    cornerRadius = CustomRules.corner_quad(non_negative_number_rule),
    cornerRadiusTopLeft = Rule.number({ min = 0 }),
    cornerRadiusTopRight = Rule.number({ min = 0 }),
    cornerRadiusBottomRight = Rule.number({ min = 0 }),
    cornerRadiusBottomLeft = Rule.number({ min = 0 }),

    -- shadow
    shadowColor = CustomRules.color(),
    shadowOpacity = opacity_rule,
    shadowOffsetX = Rule.number(),
    shadowOffsetY = Rule.number(),
    shadowBlur = Rule.number({ min = 0 }),
    shadowInset = Rule.boolean(),
}

return DRAWABLE_SCHEMA
