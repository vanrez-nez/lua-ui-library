local Rule = require('lib.ui.utils.rule')
local CustomRules = require('lib.ui.schema.custom_rules')
local Motion = require('lib.ui.motion')

local CONTAINER_SCHEMA = {
    id = Rule.string({ non_empty = true, optional = true }),
    name = Rule.string({ non_empty = true, optional = true }),
    tag = Rule.string({ non_empty = true, optional = true }),
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
    width = CustomRules.size_value({
        default = 0,
        allow_content = true
    }),
    height = CustomRules.size_value({
        default = 0,
        allow_content = true
    }),
    minWidth = Rule.number({ optional = true }),
    minHeight = Rule.number({ optional = true }),
    maxWidth = Rule.number({ optional = true }),
    maxHeight = Rule.number({ optional = true }),
    scaleX = Rule.number({ default = 1 }),
    scaleY = Rule.number({ default = 1 }),
    rotation = Rule.number({ default = 0 }),
    skewX = Rule.number({ default = 0 }),
    skewY = Rule.number({ default = 0 }),
    breakpoints = Rule.table({ optional = true }),
    motionPreset = Rule.custom(Motion.validate_motion_preset, { optional = true }),
    motion = Rule.custom(Motion.validate_motion, { optional = true }),
}

return CONTAINER_SCHEMA
