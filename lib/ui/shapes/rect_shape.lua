local Shape = require('lib.ui.core.shape')
local DrawHelpers = require('lib.ui.shapes.draw_helpers')

local RectShape = Shape:extends('RectShape')

function RectShape:constructor(opts)
    Shape.constructor(self, opts)
end

function RectShape:_get_local_points()
    local bounds = self:_get_shape_local_bounds()

    return {
        { bounds.x, bounds.y },
        { bounds.x + bounds.width, bounds.y },
        { bounds.x + bounds.width, bounds.y + bounds.height },
        { bounds.x, bounds.y + bounds.height },
    }
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
    local world_points = DrawHelpers.transform_local_points(self, local_points)
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
