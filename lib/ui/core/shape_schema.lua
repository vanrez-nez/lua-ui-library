local Rule = require('lib.ui.utils.rule')
local GraphicsValidation = require('lib.ui.render.graphics_validation')

return {
    fillColor = Rule.color({ 1, 1, 1, 1 }),
    fillOpacity = Rule.opacity(1),
    fillGradient = Rule.custom(GraphicsValidation.validate_gradient, { tier = 'always' }),
    fillTexture = Rule.custom(GraphicsValidation.validate_texture_or_sprite_source, { tier = 'heavy' }),
    fillRepeatX = Rule.boolean(false),
    fillRepeatY = Rule.boolean(false),
    fillOffsetX = Rule.number({ finite = true, default = 0 }),
    fillOffsetY = Rule.number({ finite = true, default = 0 }),
    fillAlignX = Rule.enum(GraphicsValidation.SOURCE_ALIGN_VALUES, 'center'),
    fillAlignY = Rule.enum(GraphicsValidation.SOURCE_ALIGN_VALUES, 'center'),
    strokeColor = Rule.color(),
    strokeOpacity = Rule.opacity(1),
    strokeWidth = Rule.number({ min = 0, finite = true, default = 0 }),
    strokeStyle = Rule.enum({ 'smooth', 'rough' }, 'smooth'),
    strokeJoin = Rule.enum({ 'miter', 'bevel', 'none' }, 'miter'),
    strokeMiterLimit = Rule.number({ min_exclusive = 0, finite = true, default = 10 }),
    strokePattern = Rule.enum({ 'solid', 'dashed' }, 'solid'),
    strokeDashLength = Rule.number({ min_exclusive = 0, finite = true, default = 8 }),
    strokeGapLength = Rule.number({ min = 0, finite = true, default = 4 }),
    strokeDashOffset = Rule.number({ finite = true, default = 0 }),
    shader = Rule.custom(GraphicsValidation.validate_root_shader),
    opacity = Rule.opacity(GraphicsValidation.ROOT_OPACITY_DEFAULT),
    blendMode = Rule.enum(
        GraphicsValidation.ROOT_BLEND_MODE_VALUES,
        GraphicsValidation.ROOT_BLEND_MODE_DEFAULT
    ),
}
