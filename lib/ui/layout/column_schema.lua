local Schema = require('lib.ui.utils.schema')
local LayoutNodeSchema = require('lib.ui.layout.layout_node_schema')

local COLUMN_SCHEMA = Schema.merge(LayoutNodeSchema, {})

return COLUMN_SCHEMA
