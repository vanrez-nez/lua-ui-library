local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Rule = require('lib.ui.utils.rule')
local SpacingSchema = require('lib.ui.core.spacing_schema')
local ResponsiveBreakpointsGate = require('lib.ui.core.responsive_breakpoints_gate')
local Responsive = require('lib.ui.layout.responsive')

local JUSTIFY_VALUES = {
    start = true,
    center = true,
    ['end'] = true,
    ['space-between'] = true,
    ['space-around'] = true,
}

local ALIGN_VALUES = {
    start = true,
    center = true,
    ['end'] = true,
    stretch = true,
}

local function mark_dirty(ctx)
    local method = rawget(ctx, 'markDirty')
    local current = rawget(ctx, '_pclass') or getmetatable(ctx)

    while method == nil and current ~= nil do
        method = rawget(current, 'markDirty')
        current = rawget(current, 'super')
    end

    if method ~= nil then
        method(ctx)
    end
end

local function validate_justify(_, value, _, level)
    if not Types.is_string(value) or not JUSTIFY_VALUES[value] then
        Assert.fail('Layout.justify must be "start", "center", "end", "space-between", or "space-around"', level)
    end
    return value
end

local function validate_align(_, value, _, level)
    if not Types.is_string(value) or not ALIGN_VALUES[value] then
        Assert.fail('Layout.align must be "start", "center", "end", or "stretch"', level)
    end
    return value
end

local LAYOUT_NODE_SCHEMA = {
    gap = SpacingSchema.non_negative_finite_rule({ default = 0, set = mark_dirty }),
    padding = SpacingSchema.padding_rule({ default = 0, set = mark_dirty }),
    paddingTop = SpacingSchema.non_negative_finite_rule({ set = mark_dirty }),
    paddingRight = SpacingSchema.non_negative_finite_rule({ set = mark_dirty }),
    paddingBottom = SpacingSchema.non_negative_finite_rule({ set = mark_dirty }),
    paddingLeft = SpacingSchema.non_negative_finite_rule({ set = mark_dirty }),
    wrap = Rule.boolean(false, { set = mark_dirty }),
    justify = Rule.custom(validate_justify, {
        default = 'start',
        set = mark_dirty,
    }),
    align = Rule.custom(validate_align, {
        default = 'start',
        set = mark_dirty,
    }),
    responsive = Rule.gate(
        ResponsiveBreakpointsGate.with_peer('breakpoints'),
        Responsive.schema_rule('Layout', { set = mark_dirty })
    ),
}

return LAYOUT_NODE_SCHEMA
