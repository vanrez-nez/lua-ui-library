local Assert = require('lib.ui.core.assert')
local Container = require('lib.ui.core.container')
local Insets = require('lib.ui.core.insets')
local Rectangle = require('lib.ui.core.rectangle')

local max = math.max

local LayoutNode = {}

local COMMON_PUBLIC_KEYS = {
    gap = true,
    padding = true,
    wrap = true,
    justify = true,
    align = true,
    responsive = true,
}

local JUSTIFY_VALUES = {
    start = true,
    center = true,
    ['end'] = true,
    ['space-between'] = true,
    ['space-around'] = true,
}

local ALIGN_VALUES = {
    start = true,
    center = true,
    ['end'] = true,
    stretch = true,
}

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

local function merge_extra_public_keys(extra_public_keys)
    local merged = {}

    for key in pairs(COMMON_PUBLIC_KEYS) do
        merged[key] = true
    end

    if extra_public_keys ~= nil then
        Assert.table('extra_public_keys', extra_public_keys, 3)

        for key in pairs(extra_public_keys) do
            merged[key] = true
        end
    end

    return merged
end

local function validate_justify(value, level)
    if type(value) ~= 'string' or not JUSTIFY_VALUES[value] then
        Assert.fail(
            'Layout.justify must be "start", "center", "end", "space-between", or "space-around"',
            level or 1
        )
    end
end

local function validate_align(value, level)
    if type(value) ~= 'string' or not ALIGN_VALUES[value] then
        Assert.fail(
            'Layout.align must be "start", "center", "end", or "stretch"',
            level or 1
        )
    end
end

local function validate_responsive_value(self, value, level)
    if value == nil then
        return nil
    end

    if self._public_values ~= nil and self._public_values.breakpoints ~= nil then
        Assert.fail(
            'responsive and breakpoints cannot both be supplied on the same node',
            level or 1
        )
    end

    local value_type = type(value)

    if value_type ~= 'table' and value_type ~= 'function' then
        Assert.fail(
            'Layout.responsive must be a table or function',
            level or 1
        )
    end

    return value
end

local function validate_extra_public_value(self, key, value, level)
    if key == 'gap' then
        Assert.number('Layout.gap', value, level)
        return value
    end

    if key == 'padding' then
        return Insets.normalize(value)
    end

    if key == 'wrap' then
        Assert.boolean('Layout.wrap', value, level)
        return value
    end

    if key == 'justify' then
        validate_justify(value, level)
        return value
    end

    if key == 'align' then
        validate_align(value, level)
        return value
    end

    if key == 'responsive' then
        return validate_responsive_value(self, value, level)
    end

    return value
end

local function set_extra_public_value(self, key, value, level)
    value = validate_extra_public_value(self, key, value, level or 1)

    if self._public_values[key] == value then
        return value
    end

    self._public_values[key] = value
    self:markDirty()
    return value
end

local function set_initial_extra_public_value(self, key, value)
    local resolved = validate_extra_public_value(self, key, value, 3)

    self._public_values[key] = resolved
    self._effective_values[key] = resolved
end

LayoutNode.__index = function(self, key)
    local method = rawget(LayoutNode, key)

    if method ~= nil then
        return method
    end

    return Container.__index(self, key)
end

LayoutNode.__newindex = function(self, key, value)
    if COMMON_PUBLIC_KEYS[key] then
        set_extra_public_value(self, key, value, 2)
        return
    end

    Container.__newindex(self, key, value)
end

function LayoutNode._initialize(self, opts, extra_public_keys)
    opts = copy_options(opts)

    if opts.gap == nil then
        opts.gap = 0
    end

    if opts.padding == nil then
        opts.padding = 0
    end

    if opts.wrap == nil then
        opts.wrap = false
    end

    if opts.justify == nil then
        opts.justify = 'start'
    end

    if opts.align == nil then
        opts.align = 'start'
    end

    local allowed_public_keys = merge_extra_public_keys(extra_public_keys)

    Container._initialize(self, opts, allowed_public_keys, {
        allow_content_width = true,
        allow_content_height = true,
    })

    set_initial_extra_public_value(self, 'gap', opts.gap)
    set_initial_extra_public_value(self, 'padding', opts.padding)
    set_initial_extra_public_value(self, 'wrap', opts.wrap)
    set_initial_extra_public_value(self, 'justify', opts.justify)
    set_initial_extra_public_value(self, 'align', opts.align)
    set_initial_extra_public_value(self, 'responsive', opts.responsive)

    self._ui_layout_instance = true
    self._layout_dirty = true
    self._layout_content_rect_cache = Rectangle.new(0, 0, 0, 0)

    return self
end

function LayoutNode.is_layout_node(value)
    return type(value) == 'table' and value._ui_layout_instance == true
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
    local padding = self._effective_values.padding or Insets.zero()
    local width = self._resolved_width or 0
    local height = self._resolved_height or 0

    self._layout_content_rect_cache = Rectangle.new(
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
