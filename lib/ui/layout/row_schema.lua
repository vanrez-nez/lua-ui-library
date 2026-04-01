local Schema = require('lib.ui.utils.schema')
local LayoutNodeSchema = require('lib.ui.layout.layout_node_schema')

local ROW_SCHEMA = Schema.merge(LayoutNodeSchema, {
    direction = { type = 'string', default = 'ltr' }
})

return ROW_SCHEMA
