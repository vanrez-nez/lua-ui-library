local Shape = require('lib.ui.core.shape')
local DrawHelpers = require('lib.ui.shapes.draw_helpers')

local CircleShape = Shape:extends('CircleShape')

local DEFAULT_SEGMENTS = 32
local TWO_PI = math.pi * 2
local PATH_EPSILON = 1e-9

local function positive_mod(value, modulus)
    if modulus == nil or modulus <= 0 then
        return 0
    end

    local result = value % modulus
    if result < 0 then
        result = result + modulus
    end

    return result
end

local function estimate_ellipse_perimeter(width, height)
    if width <= 0 or height <= 0 then
        return 0
    end

    local a = width / 2
    local b = height / 2

    return math.pi * (3 * (a + b) - math.sqrt((3 * a + b) * (a + 3 * b)))
end

local function resolve_closed_dash_pattern(perimeter, dash_length, gap_length)
    local cycle = dash_length + gap_length
    if perimeter <= 0 or gap_length <= 0 or cycle <= 0 then
        return dash_length, gap_length
    end

    local dash_count = math.floor((perimeter / cycle) + 0.5)
    if dash_count <= 0 then
        return dash_length, gap_length
    end

    local adjusted_cycle = perimeter / dash_count
    local adjusted_dash = adjusted_cycle * (dash_length / cycle)

    return adjusted_dash, adjusted_cycle - adjusted_dash
end

local function build_local_ellipse_points(bounds, segments)
    local points = {}
    local radius_x = bounds.width / 2
    local radius_y = bounds.height / 2
    local center_x = bounds.x + radius_x
    local center_y = bounds.y + radius_y

    for index = 0, segments - 1 do
        local angle = (-math.pi / 2) + ((index / segments) * TWO_PI)
        points[#points + 1] = {
            center_x + math.cos(angle) * radius_x,
            center_y + math.sin(angle) * radius_y,
        }
    end

    return points
end

function CircleShape:constructor(opts)
    Shape.constructor(self, opts)
end

function CircleShape:_get_local_points()
    local bounds = self:_get_shape_local_bounds()
    return build_local_ellipse_points(bounds, DEFAULT_SEGMENTS)
end

function CircleShape:draw(graphics)
    if type(graphics) ~= 'table' or type(graphics.polygon) ~= 'function' then
        return Shape.draw(self, graphics)
    end

    local bounds = self:getLocalBounds()
    if bounds.width <= 0 or bounds.height <= 0 then
        return
    end

    local fill_color = self.fillColor or { 1, 1, 1, 1 }
    local fill_opacity = self.fillOpacity or 1
    local world_points = DrawHelpers.transform_local_points(self, self:_get_local_points())
    local dash_length = self.strokeDashLength or 8
    local gap_length = self.strokeGapLength or 4
    local dash_offset = self.strokeDashOffset or 0
    local stroke_pattern = self.strokePattern or 'solid'

    DrawHelpers.draw_polygon_fill(graphics, world_points, fill_color, fill_opacity)

    if stroke_pattern == 'dashed' and gap_length > 0 then
        local perimeter = estimate_ellipse_perimeter(bounds.width, bounds.height)
        dash_length, gap_length = resolve_closed_dash_pattern(
            perimeter,
            dash_length,
            gap_length
        )

        local cycle = dash_length + gap_length
        local normalized_offset = positive_mod(dash_offset, cycle)
        local shifted_seam = positive_mod(
            normalized_offset + dash_length + (gap_length * 0.5),
            cycle
        )
        local desired_offset = gap_length * 0.5
        local shift = shifted_seam

        if shift > PATH_EPSILON then
            world_points = DrawHelpers.rotate_closed_path(world_points, shift)
            dash_offset = desired_offset
        end
    end

    DrawHelpers.draw_polyline_stroke(graphics, world_points, {
        color = self.strokeColor,
        opacity = self.strokeOpacity or 1,
        width = self.strokeWidth or 0,
        style = self.strokeStyle or 'smooth',
        join = nil,
        miter_limit = nil,
        pattern = stroke_pattern,
        dash_length = dash_length,
        gap_length = gap_length,
        dash_offset = dash_offset,
    }, true)
end

function CircleShape:_contains_local_point(local_x, local_y)
    local bounds = self:getLocalBounds()
    if bounds.width <= 0 or bounds.height <= 0 then
        return false
    end

    local radius_x = bounds.width / 2
    local radius_y = bounds.height / 2
    local center_x = bounds.x + radius_x
    local center_y = bounds.y + radius_y

    local normalized_x = (local_x - center_x) / radius_x
    local normalized_y = (local_y - center_y) / radius_y

    return (normalized_x * normalized_x) + (normalized_y * normalized_y) <= 1
end

function CircleShape.new(opts)
    return CircleShape(opts)
end

return CircleShape
