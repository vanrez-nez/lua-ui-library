local Shape = require('lib.ui.core.shape')
local DrawHelpers = require('lib.ui.shapes.draw_helpers')

local CircleShape = Shape:extends('CircleShape')
local WHITE_COLOR = { 1, 1, 1, 1 }

local abs = math.abs
local ceil = math.ceil
local sqrt = math.sqrt
local max = math.max
local pi = math.pi
local TWO_PI = pi * 2
local PATH_EPSILON = 1e-9

local MIN_SEGMENTS = 8
local MAX_SEGMENTS = 256
local DEFAULT_SEGMENTS = 64
local ARC_LENGTH_THRESHOLD = 3

local function resolve_segments(shape)
    local matrix = rawget(shape, '_world_transform_cache')

    if matrix == nil then
        return DEFAULT_SEGMENTS
    end

    -- Use the raw local-bounds cache directly instead of calling getLocalBounds(),
    -- which triggers ensure_current() and re-enters the update cycle if this runs
    -- from inside refresh_bounds (refresh_bounds -> _get_world_bounds_points ->
    -- _get_local_points -> resolve_segments -> getLocalBounds -> refresh_bounds).
    local bounds = shape:_get_shape_local_bounds()
    local radius_x = bounds.width / 2
    local radius_y = bounds.height / 2

    if radius_x <= 0 or radius_y <= 0 then
        return MIN_SEGMENTS
    end

    local scale_x = sqrt(matrix.a * matrix.a + matrix.b * matrix.b)
    local scale_y = sqrt(matrix.c * matrix.c + matrix.d * matrix.d)
    local max_world_radius = max(scale_x * radius_x, scale_y * radius_y)
    local segments = ceil(pi * max_world_radius / ARC_LENGTH_THRESHOLD)

    if segments < MIN_SEGMENTS then
        return MIN_SEGMENTS
    end

    if segments > MAX_SEGMENTS then
        return MAX_SEGMENTS
    end

    return segments
end

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

local function build_local_ellipse_points(bounds, segments, points)
    points = points or {}
    local radius_x = bounds.width / 2
    local radius_y = bounds.height / 2
    local center_x = bounds.x + radius_x
    local center_y = bounds.y + radius_y

    for index = 0, segments - 1 do
        local angle = (-math.pi / 2) + ((index / segments) * TWO_PI)
        local point_index = index + 1
        local point = points[point_index]

        if point == nil then
            point = { 0, 0 }
            points[point_index] = point
        end

        point[1] = center_x + math.cos(angle) * radius_x
        point[2] = center_y + math.sin(angle) * radius_y
    end

    for index = #points, segments + 1, -1 do
        points[index] = nil
    end

    return points
end

local function resolve_axis_aligned_world_ellipse(shape)
    local matrix = rawget(shape, '_world_transform_cache')

    if matrix == nil or abs(matrix.b) > PATH_EPSILON or abs(matrix.c) > PATH_EPSILON then
        return nil
    end

    local bounds = shape:getLocalBounds()
    local radius_x = bounds.width / 2
    local radius_y = bounds.height / 2

    if radius_x <= 0 or radius_y <= 0 then
        return nil
    end

    local center_x = bounds.x + radius_x
    local center_y = bounds.y + radius_y
    local world_center_x, world_center_y = shape:localToWorld(center_x, center_y)

    return {
        x = world_center_x,
        y = world_center_y,
        radius_x = abs(matrix.a) * radius_x,
        radius_y = abs(matrix.d) * radius_y,
    }
end

local function draw_axis_aligned_ellipse_fill(graphics, ellipse, fill_color, fill_opacity, segments)
    return DrawHelpers.with_fill_color(graphics, fill_color, fill_opacity, function()
        graphics.ellipse('fill', ellipse.x, ellipse.y, ellipse.radius_x, ellipse.radius_y, segments)
    end)
end

local function draw_axis_aligned_ellipse_stroke(graphics, ellipse, stroke, segments)
    if stroke == nil or stroke.color == nil or (stroke.width or 0) <= 0 then
        return false
    end

    return DrawHelpers.with_stroke_color(
        graphics,
        stroke.color,
        stroke.opacity or 1,
        stroke.node_opacity or 1,
        function()
            DrawHelpers.with_stroke_state(
                graphics,
                stroke.width,
                stroke.style,
                nil,
                nil,
                function()
                    graphics.ellipse(
                        'line',
                        ellipse.x,
                        ellipse.y,
                        ellipse.radius_x,
                        ellipse.radius_y,
                        segments
                    )
                end
            )
        end
    )
end

local function draw_axis_aligned_result_clip_fill(graphics, ellipse, radius_delta, segments)
    if type(graphics.ellipse) ~= 'function' then
        return false
    end

    local radius_x = ellipse.radius_x + radius_delta
    local radius_y = ellipse.radius_y + radius_delta

    if radius_x <= 0 or radius_y <= 0 then
        return false
    end

    graphics.ellipse('fill', ellipse.x, ellipse.y, radius_x, radius_y, segments)

    return true
end

local function draw_polygon_result_clip_fill(shape, graphics, radius_delta, segments)
    if type(graphics.polygon) ~= 'function' then
        return false
    end

    local bounds = shape:_get_shape_local_bounds()
    local inset = -radius_delta
    local adjusted_bounds = {
        x = bounds.x + inset,
        y = bounds.y + inset,
        width = bounds.width - (inset * 2),
        height = bounds.height - (inset * 2),
    }

    if adjusted_bounds.width <= 0 or adjusted_bounds.height <= 0 then
        return false
    end

    local local_points = build_local_ellipse_points(adjusted_bounds, segments, shape:_get_local_point_buffer(segments))
    local world_points = shape:_transform_local_points(local_points)
    graphics.polygon('fill', shape:_flatten_points(world_points))

    return true
end

local function draw_result_clip_fill(shape, graphics, radius_delta, segments)
    local axis_aligned_world_ellipse = nil

    if type(graphics.ellipse) == 'function' then
        axis_aligned_world_ellipse = resolve_axis_aligned_world_ellipse(shape)
    end

    if axis_aligned_world_ellipse ~= nil then
        return draw_axis_aligned_result_clip_fill(graphics, axis_aligned_world_ellipse, radius_delta, segments)
    end

    return draw_polygon_result_clip_fill(shape, graphics, radius_delta, segments)
end

local function resolve_stroke_draw_options(shape, bounds, world_points)
    local dash_length = shape.strokeDashLength or 8
    local gap_length = shape.strokeGapLength or 4
    local dash_offset = shape.strokeDashOffset or 0
    local stroke_pattern = shape.strokePattern or 'solid'

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

    local stroke = rawget(shape, '_circle_stroke_options_scratch')

    if stroke == nil then
        stroke = {}
        rawset(shape, '_circle_stroke_options_scratch', stroke)
    end

    stroke.color = shape.strokeColor
    stroke.opacity = shape.strokeOpacity or 1
    stroke.width = shape.strokeWidth or 0
    stroke.style = shape.strokeStyle or 'smooth'
    stroke.join = nil
    stroke.miter_limit = nil
    stroke.pattern = stroke_pattern
    stroke.dash_length = dash_length
    stroke.gap_length = gap_length
    stroke.dash_offset = dash_offset
    stroke.node_opacity = nil

    return world_points, stroke
end

function CircleShape:constructor(opts)
    Shape.constructor(self, opts)
end

function CircleShape:_get_local_points()
    local bounds = self:_get_shape_local_bounds()
    local segments = resolve_segments(self)
    return build_local_ellipse_points(bounds, segments, self:_get_local_point_buffer(segments))
end

function CircleShape:_requires_shape_result_clip()
    return true
end

function CircleShape:_resolve_root_compositing_result_clip()
    local fill_visible = self:_is_active_fill_visible()
    local has_stroke = self:_has_visible_root_result_stroke()

    if not fill_visible and not has_stroke then
        return nil
    end

    if (self.strokePattern or 'solid') ~= 'solid' then
        return Shape._resolve_root_compositing_result_clip(self)
    end

    return {
        kind = 'stencil_region',
        exclude_inner = has_stroke and not fill_visible,
    }
end

function CircleShape:draw(graphics)
    if type(graphics) ~= 'table' then
        return Shape.draw(self, graphics)
    end

    local bounds = self:getLocalBounds()
    if bounds.width <= 0 or bounds.height <= 0 then
        return
    end

    local segments = resolve_segments(self)
    local axis_aligned_world_ellipse = nil
    local local_points = self:_get_local_points()
    local world_points = self:_transform_local_points(local_points)
    local active_fill = self:_resolve_active_fill_source()

    if type(graphics.ellipse) == 'function' then
        axis_aligned_world_ellipse = resolve_axis_aligned_world_ellipse(self)
    end

    if active_fill.kind == 'color' and
        type(graphics.polygon) ~= 'function' and
        axis_aligned_world_ellipse == nil then
        return Shape.draw(self, graphics)
    end

    if active_fill.kind == 'color' and axis_aligned_world_ellipse ~= nil then
        draw_axis_aligned_ellipse_fill(
            graphics,
            axis_aligned_world_ellipse,
            active_fill.color,
            active_fill.opacity,
            segments
        )
    else
        self:_render_active_fill(graphics, local_points, world_points, active_fill)
    end

    local stroked_world_points, stroke = resolve_stroke_draw_options(self, bounds, world_points)

    if stroke.pattern == 'solid' and axis_aligned_world_ellipse ~= nil then
        draw_axis_aligned_ellipse_stroke(graphics, axis_aligned_world_ellipse, stroke, segments)
        return
    end

    DrawHelpers.draw_polyline_stroke(graphics, stroked_world_points, stroke, true)
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

function CircleShape:_draw_root_compositing_result_stroke_mask(graphics, world_points)
    local bounds = self:getLocalBounds()
    local stroked_world_points, stroke = resolve_stroke_draw_options(self, bounds, world_points)
    stroke.color = WHITE_COLOR
    stroke.opacity = 1
    stroke.node_opacity = 1

    return DrawHelpers.draw_polyline_stroke(graphics, stroked_world_points, stroke, true)
end

function CircleShape:_draw_root_compositing_result_clip_outer(graphics)
    local half_stroke = self:_has_visible_root_result_stroke() and ((self.strokeWidth or 0) * 0.5) or 0
    local segments = resolve_segments(self)

    return draw_result_clip_fill(self, graphics, half_stroke, segments)
end

function CircleShape:_draw_root_compositing_result_clip_inner(graphics)
    local half_stroke = (self.strokeWidth or 0) * 0.5

    if half_stroke <= 0 then
        return false
    end

    local segments = resolve_segments(self)

    return draw_result_clip_fill(self, graphics, -half_stroke, segments)
end

function CircleShape.new(opts)
    return CircleShape(opts)
end

return CircleShape
