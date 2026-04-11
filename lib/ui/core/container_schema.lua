local Assert = require('lib.ui.utils.assert')
local Rule = require('lib.ui.utils.rule')
local Motion = require('lib.ui.motion')
local ResponsiveBreakpointsGate = require('lib.ui.core.responsive_breakpoints_gate')
local MathUtils = require('lib.ui.utils.math')

local function validate_container_size(key, value, ctx, level)
    local prop_name = key:match("%.([^%.]+)$") or key
    local allow_content = ctx._config['allow_content_' .. prop_name] == true

    if value == 'content' then
        if not allow_content then
            Assert.fail(
                tostring(key) ..
                    '="content" is only supported by layout nodes with an intrinsic measurement rule',
                (level or 1) + 1
            )
        end
        return value
    end

    if value == 'fill' or type(value) == 'number' then
        return value
    end

    if MathUtils.is_percentage_string(value) then
        return value
    end

    Assert.fail(
        key .. ' must be a number, "content", "fill", or a percentage string',
        level or 1
    )
end

local CONTAINER_SCHEMA = {
    id = Rule.string({ non_empty = true }),
    name = Rule.string({ non_empty = true }),
    tag = Rule.string({ non_empty = true }),
    internal = Rule.boolean(false),
    visible = Rule.boolean(true),
    interactive = Rule.boolean(false),
    enabled = Rule.boolean(true),
    focusable = Rule.boolean(false),
    clipChildren = Rule.boolean(false),
    zIndex = Rule.number({ default = 0 }),
    anchorX = Rule.number({ default = 0 }),
    anchorY = Rule.number({ default = 0 }),
    pivotX = Rule.number({ default = 0.5 }),
    pivotY = Rule.number({ default = 0.5 }),
    x = Rule.number({ default = 0 }),
    y = Rule.number({ default = 0 }),
    width = Rule.custom(validate_container_size, { default = 0 }),
    height = Rule.custom(validate_container_size, { default = 0 }),
    minWidth = Rule.number(),
    minHeight = Rule.number(),
    maxWidth = Rule.number(),
    maxHeight = Rule.number(),
    scaleX = Rule.number({ default = 1 }),
    scaleY = Rule.number({ default = 1 }),
    rotation = Rule.number({ default = 0 }),
    skewX = Rule.number({ default = 0 }),
    skewY = Rule.number({ default = 0 }),
    breakpoints = Rule.gate(
        ResponsiveBreakpointsGate.with_peer('responsive', {
            require_declared_peer = true,
        }),
        Rule.table()
    ),
    motionPreset = Rule.custom(Motion.validate_motion_preset, { tier = 'heavy' }),
    motion = Rule.custom(Motion.validate_motion, { tier = 'heavy' }),
}

return CONTAINER_SCHEMA
