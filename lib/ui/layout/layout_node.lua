local Assert = require('lib.ui.utils.assert')
local Container = require('lib.ui.core.container')
local Types = require('lib.ui.utils.types')
local Rectangle = require('lib.ui.core.rectangle')
local Schema = require('lib.ui.utils.schema')

local max = math.max

local LayoutNode = Container:extends('LayoutNode')
LayoutNode._schema = Schema.merge(Container._schema, require('lib.ui.layout.layout_node_schema'))

local function assert_no_dual_responsive_breakpoints(responsive, breakpoints, level)
    if responsive ~= nil and breakpoints ~= nil then
        Assert.fail(
            'responsive and breakpoints cannot both be supplied on the same node',
            level or 1
        )
    end
end

local function resolve_method(self, key, base_cls)
    local val = Container._walk_hierarchy(getmetatable(self), key)
    if val ~= nil then
        return val
    end

    return Container._walk_hierarchy(base_cls, key)
end

function LayoutNode.__index(self, key)
    local val = resolve_method(self, key, LayoutNode)
    if val ~= nil then
        return val
    end

    local allowed_public_keys = rawget(self, '_allowed_public_keys')
    if allowed_public_keys and allowed_public_keys[key] then
        return Container._get_public_read_value(self, key)
    end

    return nil
end

function LayoutNode.__newindex(self, key, value)
    local allowed_public_keys = rawget(self, '_allowed_public_keys')
    if allowed_public_keys and allowed_public_keys[key] then
        local public_values = rawget(self, '_public_values') or {}

        if key == 'responsive' then
            assert_no_dual_responsive_breakpoints(
                value,
                public_values.breakpoints,
                2
            )
        elseif key == 'breakpoints' then
            assert_no_dual_responsive_breakpoints(
                public_values.responsive,
                value,
                2
            )
        end

        Container._set_public_value(self, key, value, 2)

        local rule = allowed_public_keys[key]
        if Types.is_table(rule) and Types.is_function(rule.set) then
            rule.set(self, value)
        end
        return
    end

    rawset(self, key, value)
end

function LayoutNode:_initialize(opts, extra_schema, extra_public_keys, config)
    opts = opts or {}

    assert_no_dual_responsive_breakpoints(
        opts.responsive,
        opts.breakpoints,
        3
    )

    Container._initialize(
        self,
        opts,
        Schema.merge(extra_schema or LayoutNode._schema, extra_public_keys),
        config
    )
    rawset(self, '_ui_layout_kind', 'LayoutNode')
    rawset(self, '_ui_layout_instance', true)
    rawset(self, '_layout_dirty', true)
    rawset(self, '_layout_content_rect_cache', Rectangle(0, 0, 0, 0))
end

function LayoutNode:constructor(opts, extra_public_keys, config)
    self:_initialize(opts, LayoutNode._schema, extra_public_keys, config)
end

function LayoutNode.is_layout_node(value)
    return Types.is_table(value) and rawget(value, '_ui_layout_instance') == true
end

function LayoutNode:markDirty()
    self._layout_dirty = true

    local current = self.parent

    while current ~= nil do
        if current._ui_layout_instance == true then
            current._layout_dirty = true
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
    local effective_values = rawget(self, '_effective_values') or {}
    local padding = effective_values.padding or {
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

    if self._layout_dirty then
        self:_apply_layout(stage)
        self._layout_dirty = false
    end

    return self
end

return LayoutNode
