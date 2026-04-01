local LayoutNode = require('lib.ui.layout.layout_node')
local SequentialLayout = require('lib.ui.layout.sequential_layout')

local Column = LayoutNode:extends('Column')
Column._schema = require('lib.ui.layout.column_schema')

function Column:constructor(opts)
    LayoutNode.constructor(self, opts, nil, {
        allow_content_width = true,
        allow_content_height = true,
    })
    self._ui_layout_kind = 'Column'
end

function Column.new(opts)
    return Column(opts)
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
