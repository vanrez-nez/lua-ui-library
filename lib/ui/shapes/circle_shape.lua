local Shape = require('lib.ui.core.shape')
local DrawHelpers = require('lib.ui.shapes.draw_helpers')

local CircleShape = Shape:extends('CircleShape')

local DEFAULT_SEGMENTS = 32

local function build_local_ellipse_points(bounds, segments)
    local points = {}
    local radius_x = bounds.width / 2
    local radius_y = bounds.height / 2
    local center_x = bounds.x + radius_x
    local center_y = bounds.y + radius_y

    for index = 0, segments - 1 do
        local angle = (index / segments) * (math.pi * 2)
        points[#points + 1] = {
            center_x + math.cos(angle) * radius_x,
            center_y + math.sin(angle) * radius_y,
        }
    end

    return points
end

function CircleShape:constructor(opts)
    Shape.constructor(self, opts)
end

function CircleShape:_get_local_points()
    local bounds = self:_get_shape_local_bounds()
    return build_local_ellipse_points(bounds, DEFAULT_SEGMENTS)
end

function CircleShape:draw(graphics)
    if type(graphics) ~= 'table' or type(graphics.polygon) ~= 'function' then
        return Shape.draw(self, graphics)
    end

    local bounds = self:getLocalBounds()
    if bounds.width <= 0 or bounds.height <= 0 then
        return
    end

    local fill_color = self.fillColor or { 1, 1, 1, 1 }
    local fill_opacity = self.fillOpacity or 1
    local world_points = DrawHelpers.transform_local_points(self, self:_get_local_points())

    DrawHelpers.with_fill_color(graphics, fill_color, fill_opacity, function()
        graphics.polygon('fill', DrawHelpers.flatten_points(world_points))
    end)
end

function CircleShape:_contains_local_point(local_x, local_y)
    local bounds = self:getLocalBounds()
    if bounds.width <= 0 or bounds.height <= 0 then
        return false
    end

    local radius_x = bounds.width / 2
    local radius_y = bounds.height / 2
    local center_x = bounds.x + radius_x
    local center_y = bounds.y + radius_y

    local normalized_x = (local_x - center_x) / radius_x
    local normalized_y = (local_y - center_y) / radius_y

    return (normalized_x * normalized_x) + (normalized_y * normalized_y) <= 1
end

function CircleShape.new(opts)
    return CircleShape(opts)
end

return CircleShape
