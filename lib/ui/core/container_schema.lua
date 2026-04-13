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
    visible = Rule.boolean({ default = true, deferred = true }),
    interactive = Rule.boolean(false),
    enabled = Rule.boolean({ default = true, deferred = true }),
    focusable = Rule.boolean(false),
    clipChildren = Rule.boolean({ default = false, deferred = true }),
    zIndex = Rule.number({ default = 0, deferred = true }),
    anchorX = Rule.number({ default = 0, deferred = true }),
    anchorY = Rule.number({ default = 0, deferred = true }),
    pivotX = Rule.number({ default = 0.5, deferred = true }),
    pivotY = Rule.number({ default = 0.5, deferred = true }),
    x = Rule.number({ default = 0, deferred = true }),
    y = Rule.number({ default = 0, deferred = true }),
    width = Rule.custom(validate_container_size, { default = 0, deferred = true }),
    height = Rule.custom(validate_container_size, { default = 0, deferred = true }),
    minWidth = Rule.number({ deferred = true }),
    minHeight = Rule.number({ deferred = true }),
    maxWidth = Rule.number({ deferred = true }),
    maxHeight = Rule.number({ deferred = true }),
    scaleX = Rule.number({ default = 1, deferred = true }),
    scaleY = Rule.number({ default = 1, deferred = true }),
    rotation = Rule.number({ default = 0, deferred = true }),
    skewX = Rule.number({ default = 0, deferred = true }),
    skewY = Rule.number({ default = 0, deferred = true }),
    breakpoints = Rule.gate(
        ResponsiveBreakpointsGate.with_peer('responsive', {
            require_declared_peer = true,
        }),
        Rule.table({ deferred = true })
    ),
    motionPreset = Rule.custom(Motion.validate_motion_preset, { tier = 'heavy' }),
    motion = Rule.custom(Motion.validate_motion, { tier = 'heavy' }),
}

return CONTAINER_SCHEMA
