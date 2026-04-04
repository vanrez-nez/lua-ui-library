local Schema = require('lib.ui.utils.schema')
local LayoutNodeSchema = require('lib.ui.layout.layout_node_schema')
local Direction = require('lib.ui.layout.direction')

local FLOW_SCHEMA = Schema.merge(LayoutNodeSchema, {
    direction = Direction.schema_rule('Flow')
})

return FLOW_SCHEMA
