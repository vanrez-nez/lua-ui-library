local Assert = require('lib.ui.core.assert')
local Container = require('lib.ui.core.container')
local Insets = require('lib.ui.core.insets')
local Rectangle = require('lib.ui.core.rectangle')

local max = math.max

local Drawable = {}

local EXTRA_PUBLIC_KEYS = {
    padding = true,
    margin = true,
    alignX = true,
    alignY = true,
    skin = true,
    shader = true,
    opacity = true,
    blendMode = true,
    mask = true,
}

local ALIGNMENT_VALUES = {
    start = true,
    center = true,
    ['end'] = true,
    stretch = true,
}

local function assert_alignment(name, value, level)
    if type(value) ~= 'string' or not ALIGNMENT_VALUES[value] then
        Assert.fail(
            name .. ' must be "start", "center", "end", or "stretch"',
            level or 1
        )
    end
end

local function copy_options(opts)
    if opts == nil then
        return {}
    end

    if type(opts) ~= 'table' then
        Assert.fail('opts must be a table', 2)
    end

    local copy = {}

    for key, value in pairs(opts) do
        copy[key] = value
    end

    return copy
end

local function validate_extra_public_value(key, value, level)
    if key == 'padding' or key == 'margin' then
        return Insets.normalize(value)
    end

    if key == 'alignX' then
        assert_alignment('Drawable.alignX', value, level)
        return value
    end

    if key == 'alignY' then
        assert_alignment('Drawable.alignY', value, level)
        return value
    end

    if key == 'opacity' then
        Assert.number('Drawable.opacity', value, level)
        return value
    end

    return value
end

local function set_extra_public_value(self, key, value, level)
    value = validate_extra_public_value(key, value, level or 1)

    if self._public_values[key] == value then
        return value
    end

    self._public_values[key] = value
    self._responsive_dirty = true
    return value
end

local function set_initial_extra_public_value(self, key, value)
    local resolved = validate_extra_public_value(key, value, 3)

    self._public_values[key] = resolved
    self._effective_values[key] = resolved
end

local function get_effective_insets(self, key)
    return self._effective_values[key] or Insets.zero()
end

local function resolve_alignment_axis(origin, available_size, content_size, align)
    content_size = max(0, content_size)

    if available_size <= 0 then
        if align == 'stretch' then
            return origin, 0
        end

        return origin, content_size
    end

    if align == 'stretch' then
        return origin, available_size
    end

    if align == 'center' then
        return origin + ((available_size - content_size) / 2), content_size
    end

    if align == 'end' then
        return origin + (available_size - content_size), content_size
    end

    return origin, content_size
end

Drawable.__index = function(self, key)
    local method = rawget(Drawable, key)

    if method ~= nil then
        return method
    end

    return Container.__index(self, key)
end

Drawable.__newindex = function(self, key, value)
    if EXTRA_PUBLIC_KEYS[key] then
        set_extra_public_value(self, key, value, 2)
        return
    end

    Container.__newindex(self, key, value)
end

function Drawable.new(opts)
    opts = copy_options(opts)

    if opts.padding == nil then
        opts.padding = 0
    end

    if opts.margin == nil then
        opts.margin = 0
    end

    if opts.alignX == nil then
        opts.alignX = 'start'
    end

    if opts.alignY == nil then
        opts.alignY = 'start'
    end

    if opts.opacity == nil then
        opts.opacity = 1
    end

    local self = {}

    Container._initialize(self, opts, EXTRA_PUBLIC_KEYS)

    set_initial_extra_public_value(self, 'padding', opts.padding)
    set_initial_extra_public_value(self, 'margin', opts.margin)
    set_initial_extra_public_value(self, 'alignX', opts.alignX)
    set_initial_extra_public_value(self, 'alignY', opts.alignY)
    set_initial_extra_public_value(self, 'skin', opts.skin)
    set_initial_extra_public_value(self, 'shader', opts.shader)
    set_initial_extra_public_value(self, 'opacity', opts.opacity)
    set_initial_extra_public_value(self, 'blendMode', opts.blendMode)
    set_initial_extra_public_value(self, 'mask', opts.mask)

    self._ui_drawable_instance = true

    return setmetatable(self, Drawable)
end

function Drawable.is_drawable(value)
    return type(value) == 'table' and value._ui_drawable_instance == true
end

function Drawable:getContentRect()
    local bounds = self:getLocalBounds()
    return bounds:inset(get_effective_insets(self, 'padding'))
end

function Drawable:resolveContentRect(content_width, content_height)
    Assert.number('content_width', content_width, 2)
    Assert.number('content_height', content_height, 2)

    local content_box = self:getContentRect()
    local x, width = resolve_alignment_axis(
        content_box.x,
        content_box.width,
        content_width,
        self._effective_values.alignX or 'start'
    )
    local y, height = resolve_alignment_axis(
        content_box.y,
        content_box.height,
        content_height,
        self._effective_values.alignY or 'start'
    )

    return Rectangle.new(x, y, width, height)
end

return Drawable
