local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Rule = require('lib.ui.utils.rule')
local CustomRules = require('lib.ui.schema.custom_rules')
local ResponsiveBreakpointsGate = require('lib.ui.core.responsive_breakpoints_gate')
local Responsive = require('lib.ui.layout.responsive')
local Enums = require('lib.ui.core.enums')
local Enum = require('lib.ui.utils.enum')

local enum_has = Enum.enum_has

local function validate_justify(_, value, _, level)
    if not Types.is_string(value) or not enum_has(Enums.Justify, value) then
        Assert.fail('Layout.justify must be "start", "center", "end", "space-between", or "space-around"', level)
    end
    return value
end

local function validate_align(_, value, _, level)
    if not Types.is_string(value) or not enum_has(Enums.Alignment, value) then
        Assert.fail('Layout.align must be "start", "center", "end", or "stretch"', level)
    end
    return value
end

local LAYOUT_NODE_SCHEMA = {
    gap = Rule.number({ min = 0, default = 0 }),
    padding = CustomRules.padding({ default = 0 }),
    paddingTop = Rule.number({ min = 0 }),
    paddingRight = Rule.number({ min = 0 }),
    paddingBottom = Rule.number({ min = 0 }),
    paddingLeft = Rule.number({ min = 0 }),
    wrap = Rule.boolean(false),
    justify = Rule.custom(validate_justify, { default = Enums.Justify.START }),
    align = Rule.custom(validate_align, { default = Enums.Alignment.START }),
    responsive = Rule.all_of({
        ResponsiveBreakpointsGate.with_peer('breakpoints'),
        Responsive.schema_rule('Layout')
    }),
}

return LAYOUT_NODE_SCHEMA
