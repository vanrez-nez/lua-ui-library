local Assert = require('lib.ui.utils.assert')
local LayoutNode = require('lib.ui.layout.layout_node')
local SequentialLayout = require('lib.ui.layout.sequential_layout')

local Row = LayoutNode:extends('Row')
Row._schema = require('lib.ui.layout.row_schema')

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

    local public_values = rawget(self, '_public_values')
    if public_values and public_values.direction == value then
        return value
    end

    if public_values then
        public_values.direction = value
    end
    self:markDirty()
    return value
end



function Row:constructor(opts)
    LayoutNode.constructor(self, opts, nil, {
        allow_content_width = true,
        allow_content_height = true,
    })
    self._ui_layout_kind = 'Row'
end

function Row.new(opts)
    return Row(opts)
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
