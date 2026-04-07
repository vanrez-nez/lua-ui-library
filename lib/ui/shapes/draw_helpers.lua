local Types = require('lib.ui.utils.types')

local DrawHelpers = {}

function DrawHelpers.with_fill_color(graphics, fill_color, fill_opacity, draw_fn)
    local alpha = (fill_color[4] or 1) * fill_opacity
    if alpha <= 0 then
        return false
    end

    local restore_red = nil
    local restore_green = nil
    local restore_blue = nil
    local restore_alpha = nil

    if Types.is_function(graphics.getColor) then
        restore_red, restore_green, restore_blue, restore_alpha = graphics.getColor()
    end

    if Types.is_function(graphics.setColor) then
        graphics.setColor(
            fill_color[1] or 1,
            fill_color[2] or 1,
            fill_color[3] or 1,
            alpha
        )
    end

    draw_fn()

    if restore_red ~= nil and Types.is_function(graphics.setColor) then
        graphics.setColor(
            restore_red,
            restore_green,
            restore_blue,
            restore_alpha
        )
    end

    return true
end

function DrawHelpers.transform_local_points(node, points)
    local transformed = {}

    for index = 1, #points do
        local point = points[index]
        local world_x, world_y = node:localToWorld(point[1], point[2])
        transformed[#transformed + 1] = { world_x, world_y }
    end

    return transformed
end

function DrawHelpers.flatten_points(points)
    local flattened = {}

    for index = 1, #points do
        local point = points[index]
        flattened[#flattened + 1] = point[1]
        flattened[#flattened + 1] = point[2]
    end

    return flattened
end

return DrawHelpers
