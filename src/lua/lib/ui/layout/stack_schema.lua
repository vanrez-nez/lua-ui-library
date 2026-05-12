local LayoutNodeSchema = require('lib.ui.layout.layout_node_schema')
local Utils = require('lib.ui.utils.common')

local STACK_SCHEMA = Utils.merge_tables(Utils.copy_table(LayoutNodeSchema), {})

return STACK_SCHEMA
