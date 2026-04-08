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
    if type(graphics) ~= 'table' or type(graphics.polygon) ~= 'function' then
        return Shape.draw(self, graphics)
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

function RectShape.new(opts)
    return RectShape(opts)
end

return RectShape
