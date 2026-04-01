local Schema = require('lib.ui.utils.schema')
local LayoutNodeSchema = require('lib.ui.layout.layout_node_schema')

local STACK_SCHEMA = Schema.merge(LayoutNodeSchema, {})

return STACK_SCHEMA
