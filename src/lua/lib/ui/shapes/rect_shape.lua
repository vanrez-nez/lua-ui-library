local Shape = require('lib.ui.core.shape')

local RectShape = Shape:extends('RectShape')

function RectShape:constructor(opts)
    Shape.constructor(self, opts)
end

function RectShape:_get_local_points(out_table)
    local bounds = self:_get_shape_local_bounds()
    local points = self:_get_local_point_buffer(4, out_table)

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

function RectShape.new(opts)
    return RectShape(opts)
end

return RectShape
