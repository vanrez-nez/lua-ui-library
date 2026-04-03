local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Insets = require('lib.ui.core.insets')

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

local LAYOUT_NODE_SCHEMA = {
    gap = { type = 'number', default = 0, set = function(ctx) ctx:markDirty() end },
    padding = { 
        validate = function(key, value) return Insets.normalize(value) end, 
        default = 0,
        set = function(ctx) ctx:markDirty() end
    },
    paddingTop = { type = 'number', set = function(ctx) ctx:markDirty() end },
    paddingRight = { type = 'number', set = function(ctx) ctx:markDirty() end },
    paddingBottom = { type = 'number', set = function(ctx) ctx:markDirty() end },
    paddingLeft = { type = 'number', set = function(ctx) ctx:markDirty() end },
    wrap = { type = 'boolean', default = false, set = function(ctx) ctx:markDirty() end },
    justify = { 
        validate = function(key, value, ctx, level)
            if not Types.is_string(value) or not JUSTIFY_VALUES[value] then
                Assert.fail('Layout.justify must be "start", "center", "end", "space-between", or "space-around"', level)
            end
            return value
        end,
        default = 'start',
        set = function(ctx) ctx:markDirty() end
    },
    align = { 
        validate = function(key, value, ctx, level)
            if not Types.is_string(value) or not ALIGN_VALUES[value] then
                Assert.fail('Layout.align must be "start", "center", "end", or "stretch"', level)
            end
            return value
        end,
        default = 'start',
        set = function(ctx) ctx:markDirty() end
    },
    responsive = {
        validate = function(key, value, ctx, level)
            if value ~= nil then
                local public_values = rawget(ctx, '_public_values')
                if public_values and public_values.breakpoints ~= nil then
                    Assert.fail('responsive and breakpoints cannot both be supplied on the same node', level)
                end
                if not Types.is_table(value) and not Types.is_function(value) then
                    Assert.fail('Layout.responsive must be a table or a function', level)
                end
            end
            return value
        end,
        set = function(ctx) ctx:markDirty() end
    }
}

return LAYOUT_NODE_SCHEMA
