local Assert = require('lib.ui.utils.assert')

local NineSlice = {}

local function validate_definition(definition)
    Assert.table('definition', definition, 2)
    Assert.number('definition.x', definition.x or 0, 2)
    Assert.number('definition.y', definition.y or 0, 2)
    Assert.number('definition.width', definition.width, 2)
    Assert.number('definition.height', definition.height, 2)
    Assert.number('definition.top', definition.top, 2)
    Assert.number('definition.right', definition.right, 2)
    Assert.number('definition.bottom', definition.bottom, 2)
    Assert.number('definition.left', definition.left, 2)

    if definition.left + definition.right > definition.width then
        error('invalid nine-slice definition: horizontal insets exceed source width', 2)
    end

    if definition.top + definition.bottom > definition.height then
        error('invalid nine-slice definition: vertical insets exceed source height', 2)
    end

    return definition
end

function NineSlice.define(definition)
    local validated = validate_definition(definition)
    local copy = {}

    for key, value in pairs(validated) do
        copy[key] = value
    end

    return copy
end

function NineSlice.layout(definition, target_width, target_height)
    validate_definition(definition)
    Assert.number('target_width', target_width, 2)
    Assert.number('target_height', target_height, 2)

    local left = definition.left
    local right = definition.right
    local top = definition.top
    local bottom = definition.bottom

    local scale_x = 1
    local scale_y = 1

    if target_width < left + right and left + right > 0 then
        scale_x = target_width / (left + right)
    end

    if target_height < top + bottom and top + bottom > 0 then
        scale_y = target_height / (top + bottom)
    end

    local draw_left = left * scale_x
    local draw_right = right * scale_x
    local draw_top = top * scale_y
    local draw_bottom = bottom * scale_y
    local center_width = math.max(0, target_width - draw_left - draw_right)
    local center_height = math.max(0, target_height - draw_top - draw_bottom)
    local omit_horizontal = scale_x < 1
    local omit_vertical = scale_y < 1

    local top_edge = nil
    local bottom_edge = nil
    local left_edge = nil
    local right_edge = nil
    local center = nil

    if not omit_horizontal then
        top_edge = { width = center_width, height = draw_top }
        bottom_edge = { width = center_width, height = draw_bottom }
    end

    if not omit_vertical then
        left_edge = { width = draw_left, height = center_height }
        right_edge = { width = draw_right, height = center_height }
    end

    if not omit_horizontal and not omit_vertical then
        center = {
            width = center_width,
            height = center_height,
        }
    end

    return {
        corners = {
            top_left = { width = draw_left, height = draw_top },
            top_right = { width = draw_right, height = draw_top },
            bottom_left = { width = draw_left, height = draw_bottom },
            bottom_right = { width = draw_right, height = draw_bottom },
        },
        edges = {
            top = top_edge,
            bottom = bottom_edge,
            left = left_edge,
            right = right_edge,
        },
        center = center,
    }
end

return NineSlice
