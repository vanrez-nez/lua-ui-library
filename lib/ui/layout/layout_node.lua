local Assert = require('lib.ui.utils.assert')
local Container = require('lib.ui.core.container')
local Types = require('lib.ui.utils.types')
local Insets = require('lib.ui.core.insets')
local Rectangle = require('lib.ui.core.rectangle')
local Schema = require('lib.ui.utils.schema')

local max = math.max

local LayoutNode = Container:extends('LayoutNode')
LayoutNode._schema = Schema.merge(Container._schema, require('lib.ui.layout.layout_node_schema'))

local function resolve_method(self, key, base_cls)
    local val = Container._walk_hierarchy(getmetatable(self), key)
    if val ~= nil then return val end
    return Container._walk_hierarchy(base_cls, key)
end

function LayoutNode.__index(self, key)
    local val = resolve_method(self, key, LayoutNode)
    if val ~= nil then return val end

    local allowed_public_keys = rawget(self, '_allowed_public_keys')
    if allowed_public_keys and allowed_public_keys[key] then
        local public_values = rawget(self, '_public_values')
        return public_values and public_values[key]
    end

    return nil
end

function LayoutNode.__newindex(self, key, value)
    local allowed_public_keys = rawget(self, '_allowed_public_keys')
    if allowed_public_keys and allowed_public_keys[key] then
        Container._set_public_value(self, key, value, 2)
        
        local rule = allowed_public_keys[key]
        if Types.is_table(rule) and Types.is_function(rule.set) then
            rule.set(self, value)
        end
        return
    end

    rawset(self, key, value)
end

local function copy_options(opts)
    if opts == nil then
        return {}
    end

    Assert.table('opts', opts, 2)

    local copy = {}

    for key, value in pairs(opts) do
        copy[key] = value
    end

    return copy
end



local function validate_responsive_value(self, value, level)
    if value == nil then
        return nil
    end

    local public_values = rawget(self, '_public_values')
    if public_values ~= nil and public_values.breakpoints ~= nil then
        Assert.fail(
            'responsive and breakpoints cannot both be supplied on the same node',
            level or 1
        )
    end

    if not Types.is_table(value) and not Types.is_function(value) then
        Assert.fail(
            'Layout.responsive must be a table or function',
            level or 1
        )
    end

    return value
end

local function validate_extra_public_value(self, key, value, level)
    if key == 'padding' then
        return Insets.normalize(value)
    end

    if key == 'responsive' then
        return validate_responsive_value(self, value, level)
    end

    return value
end

local function set_extra_public_value(self, key, value, level)
    value = validate_extra_public_value(self, key, value, level or 1)

    local public_values = rawget(self, '_public_values')
    if public_values and public_values[key] == value then
        return value
    end

    if public_values then
        public_values[key] = value
    end
    self:markDirty()
    return value
end

local function set_initial_extra_public_value(self, key, value)
    local resolved = validate_extra_public_value(self, key, value, 3)

    local public_values = rawget(self, '_public_values')
    if public_values then
        public_values[key] = resolved
    end
    local effective_values = rawget(self, '_effective_values')
    if effective_values then
        effective_values[key] = resolved
    end
end



local function resolve_method(self, key, base_cls)
    local val = Container._walk_hierarchy(getmetatable(self), key)
    if val ~= nil then return val end
    -- Fallback to the explicit base class hierarchy for mocks
    return Container._walk_hierarchy(base_cls, key)
end

function LayoutNode.__index(self, key)
    local val = resolve_method(self, key, LayoutNode)
    if val ~= nil then return val end

    local allowed_public_keys = rawget(self, '_allowed_public_keys')
    if allowed_public_keys and allowed_public_keys[key] then
        local public_values = rawget(self, '_public_values')
        return public_values and public_values[key]
    end

    return nil
end

function LayoutNode.__newindex(self, key, value)
    local allowed_public_keys = rawget(self, '_allowed_public_keys')
    if allowed_public_keys and allowed_public_keys[key] then
        Container._set_public_value(self, key, value, 2)
        return
    end

    rawset(self, key, value)
end

function LayoutNode:_initialize(opts, extra_schema, extra_public_keys, config)
    Container._initialize(self, opts, Schema.merge(extra_schema or LayoutNode._schema, extra_public_keys), config)
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
    local padding = effective_values.padding or Insets.zero()
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
    self:_refresh_layout_content_rect()

    if self._layout_dirty then
        self:_apply_layout(stage)
        self._layout_dirty = false
    end

    return self
end

return LayoutNode
