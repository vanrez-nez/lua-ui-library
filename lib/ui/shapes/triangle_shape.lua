local Shape = require('lib.ui.core.shape')
local DrawHelpers = require('lib.ui.shapes.draw_helpers')

local TriangleShape = Shape:extends('TriangleShape')

local function sign(px, py, ax, ay, bx, by)
    return (px - bx) * (ay - by) - (ax - bx) * (py - by)
end

local function contains_triangle(px, py, ax, ay, bx, by, cx, cy)
    local d1 = sign(px, py, ax, ay, bx, by)
    local d2 = sign(px, py, bx, by, cx, cy)
    local d3 = sign(px, py, cx, cy, ax, ay)

    local has_negative = d1 < 0 or d2 < 0 or d3 < 0
    local has_positive = d1 > 0 or d2 > 0 or d3 > 0

    return not (has_negative and has_positive)
end

function TriangleShape:constructor(opts)
    Shape.constructor(self, opts)
end

function TriangleShape:_get_local_points()
    local bounds = self:getLocalBounds()

    return {
        { bounds.x + (bounds.width / 2), bounds.y },
        { bounds.x + bounds.width, bounds.y + bounds.height },
        { bounds.x, bounds.y + bounds.height },
    }
end

function TriangleShape:draw(graphics)
    if type(graphics) ~= 'table' or type(graphics.polygon) ~= 'function' then
        return
    end

    local bounds = self:getWorldBounds()
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

function TriangleShape:_contains_local_point(local_x, local_y)
    local bounds = self:getLocalBounds()
    if bounds.width <= 0 or bounds.height <= 0 then
        return false
    end

    return contains_triangle(
        local_x,
        local_y,
        bounds.x + (bounds.width / 2),
        bounds.y,
        bounds.x + bounds.width,
        bounds.y + bounds.height,
        bounds.x,
        bounds.y + bounds.height
    )
end

function TriangleShape.new(opts)
    return TriangleShape(opts)
end

return TriangleShape
