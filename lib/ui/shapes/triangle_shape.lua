local Shape = require('lib.ui.core.shape')

local TriangleShape = Shape:extends('TriangleShape')
TriangleShape._allow_rect_draw_fallback = false

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

local function resolve_local_points(bounds)
    local top_x = bounds.x + (bounds.width / 2)
    local top_y = bounds.y
    local base_y = bounds.y + bounds.height

    return {
        { top_x, top_y },
        { bounds.x + bounds.width, base_y },
        { bounds.x, base_y },
    }
end

function TriangleShape:constructor(opts)
    Shape.constructor(self, opts)
end

function TriangleShape:_get_local_points(out_table)
    local bounds = self:_get_shape_local_bounds()
    local points = self:_get_local_point_buffer(3, out_table)
    local top_x = bounds.x + (bounds.width / 2)
    local top_y = bounds.y
    local base_y = bounds.y + bounds.height

    points[1][1] = top_x
    points[1][2] = top_y
    points[2][1] = bounds.x + bounds.width
    points[2][2] = base_y
    points[3][1] = bounds.x
    points[3][2] = base_y

    return points
end

function TriangleShape:_requires_shape_result_clip()
    return true
end

function TriangleShape:get_local_centroid()
    local points = self:_get_local_points()

    return
        (points[1][1] + points[2][1] + points[3][1]) / 3,
        (points[1][2] + points[2][2] + points[3][2]) / 3
end

function TriangleShape:_contains_local_point(local_x, local_y)
    local bounds = self:getLocalBounds()
    if bounds.width <= 0 or bounds.height <= 0 then
        return false
    end

    local points = resolve_local_points(bounds)

    return contains_triangle(
        local_x,
        local_y,
        points[1][1],
        points[1][2],
        points[2][1],
        points[2][2],
        points[3][1],
        points[3][2]
    )
end

function TriangleShape.new(opts)
    return TriangleShape(opts)
end

return TriangleShape
