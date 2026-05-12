local LayoutNodeSchema = require('lib.ui.layout.layout_node_schema')
local Rule = require('lib.ui.utils.rule')
local Utils = require('lib.ui.utils.common')

local SAFE_AREA_CONTAINER_SCHEMA = Utils.merge_tables(Utils.copy_table(LayoutNodeSchema), {
    applyLeft = Rule.boolean(true),
    applyTop = Rule.boolean(true),
    applyRight = Rule.boolean(true),
    applyBottom = Rule.boolean(true),
})

return SAFE_AREA_CONTAINER_SCHEMA
