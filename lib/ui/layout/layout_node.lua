local Assert = require('lib.ui.utils.assert')
local Container = require('lib.ui.core.container')
local Types = require('lib.ui.utils.types')
local Rectangle = require('lib.ui.core.rectangle')
local Utils = require('lib.ui.utils.common')
local LayoutNodeSchema = require('lib.ui.layout.layout_node_schema')
-- Proxy removed: DirtyProps sync handles change detection

local max = math.max

local LayoutNode = Container:extends('LayoutNode')
LayoutNode._schema = Utils.merge_tables(
    Utils.copy_table(Container._schema),
    LayoutNodeSchema
)

local function assert_no_dual_responsive_breakpoints(responsive, breakpoints, level)
    if responsive ~= nil and breakpoints ~= nil then
        Assert.fail(
            'responsive and breakpoints cannot both be supplied on the same node',
            level or 1
        )
    end
end

function LayoutNode.__index(self, key)
    local current = rawget(self, '_pclass') or getmetatable(self)
    while current ~= nil do
        local method = rawget(current, key)
        if method ~= nil then
            return method
        end
        current = rawget(current, 'super')
    end

    local method = Container._walk_hierarchy(LayoutNode, key)
    if method ~= nil then
        return method
    end

    return nil
end

function LayoutNode:constructor(opts, schema, config)
    opts = opts or {}
    schema = schema or LayoutNodeSchema
    local declared_schema = Utils.merge_tables(
        Utils.copy_table(LayoutNode._schema),
        schema
    )

    assert_no_dual_responsive_breakpoints(
        opts.responsive,
        opts.breakpoints,
        3
    )

    Container._initialize(self, opts, declared_schema, config)

    for key, value in pairs(opts) do
        self[key] = value
    end

    self._ui_layout_kind = 'LayoutNode'
    self._ui_layout_instance = true
    self:mark_dirty('layout')
    self._layout_content_rect_cache = Rectangle(0, 0, 0, 0)
end

function LayoutNode:_initialize(opts, schema, config)
    return LayoutNode.constructor(self, opts, schema, config)
end

function LayoutNode.is_layout_node(value)
    return Types.is_table(value) and value._ui_layout_instance == true
end

function LayoutNode:markDirty()
    self:mark_dirty('layout')

    local current = self.parent

    while current ~= nil do
        if current._ui_layout_instance == true then
            current:mark_dirty('layout')
        end

        current = current.parent
    end

    return Container.markDirty(self)
end

function LayoutNode:_prepare_for_layout_pass()
    Container._prepare_for_layout_pass(self)
    self:_refresh_layout_content_rect()
    return self
end

function LayoutNode:_get_effective_content_rect()
    return self._layout_content_rect_cache:clone()
end

function LayoutNode:_refresh_layout_content_rect()
    local padding = self.padding or {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
    }
    local width = self._resolved_width or 0
    local height = self._resolved_height or 0

    self._layout_content_rect_cache = Rectangle(
        padding.left,
        padding.top,
        max(0, width - padding.left - padding.right),
        max(0, height - padding.top - padding.bottom)
    )

    return self._layout_content_rect_cache
end

function LayoutNode:_apply_layout(_)
    return self
end

function LayoutNode:_run_layout_pass(stage)
    self:_prepare_for_layout_pass(stage)
    self:_refresh_layout_content_rect()

    if self:group_dirty('layout') then
        self:_apply_layout(stage)
        self:clear_dirty('layout')
    end

    return self
end

return LayoutNode
