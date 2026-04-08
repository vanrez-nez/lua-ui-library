local Container = require('lib.ui.core.container')
local Schema = require('lib.ui.utils.schema')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')

local Shape = Container:extends('Shape')

Shape._schema = Schema.merge(Container._schema, require('lib.ui.core.shape_schema'))

function Shape.__index(self, key)
    local val = Container._walk_hierarchy(getmetatable(self), key)
    if val ~= nil then
        return val
    end

    val = Container._walk_hierarchy(Shape, key)
    if val ~= nil then
        return val
    end

    local allowed_public_keys = rawget(self, '_allowed_public_keys')
    if allowed_public_keys and allowed_public_keys[key] then
        return Container._get_public_read_value(self, key)
    end

    return nil
end

function Shape.__newindex(self, key, value)
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

function Shape:constructor(opts)
    Container.constructor(self, opts)
    rawset(self, '_ui_shape_instance', true)
end

function Shape.new(opts)
    return Shape(opts)
end

function Shape:addChild()
    Assert.fail('Shape may not contain child nodes', 2)
end

function Shape:removeChild()
    Assert.fail('Shape may not contain child nodes', 2)
end

function Shape:_get_shape_local_bounds()
    return rawget(self, '_local_bounds_cache') or self:getLocalBounds()
end

function Shape:_get_local_points()
    local bounds = self:_get_shape_local_bounds()

    return {
        { bounds.x, bounds.y },
        { bounds.x + bounds.width, bounds.y },
        { bounds.x + bounds.width, bounds.y + bounds.height },
        { bounds.x, bounds.y + bounds.height },
    }
end

function Shape:_get_world_bounds_points()
    local matrix = rawget(self, '_world_transform_cache')
    local local_points = self:_get_local_points()
    local world_points = {}

    if matrix == nil then
        return world_points
    end

    for index = 1, #local_points do
        local point = local_points[index]
        local world_x, world_y = matrix:transform_point(point[1], point[2])
        world_points[#world_points + 1] = { x = world_x, y = world_y }
    end

    return world_points
end

function Shape:draw(graphics)
    if not Types.is_table(graphics) or not Types.is_function(graphics.rectangle) then
        return
    end

    local bounds = self:getWorldBounds()
    if bounds.width <= 0 or bounds.height <= 0 then
        return
    end

    local fill_color = self.fillColor or { 1, 1, 1, 1 }
    local fill_opacity = self.fillOpacity or 1
    local alpha = (fill_color[4] or 1) * fill_opacity

    if alpha <= 0 then
        return
    end

    local restore_red = nil
    local restore_green = nil
    local restore_blue = nil
    local restore_alpha = nil

    if Types.is_function(graphics.getColor) then
        restore_red, restore_green, restore_blue, restore_alpha = graphics.getColor()
    end

    if Types.is_function(graphics.setColor) then
        graphics.setColor(
            fill_color[1] or 1,
            fill_color[2] or 1,
            fill_color[3] or 1,
            alpha
        )
    end

    graphics.rectangle(
        'fill',
        bounds.x,
        bounds.y,
        bounds.width,
        bounds.height
    )

    if restore_red ~= nil and Types.is_function(graphics.setColor) then
        graphics.setColor(
            restore_red,
            restore_green,
            restore_blue,
            restore_alpha
        )
    end
end

function Shape:_contains_local_point(local_x, local_y)
    local bounds = self:getLocalBounds()

    return bounds:contains_point(local_x, local_y)
end

function Shape:get_local_centroid()
    local bounds = self:getLocalBounds()

    return bounds.x + (bounds.width / 2), bounds.y + (bounds.height / 2)
end

function Shape:set_centroid_pivot()
    local bounds = self:getLocalBounds()

    if bounds.width == 0 or bounds.height == 0 then
        return
    end

    local centroid_x, centroid_y = self:get_local_centroid()

    Assert.number('centroid_x', centroid_x, 2)
    Assert.number('centroid_y', centroid_y, 2)

    self.pivotX = centroid_x / bounds.width
    self.pivotY = centroid_y / bounds.height
end

function Shape:containsPoint(x, y)
    local local_x, local_y = self:worldToLocal(x, y)

    return self:_contains_local_point(local_x, local_y)
end

function Shape:_is_effectively_targetable(x, y, state)
    return Container._is_effectively_targetable(self, x, y, state) and
        self:containsPoint(x, y)
end

return Shape
