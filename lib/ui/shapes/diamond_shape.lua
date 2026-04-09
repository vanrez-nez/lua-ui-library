local Shape = require('lib.ui.core.shape')
local DrawHelpers = require('lib.ui.shapes.draw_helpers')

local DiamondShape = Shape:extends('DiamondShape')

function DiamondShape:constructor(opts)
    Shape.constructor(self, opts)
end

function DiamondShape:_get_local_points()
    local bounds = self:_get_shape_local_bounds()

    return {
        { bounds.x + (bounds.width / 2), bounds.y },
        { bounds.x + bounds.width, bounds.y + (bounds.height / 2) },
        { bounds.x + (bounds.width / 2), bounds.y + bounds.height },
        { bounds.x, bounds.y + (bounds.height / 2) },
    }
end

function DiamondShape:_requires_shape_result_clip()
    return true
end

function DiamondShape:draw(graphics)
    if type(graphics) ~= 'table' then
        return
    end

    local bounds = self:getWorldBounds()
    if bounds.width <= 0 or bounds.height <= 0 then
        return
    end

    local local_points = self:_get_local_points()
    local world_points = DrawHelpers.transform_local_points(self, local_points)
    local active_fill = self:_resolve_active_fill_source()

    if active_fill.kind == 'color' and type(graphics.polygon) ~= 'function' then
        return
    end

    self:_render_active_fill(graphics, local_points, world_points, active_fill)
    DrawHelpers.draw_polygon_stroke(graphics, world_points, self:_resolve_polygon_stroke_options())
end

function DiamondShape:_contains_local_point(local_x, local_y)
    local bounds = self:getLocalBounds()
    if bounds.width <= 0 or bounds.height <= 0 then
        return false
    end

    local radius_x = bounds.width / 2
    local radius_y = bounds.height / 2
    local center_x = bounds.x + radius_x
    local center_y = bounds.y + radius_y

    local normalized_x = math.abs((local_x - center_x) / radius_x)
    local normalized_y = math.abs((local_y - center_y) / radius_y)

    return normalized_x + normalized_y <= 1
end

function DiamondShape.new(opts)
    return DiamondShape(opts)
end

return DiamondShape
