local LayoutNode = require('lib.ui.layout.layout_node')
local SequentialLayout = require('lib.ui.layout.sequential_layout')

local Column = {}

Column.__index = function(self, key)
    local method = rawget(Column, key)

    if method ~= nil then
        return method
    end

    return LayoutNode.__index(self, key)
end

Column.__newindex = LayoutNode.__newindex

function Column.new(opts)
    local self = {}
    LayoutNode._initialize(self, opts)
    self._ui_layout_kind = 'Column'
    return setmetatable(self, Column)
end

function Column:_apply_layout(stage)
    return SequentialLayout.apply(self, stage, {
        kind = 'Column',
        main_size_key = 'height',
        cross_size_key = 'width',
        main_min_key = 'minHeight',
        main_max_key = 'maxHeight',
        cross_min_key = 'minWidth',
        cross_max_key = 'maxWidth',
        main_position_key = 'y',
    })
end

return Column
