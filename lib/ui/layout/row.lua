local LayoutNode = require('lib.ui.layout.layout_node')
local SequentialLayout = require('lib.ui.layout.sequential_layout')

local Row = LayoutNode:extends('Row')
Row._schema = require('lib.ui.layout.row_schema')

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
