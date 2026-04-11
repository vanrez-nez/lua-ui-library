local LayoutNodeSchema = require('lib.ui.layout.layout_node_schema')
local Direction = require('lib.ui.layout.direction')
local Utils = require('lib.ui.utils.common')

local ROW_SCHEMA = Utils.merge_tables(Utils.copy_table(LayoutNodeSchema), {
    direction = Direction.schema_rule('Row'),
})

return ROW_SCHEMA
