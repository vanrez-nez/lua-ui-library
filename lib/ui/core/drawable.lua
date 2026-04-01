local Assert = require('lib.ui.utils.assert')
local Container = require('lib.ui.core.container')
local Types = require('lib.ui.utils.types')
local Insets = require('lib.ui.core.insets')
local Rectangle = require('lib.ui.core.rectangle')
local Schema = require('lib.ui.utils.schema')

local max = math.max

local Drawable = Container:extends('Drawable')

function Drawable.__index(self, key)
    local val = Container._walk_hierarchy(getmetatable(self), key)
    if val ~= nil then return val end
    
    val = Container._walk_hierarchy(Drawable, key)
    if val ~= nil then return val end

    local allowed_public_keys = rawget(self, '_allowed_public_keys')
    if allowed_public_keys and allowed_public_keys[key] then
        local public_values = rawget(self, '_public_values')
        return public_values and public_values[key]
    end

    return nil
end

function Drawable.__newindex(self, key, value)
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

Drawable._schema = Schema.merge(Container._schema, require('lib.ui.core.drawable_schema'))

local DEFAULT_FOCUS_RING_OFFSET = 2
local DEFAULT_FOCUS_RING_WIDTH = 2





local function copy_options(opts)
    if opts == nil then
        return {}
    end

    if not Types.is_table(opts) then
        Assert.fail('opts must be a table', 2)
    end

    local copy = {}

    for key, value in pairs(opts) do
        copy[key] = value
    end

    return copy
end



local function get_effective_insets(self, key)
    local effective_values = rawget(self, '_effective_values')
    return (effective_values and effective_values[key]) or Insets.zero()
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



function Drawable.__index(self, key)
    local val = Container._walk_hierarchy(getmetatable(self), key)
    if val ~= nil then return val end
    
    val = Container._walk_hierarchy(Drawable, key)
    if val ~= nil then return val end

    local allowed_public_keys = rawget(self, '_allowed_public_keys')
    if allowed_public_keys and allowed_public_keys[key] then
        local public_values = rawget(self, '_public_values')
        return public_values and public_values[key]
    end

    return nil
end

function Drawable.__newindex(self, key, value)
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

function Drawable:constructor(opts)
    self:_initialize(opts)
end

function Drawable:_initialize(opts)
    Container._initialize(self, opts, Drawable._schema)
    self._ui_drawable_instance = true
end

function Drawable.new(opts)
    return Drawable(opts)
end

function Drawable.is_drawable(value)
    return Types.is_instance(value, Drawable)
end

function Drawable:getContentRect()
    local bounds = self:getLocalBounds()
    return bounds:inset(get_effective_insets(self, 'padding'))
end

local function get_effective_value(self, key)
    local effective_values = rawget(self, '_effective_values')
    return effective_values and effective_values[key]
end

function Drawable:resolveContentRect(content_width, content_height)
    Assert.number('content_width', content_width, 2)
    Assert.number('content_height', content_height, 2)

    local content_box = self:getContentRect()
    local x, width = resolve_alignment_axis(
        content_box.x,
        content_box.width,
        content_width,
        (get_effective_value(self, 'alignX') or 'start')
    )
    local y, height = resolve_alignment_axis(
        content_box.y,
        content_box.height,
        content_height,
        (get_effective_value(self, 'alignY') or 'start')
    )

    return Rectangle(x, y, width, height)
end

function Drawable:_draw_default_focus_indicator(graphics)
    if not Types.is_table(graphics) or not Types.is_function(graphics.rectangle) then
        return self
    end

    local bounds = self:getWorldBounds()
    local restore_red = nil
    local restore_green = nil
    local restore_blue = nil
    local restore_alpha = nil
    local restore_line_width = nil

    if Types.is_function(graphics.getColor) then
        restore_red, restore_green, restore_blue, restore_alpha = graphics.getColor()
    end

    if Types.is_function(graphics.getLineWidth) then
        restore_line_width = graphics.getLineWidth()
    end

    if Types.is_function(graphics.setColor) then
        graphics.setColor(1, 1, 1, 1)
    end

    if Types.is_function(graphics.setLineWidth) then
        graphics.setLineWidth(DEFAULT_FOCUS_RING_WIDTH)
    end

    graphics.rectangle(
        'line',
        bounds.x - DEFAULT_FOCUS_RING_OFFSET,
        bounds.y - DEFAULT_FOCUS_RING_OFFSET,
        bounds.width + (DEFAULT_FOCUS_RING_OFFSET * 2),
        bounds.height + (DEFAULT_FOCUS_RING_OFFSET * 2)
    )

    if restore_line_width ~= nil and Types.is_function(graphics.setLineWidth) then
        graphics.setLineWidth(restore_line_width)
    end

    if restore_red ~= nil and Types.is_function(graphics.setColor) then
        graphics.setColor(
            restore_red,
            restore_green,
            restore_blue,
            restore_alpha
        )
    end

    return self
end

return Drawable
