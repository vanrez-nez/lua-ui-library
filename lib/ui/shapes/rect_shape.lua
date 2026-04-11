local Shape = require('lib.ui.core.shape')
local DrawHelpers = require('lib.ui.shapes.draw_helpers')

local RectShape = Shape:extends('RectShape')

function RectShape:constructor(opts)
    Shape.constructor(self, opts)
end

function RectShape:_get_local_points()
    local bounds = self:_get_shape_local_bounds()
    local points = self:_get_local_point_buffer(4)

    points[1][1] = bounds.x
    points[1][2] = bounds.y
    points[2][1] = bounds.x + bounds.width
    points[2][2] = bounds.y
    points[3][1] = bounds.x + bounds.width
    points[3][2] = bounds.y + bounds.height
    points[4][1] = bounds.x
    points[4][2] = bounds.y + bounds.height

    return points
end

function RectShape:draw(graphics)
    if type(graphics) ~= 'table' then
        return Shape.draw(self, graphics)
    end

    local bounds = self:getWorldBounds()
    if bounds.width <= 0 or bounds.height <= 0 then
        return
    end

    local local_points = self:_get_local_points()
    local world_points = self:_transform_local_points(local_points)
    local active_fill = self:_resolve_active_fill_source()

    if active_fill.kind == 'color' and type(graphics.polygon) ~= 'function' then
        return Shape.draw(self, graphics)
    end

    self:_render_active_fill(graphics, local_points, world_points, active_fill)
    DrawHelpers.draw_polygon_stroke(graphics, world_points, self:_resolve_polygon_stroke_options())
end

function RectShape.new(opts)
    return RectShape(opts)
end

return RectShape
