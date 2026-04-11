local LayoutNodeSchema = require('lib.ui.layout.layout_node_schema')
local Rule = require('lib.ui.utils.rule')
local Utils = require('lib.ui.utils.common')

local function mark_dirty(ctx)
    local method = rawget(ctx, 'markDirty')
    local current = rawget(ctx, '_pclass') or getmetatable(ctx)

    while method == nil and current ~= nil do
        method = rawget(current, 'markDirty')
        current = rawget(current, 'super')
    end

    if method ~= nil then
        method(ctx)
    end
end

local SAFE_AREA_CONTAINER_SCHEMA = Utils.merge_tables(Utils.copy_table(LayoutNodeSchema), {
    applyLeft = Rule.boolean(true, { set = mark_dirty }),
    applyTop = Rule.boolean(true, { set = mark_dirty }),
    applyRight = Rule.boolean(true, { set = mark_dirty }),
    applyBottom = Rule.boolean(true, { set = mark_dirty }),
})

return SAFE_AREA_CONTAINER_SCHEMA
