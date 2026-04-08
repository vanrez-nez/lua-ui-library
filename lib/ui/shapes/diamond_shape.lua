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

function DiamondShape:draw(graphics)
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

    DrawHelpers.draw_polygon_fill(graphics, world_points, fill_color, fill_opacity)
    DrawHelpers.draw_polygon_stroke(graphics, world_points, {
        color = self.strokeColor,
        opacity = self.strokeOpacity or 1,
        width = self.strokeWidth or 0,
        style = self.strokeStyle or 'smooth',
        join = self.strokeJoin or 'miter',
        miter_limit = self.strokeMiterLimit or 10,
        pattern = self.strokePattern or 'solid',
        dash_length = self.strokeDashLength or 8,
        gap_length = self.strokeGapLength or 4,
        dash_offset = self.strokeDashOffset or 0,
    })
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
