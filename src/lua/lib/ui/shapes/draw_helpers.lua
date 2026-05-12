local Types = require('lib.ui.utils.types')
local MathUtils = require('lib.ui.utils.math')
local Constants = require('lib.ui.core.constants')

local DrawHelpers = {}
local abs = math.abs
local sqrt = math.sqrt
local unpack = unpack
local PATH_EPSILON = 1e-9

local function save_color(graphics)
    if Types.is_function(graphics.getColor) then
        return { graphics.getColor() }
    end

    return nil
end

local function restore_color(graphics, saved_color)
    if saved_color == nil or not Types.is_function(graphics.setColor) then
        return
    end

    graphics.setColor(
        saved_color[1],
        saved_color[2],
        saved_color[3],
        saved_color[4]
    )
end

DrawHelpers.save_color = save_color
DrawHelpers.restore_color = restore_color

local function resolve_alpha(color, opacity)
    return (color[4] or 1) * (opacity or 1)
end

local function append_point(points, x, y)
    local last_point = points[#points]
    if last_point ~= nil and
        abs(last_point[1] - x) <= PATH_EPSILON and
        abs(last_point[2] - y) <= PATH_EPSILON then
        return
    end

    points[#points + 1] = { x, y }
end

local function interpolate_segment(segment, distance)
    if segment.length <= 0 then
        return segment.x1, segment.y1
    end

    local t = distance / segment.length

    return
        segment.x1 + ((segment.x2 - segment.x1) * t),
        segment.y1 + ((segment.y2 - segment.y1) * t)
end

function DrawHelpers.with_color(graphics, color, opacity, draw_fn)
    local alpha = resolve_alpha(color, opacity)
    if alpha <= 0 then
        return false
    end

    local saved_color = save_color(graphics)

    if Types.is_function(graphics.setColor) then
        graphics.setColor(
            color[1] or 1,
            color[2] or 1,
            color[3] or 1,
            alpha
        )
    end

    draw_fn()

    restore_color(graphics, saved_color)

    return true
end

function DrawHelpers.with_fill_color(graphics, fill_color, fill_opacity, draw_fn)
    return DrawHelpers.with_color(graphics, fill_color, fill_opacity, draw_fn)
end

function DrawHelpers.with_stroke_color(graphics, stroke_color, stroke_opacity, node_opacity, draw_fn)
    return DrawHelpers.with_color(
        graphics,
        stroke_color,
        (stroke_opacity or 1) * (node_opacity or 1),
        draw_fn
    )
end

function DrawHelpers.save_line_state(graphics)
    local state = {}

    if Types.is_function(graphics.getLineWidth) then
        state.width = graphics.getLineWidth()
    end

    if Types.is_function(graphics.getLineStyle) then
        state.style = graphics.getLineStyle()
    end

    if Types.is_function(graphics.getLineJoin) then
        state.join = graphics.getLineJoin()
    end

    if Types.is_function(graphics.getMiterLimit) then
        state.miter = graphics.getMiterLimit()
    end

    return state
end

function DrawHelpers.restore_line_state(graphics, state)
    if state.width ~= nil and Types.is_function(graphics.setLineWidth) then
        graphics.setLineWidth(state.width)
    end

    if state.style ~= nil and Types.is_function(graphics.setLineStyle) then
        graphics.setLineStyle(state.style)
    end

    if state.join ~= nil and Types.is_function(graphics.setLineJoin) then
        graphics.setLineJoin(state.join)
    end

    if state.miter ~= nil and Types.is_function(graphics.setMiterLimit) then
        graphics.setMiterLimit(state.miter)
    end
end

function DrawHelpers.restore_selected_line_state(graphics, saved_state, restore_flags)
    if restore_flags.width and saved_state.width ~= nil and Types.is_function(graphics.setLineWidth) then
        graphics.setLineWidth(saved_state.width)
    end

    if restore_flags.style and saved_state.style ~= nil and Types.is_function(graphics.setLineStyle) then
        graphics.setLineStyle(saved_state.style)
    end

    if restore_flags.join and saved_state.join ~= nil and Types.is_function(graphics.setLineJoin) then
        graphics.setLineJoin(saved_state.join)
    end

    if restore_flags.miter and saved_state.miter ~= nil and Types.is_function(graphics.setMiterLimit) then
        graphics.setMiterLimit(saved_state.miter)
    end
end

function DrawHelpers.apply_line_state(graphics, line_width, line_style, line_join, miter_limit)
    if line_width ~= nil and Types.is_function(graphics.setLineWidth) then
        graphics.setLineWidth(line_width)
    end

    if line_style ~= nil and Types.is_function(graphics.setLineStyle) then
        graphics.setLineStyle(line_style)
    end

    if line_join ~= nil and Types.is_function(graphics.setLineJoin) then
        graphics.setLineJoin(line_join)
    end

    if miter_limit ~= nil and
        line_join == Constants.STROKE_JOIN_MITER and
        Types.is_function(graphics.setMiterLimit) then
        graphics.setMiterLimit(miter_limit)
    end
end

function DrawHelpers.with_stroke_state(graphics, line_width, line_style, line_join, miter_limit, draw_fn)
    local saved_state = DrawHelpers.save_line_state(graphics)
    local restore_flags = {
        width = line_width ~= nil,
        style = line_style ~= nil,
        join = line_join ~= nil,
        miter = miter_limit ~= nil and line_join == Constants.STROKE_JOIN_MITER,
    }

    DrawHelpers.apply_line_state(
        graphics,
        line_width,
        line_style,
        line_join,
        miter_limit
    )

    draw_fn()

    DrawHelpers.restore_selected_line_state(graphics, saved_state, restore_flags)
end

function DrawHelpers.transform_local_points(node, points, transformed)

    if not Types.is_table(transformed) then
        transformed = {}
    end

    for index = 1, #points do
        local point = points[index]
        local world_x, world_y = node:localToWorld(point[1], point[2])
        local transformed_point = transformed[index]

        if transformed_point == nil then
            transformed_point = { world_x, world_y }
            transformed[index] = transformed_point
        else
            transformed_point[1] = world_x
            transformed_point[2] = world_y
        end
    end

    for index = #transformed, #points + 1, -1 do
        transformed[index] = nil
    end

    return transformed
end

function DrawHelpers.flatten_points(points, flattened)

    if not Types.is_table(flattened) then
        flattened = {}
    end

    local flattened_index = 1

    for index = 1, #points do
        local point = points[index]
        flattened[flattened_index] = point[1]
        flattened[flattened_index + 1] = point[2]
        flattened_index = flattened_index + 2
    end

    for index = #flattened, flattened_index, -1 do
        flattened[index] = nil
    end

    return flattened
end

function DrawHelpers.build_path_segments(points, closed)
    local segments = {}
    local point_count = #points
    local total_length = 0

    if point_count < 2 then
        return segments, total_length
    end

    local last_index = closed and point_count or (point_count - 1)

    for index = 1, last_index do
        local next_index = index + 1
        if next_index > point_count then
            next_index = 1
        end

        local from = points[index]
        local to = points[next_index]
        local dx = to[1] - from[1]
        local dy = to[2] - from[2]
        local length = sqrt((dx * dx) + (dy * dy))

        if length > 0 then
            segments[#segments + 1] = {
                x1 = from[1],
                y1 = from[2],
                x2 = to[1],
                y2 = to[2],
                length = length,
                start_distance = total_length,
                end_distance = total_length + length,
            }
            total_length = total_length + length
        end
    end

    return segments, total_length
end

function DrawHelpers.rotate_closed_path(points, shift_distance)
    local segments, total_length = DrawHelpers.build_path_segments(points, true)
    local point_count = #points

    if total_length <= 0 or point_count == 0 or #segments == 0 then
        return points, total_length
    end

    local shift = MathUtils.positive_mod(shift_distance or 0, total_length)
    if shift <= PATH_EPSILON or abs(total_length - shift) <= PATH_EPSILON then
        return points, total_length
    end

    local start_index = 1
    local start_x = points[1][1]
    local start_y = points[1][2]

    for index = 1, #segments do
        local segment = segments[index]
        if shift < segment.end_distance - PATH_EPSILON then
            start_index = index
            start_x, start_y = interpolate_segment(
                segment,
                shift - segment.start_distance
            )
            break
        end
    end

    local rotated = {
        { start_x, start_y },
    }

    for offset = 0, #segments - 1 do
        local segment = segments[((start_index - 1 + offset) % #segments) + 1]
        rotated[#rotated + 1] = { segment.x2, segment.y2 }
    end

    local last_point = rotated[#rotated]
    if last_point ~= nil and
        abs(last_point[1] - rotated[1][1]) <= PATH_EPSILON and
        abs(last_point[2] - rotated[1][2]) <= PATH_EPSILON then
        rotated[#rotated] = nil
    end

    return rotated, total_length
end

function DrawHelpers.draw_dashed_polyline(graphics, points, dash_length, gap_length, dash_offset, closed)
    if not Types.is_function(graphics.line) then
        return 0, 0
    end

    local segments, total_length = DrawHelpers.build_path_segments(points, closed)
    local emitted = 0

    if total_length <= 0 then
        return emitted, total_length
    end

    if gap_length <= 0 then
        return DrawHelpers.draw_polyline_segments(graphics, points, closed)
    end

    local cycle = dash_length + gap_length
    local distance = ((dash_offset or 0) % cycle) - cycle

    while distance < total_length do
        local dash_start = math.max(0, distance)
        local dash_end = math.min(total_length, distance + dash_length)

        if dash_end > dash_start then
            local dash_points = {}

            for index = 1, #segments do
                local segment = segments[index]
                local overlap_start = math.max(dash_start, segment.start_distance)
                local overlap_end = math.min(dash_end, segment.end_distance)

                if overlap_end > overlap_start then
                    local start_x, start_y = interpolate_segment(
                        segment,
                        overlap_start - segment.start_distance
                    )
                    local end_x, end_y = interpolate_segment(
                        segment,
                        overlap_end - segment.start_distance
                    )

                    append_point(dash_points, start_x, start_y)
                    append_point(dash_points, end_x, end_y)
                end
            end

            if #dash_points >= 2 then
                graphics.line(unpack(DrawHelpers.flatten_points(dash_points)))
                emitted = emitted + 1
            end
        end

        distance = distance + cycle
    end

    return emitted, total_length
end

function DrawHelpers.draw_polyline_segments(graphics, points, closed)
    if not Types.is_function(graphics.line) then
        return 0, 0
    end

    local segments, total_length = DrawHelpers.build_path_segments(points, closed)
    local polyline_points = {}

    if #segments == 0 then
        return 0, total_length
    end

    for index = 1, #points do
        append_point(polyline_points, points[index][1], points[index][2])
    end

    if closed == true and #points > 0 then
        append_point(polyline_points, points[1][1], points[1][2])
    end

    graphics.line(unpack(DrawHelpers.flatten_points(polyline_points)))

    return 1, total_length
end

function DrawHelpers.draw_polygon_fill(graphics, world_points, fill_color, fill_opacity)
    if not Types.is_function(graphics.polygon) then
        return false
    end

    return DrawHelpers.with_fill_color(graphics, fill_color, fill_opacity, function()
        graphics.polygon('fill', DrawHelpers.flatten_points(world_points))
    end)
end

function DrawHelpers.draw_polygon_stroke(graphics, world_points, stroke)
    if stroke == nil or stroke.color == nil or (stroke.width or 0) <= 0 then
        return false
    end

    local pattern = stroke.pattern or Constants.STROKE_PATTERN_SOLID
    if pattern == Constants.STROKE_PATTERN_DASHED then
        if not Types.is_function(graphics.line) then
            return false
        end
    elseif not Types.is_function(graphics.polygon) then
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
                stroke.join,
                stroke.miter_limit,
                function()
                    if pattern == Constants.STROKE_PATTERN_DASHED then
                        DrawHelpers.draw_dashed_polyline(
                            graphics,
                            world_points,
                            stroke.dash_length or 8,
                            stroke.gap_length or 0,
                            stroke.dash_offset or 0,
                            true
                        )
                    else
                        graphics.polygon('line', DrawHelpers.flatten_points(world_points))
                    end
                end
            )
        end
    )
end

function DrawHelpers.draw_polyline_stroke(graphics, world_points, stroke, closed)
    if stroke == nil or stroke.color == nil or (stroke.width or 0) <= 0 then
        return false
    end

    if not Types.is_function(graphics.line) then
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
                stroke.join,
                stroke.miter_limit,
                function()
                    if (stroke.pattern or Constants.STROKE_PATTERN_SOLID) == Constants.STROKE_PATTERN_DASHED then
                        DrawHelpers.draw_dashed_polyline(
                            graphics,
                            world_points,
                            stroke.dash_length or 8,
                            stroke.gap_length or 0,
                            stroke.dash_offset or 0,
                            closed == true
                        )
                    else
                        DrawHelpers.draw_polyline_segments(
                            graphics,
                            world_points,
                            closed == true
                        )
                    end
                end
            )
        end
    )
end

return DrawHelpers
