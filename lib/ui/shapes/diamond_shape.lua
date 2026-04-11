local Shape = require('lib.ui.core.shape')

local DiamondShape = Shape:extends('DiamondShape')
DiamondShape._allow_rect_draw_fallback = false

function DiamondShape:constructor(opts)
    Shape.constructor(self, opts)
end

function DiamondShape:_get_local_points(out_table)
    local bounds = self:_get_shape_local_bounds()
    local points = self:_get_local_point_buffer(4, out_table)

    points[1][1] = bounds.x + (bounds.width / 2)
    points[1][2] = bounds.y
    points[2][1] = bounds.x + bounds.width
    points[2][2] = bounds.y + (bounds.height / 2)
    points[3][1] = bounds.x + (bounds.width / 2)
    points[3][2] = bounds.y + bounds.height
    points[4][1] = bounds.x
    points[4][2] = bounds.y + (bounds.height / 2)

    return points
end

function DiamondShape:_requires_shape_result_clip()
    return true
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
