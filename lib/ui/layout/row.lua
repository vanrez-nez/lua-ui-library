local Assert = require('lib.ui.core.assert')
local LayoutNode = require('lib.ui.layout.layout_node')
local SequentialLayout = require('lib.ui.layout.sequential_layout')

local Row = {}

local EXTRA_PUBLIC_KEYS = {
    direction = true,
}

local function validate_direction(value, level)
    if value ~= 'ltr' and value ~= 'rtl' then
        Assert.fail('Row.direction must be "ltr" or "rtl"', level or 1)
    end
end

local function set_direction(self, value, level)
    validate_direction(value, level)

    if self._public_values.direction == value then
        return value
    end

    self._public_values.direction = value
    self:markDirty()
    return value
end

Row.__index = function(self, key)
    local method = rawget(Row, key)

    if method ~= nil then
        return method
    end

    return LayoutNode.__index(self, key)
end

Row.__newindex = function(self, key, value)
    if key == 'direction' then
        set_direction(self, value, 2)
        return
    end

    LayoutNode.__newindex(self, key, value)
end

function Row.new(opts)
    opts = opts or {}

    if opts.direction == nil then
        opts.direction = 'ltr'
    end

    local self = {}
    LayoutNode._initialize(self, opts, EXTRA_PUBLIC_KEYS)
    validate_direction(opts.direction, 3)
    self._public_values.direction = opts.direction
    self._effective_values.direction = opts.direction
    self._ui_layout_kind = 'Row'
    return setmetatable(self, Row)
end

function Row:_apply_layout(stage)
    return SequentialLayout.apply(self, stage, {
        kind = 'Row',
        main_size_key = 'width',
        cross_size_key = 'height',
        main_min_key = 'minWidth',
        main_max_key = 'maxWidth',
        cross_min_key = 'minHeight',
        cross_max_key = 'maxHeight',
        main_position_key = 'x',
    })
end

return Row
