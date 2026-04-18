local Rule = require('lib.ui.utils.rule')
local Motion = require('lib.ui.motion')

local CONTAINER_SCHEMA = {
    id = Rule.string({ non_empty = true }),
    name = Rule.string({ non_empty = true }),
    tag = Rule.string({ non_empty = true }),
    internal = Rule.boolean(false),
    visible = Rule.boolean({ default = true }),
    interactive = Rule.boolean(false),
    enabled = Rule.boolean({ default = true }),
    focusable = Rule.boolean(false),
    clipChildren = Rule.boolean({ default = false }),
    zIndex = Rule.number({ default = 0 }),
    anchorX = Rule.number({ default = 0 }),
    anchorY = Rule.number({ default = 0 }),
    pivotX = Rule.number({ default = 0.5 }),
    pivotY = Rule.number({ default = 0.5 }),
    x = Rule.number({ default = 0 }),
    y = Rule.number({ default = 0 }),
    width = Rule.size_value({
        default = 0,
        allow_content = true
    }),
    height = Rule.size_value({
        default = 0,
        allow_content = true
    }),
    minWidth = Rule.number(),
    minHeight = Rule.number(),
    maxWidth = Rule.number(),
    maxHeight = Rule.number(),
    scaleX = Rule.number({ default = 1 }),
    scaleY = Rule.number({ default = 1 }),
    rotation = Rule.number({ default = 0 }),
    skewX = Rule.number({ default = 0 }),
    skewY = Rule.number({ default = 0 }),
    breakpoints = Rule.table(),
    motionPreset = Rule.custom(Motion.validate_motion_preset),
    motion = Rule.custom(Motion.validate_motion),
}

return CONTAINER_SCHEMA