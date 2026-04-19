local Rule = require('lib.ui.utils.rule')
local CustomRules = require('lib.ui.schema.custom_rules')
local GraphicsValidation = require('lib.ui.render.graphics_validation')
local Enums = require('lib.ui.core.enums')

return {
    fillColor = CustomRules.color({ 1, 1, 1, 1 }),
    fillOpacity = CustomRules.opacity(1),
    fillGradient = Rule.custom(GraphicsValidation.validate_gradient),
    fillTexture = Rule.custom(GraphicsValidation.validate_texture_or_sprite_source),
    fillRepeatX = Rule.boolean(false),
    fillRepeatY = Rule.boolean(false),
    fillOffsetX = Rule.number({ finite = true, default = 0 }),
    fillOffsetY = Rule.number({ finite = true, default = 0 }),
    fillAlignX = Rule.enum(Enums.SourceAlign, { default = Enums.SourceAlign.CENTER }),
    fillAlignY = Rule.enum(Enums.SourceAlign, { default = Enums.SourceAlign.CENTER }),
    strokeColor = CustomRules.color(),
    strokeOpacity = CustomRules.opacity(1),
    strokeWidth = Rule.number({ min = 0, finite = true, default = 0 }),
    strokeStyle = Rule.enum(Enums.StrokeStyle, { default = Enums.StrokeStyle.SMOOTH }),
    strokeJoin = Rule.enum(Enums.StrokeJoin, { default = Enums.StrokeJoin.MITER }),
    strokeMiterLimit = CustomRules.positive_finite({ default = 10 }),
    strokePattern = Rule.enum(Enums.StrokePattern, { default = Enums.StrokePattern.SOLID }),
    strokeDashLength = CustomRules.positive_finite({ default = 8 }),
    strokeGapLength = Rule.number({ min = 0, finite = true, default = 4 }),
    strokeDashOffset = Rule.number({ finite = true, default = 0 }),
    shader = Rule.custom(GraphicsValidation.validate_root_shader),
    opacity = CustomRules.opacity(GraphicsValidation.ROOT_OPACITY_DEFAULT),
    blendMode = Rule.enum(Enums.BlendMode, { default = GraphicsValidation.ROOT_BLEND_MODE_DEFAULT }
    ),
}
