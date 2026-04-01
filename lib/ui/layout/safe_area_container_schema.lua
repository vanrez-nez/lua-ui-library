local LayoutNodeSchema = require('lib.ui.layout.layout_node_schema')
local Schema = require('lib.ui.utils.schema')

local SAFE_AREA_CONTAINER_SCHEMA = Schema.merge(LayoutNodeSchema, {
    applyLeft = { type = 'boolean', default = true },
    applyTop = { type = 'boolean', default = true },
    applyRight = { type = 'boolean', default = true },
    applyBottom = { type = 'boolean', default = true },
})

return SAFE_AREA_CONTAINER_SCHEMA
