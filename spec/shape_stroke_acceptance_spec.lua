local UI = require('lib.ui')

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
    end
end

local function assert_true(value, message)
    if not value then
        error(message, 2)
    end
end

local function assert_nil(value, message)
    if value ~= nil then
        error(message .. ': expected nil, got ' .. tostring(value), 2)
    end
end

local function assert_near(actual, expected, tolerance, message)
    tolerance = tolerance or 0.01

    if math.abs(actual - expected) > tolerance then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
    end
end

local function find_call(calls, predicate)
    for index = 1, #calls do
        if predicate(calls[index]) then
            return calls[index], index
        end
    end

    return nil, nil
end

local function make_fake_graphics()
    local graphics = {
        calls = {},
        color = { 0.25, 0.5, 0.75, 0.9 },
        line_width = 1,
        line_style = 'smooth',
        line_join = 'none',
        miter_limit = 4,
    }

    function graphics.getColor()
        return graphics.color[1], graphics.color[2], graphics.color[3], graphics.color[4]
    end

    function graphics.setColor(r, g, b, a)
        graphics.color = { r, g, b, a }
        graphics.calls[#graphics.calls + 1] = {
            kind = 'color',
            r = r,
            g = g,
            b = b,
            a = a,
        }
    end

    function graphics.polygon(mode, points)
        local copy = {}

        for index = 1, #points do
            copy[index] = points[index]
        end

        graphics.calls[#graphics.calls + 1] = {
            kind = 'polygon',
            mode = tostring(mode),
            points = copy,
        }
    end

    function graphics.getLineWidth()
        return graphics.line_width
    end

    function graphics.setLineWidth(value)
        graphics.line_width = value
        graphics.calls[#graphics.calls + 1] = {
            kind = 'line_width',
            value = value,
        }
    end

    function graphics.getLineStyle()
        return graphics.line_style
    end

    function graphics.setLineStyle(value)
        graphics.line_style = value
        graphics.calls[#graphics.calls + 1] = {
            kind = 'line_style',
            value = value,
        }
    end

    function graphics.getLineJoin()
        return graphics.line_join
    end

    function graphics.setLineJoin(value)
        graphics.line_join = value
        graphics.calls[#graphics.calls + 1] = {
            kind = 'line_join',
            value = value,
        }
    end

    function graphics.getMiterLimit()
        return graphics.miter_limit
    end

    function graphics.setMiterLimit(value)
        graphics.miter_limit = value
        graphics.calls[#graphics.calls + 1] = {
            kind = 'miter_limit',
            value = value,
        }
    end

    function graphics.line(...)
        local points = { ... }
        graphics.calls[#graphics.calls + 1] = {
            kind = 'line',
            points = points,
            x1 = points[1],
            y1 = points[2],
            x2 = points[3],
            y2 = points[4],
        }
    end

    return graphics
end

local function assert_has_fill_and_stroke_calls(graphics, label)
    local fill_call, fill_index = find_call(graphics.calls, function(call)
        return call.kind == 'polygon' and call.mode == 'fill'
    end)
    local stroke_call, stroke_index = find_call(graphics.calls, function(call)
        return (call.kind == 'polygon' and call.mode == 'line') or call.kind == 'line'
    end)

    assert_true(fill_call ~= nil, label .. ' should still draw fill')
    assert_true(stroke_call ~= nil, label .. ' should draw stroke')
    assert_true(fill_index < stroke_index, label .. ' should paint stroke after fill')
end

local function run_every_shape_stroke_tests()
    local shapes = {
        {
            label = 'RectShape solid stroke',
            node = UI.RectShape.new({
                x = 10,
                y = 20,
                width = 20,
                height = 10,
                strokeColor = { 1, 0, 0, 1 },
                strokeWidth = 2,
                strokePattern = 'solid',
            }),
        },
        {
            label = 'CircleShape dashed stroke',
            node = UI.CircleShape.new({
                x = 10,
                y = 20,
                width = 40,
                height = 20,
                strokeColor = { 0, 1, 0, 1 },
                strokeWidth = 2,
                strokePattern = 'dashed',
                strokeDashLength = 6,
                strokeGapLength = 4,
            }),
        },
        {
            label = 'TriangleShape dashed stroke',
            node = UI.TriangleShape.new({
                x = 5,
                y = 7,
                width = 20,
                height = 18,
                strokeColor = { 0, 0, 1, 1 },
                strokeWidth = 2,
                strokePattern = 'dashed',
                strokeDashLength = 6,
                strokeGapLength = 4,
            }),
        },
        {
            label = 'DiamondShape solid stroke',
            node = UI.DiamondShape.new({
                x = 3,
                y = 4,
                width = 24,
                height = 12,
                strokeColor = { 1, 1, 0, 1 },
                strokeWidth = 2,
                strokePattern = 'solid',
            }),
        },
    }

    for index = 1, #shapes do
        local graphics = make_fake_graphics()
        local entry = shapes[index]

        entry.node:draw(graphics)
        assert_has_fill_and_stroke_calls(graphics, entry.label)
    end
end

local function run_stroke_color_absent_noop_tests()
    local shapes = {
        UI.RectShape.new({ width = 20, height = 10, strokeWidth = 3 }),
        UI.CircleShape.new({ width = 20, height = 20, strokeWidth = 3 }),
        UI.TriangleShape.new({ width = 20, height = 20, strokeWidth = 3 }),
        UI.DiamondShape.new({ width = 20, height = 20, strokeWidth = 3 }),
    }

    for index = 1, #shapes do
        local graphics = make_fake_graphics()
        local shape = shapes[index]

        shape:draw(graphics)

        local stroke_call = find_call(graphics.calls, function(call)
            return (call.kind == 'polygon' and call.mode == 'line') or call.kind == 'line'
        end)

        assert_nil(stroke_call,
            'Shape stroke should paint nothing when strokeColor is absent')
    end
end

local function run_circle_join_inert_tests()
    local circle = UI.CircleShape.new({
        x = 10,
        y = 20,
        width = 40,
        height = 20,
        strokeColor = { 1, 0, 0, 1 },
        strokeWidth = 2,
        strokeJoin = 'miter',
        strokeMiterLimit = 12,
    })
    local graphics = make_fake_graphics()

    circle:draw(graphics)

    local join_call = find_call(graphics.calls, function(call)
        return call.kind == 'line_join'
    end)
    local miter_call = find_call(graphics.calls, function(call)
        return call.kind == 'miter_limit'
    end)

    assert_nil(join_call,
        'CircleShape strokeJoin should be accepted but inert')
    assert_nil(miter_call,
        'CircleShape strokeMiterLimit should be accepted but inert')
    assert_equal(graphics.line_join, 'none',
        'CircleShape stroke drawing should preserve existing line join state')
    assert_equal(graphics.miter_limit, 4,
        'CircleShape stroke drawing should preserve existing miter limit state')
end

local function run_circle_solid_stroke_seam_regression_tests()
    local circle = UI.CircleShape.new({
        x = 10,
        y = 20,
        width = 40,
        height = 20,
        strokeColor = { 1, 0, 0, 1 },
        strokeWidth = 2,
        strokePattern = 'solid',
    })
    local graphics = make_fake_graphics()

    circle:draw(graphics)

    local polygon_stroke = find_call(graphics.calls, function(call)
        return call.kind == 'polygon' and call.mode == 'line'
    end)
    local line_stroke = find_call(graphics.calls, function(call)
        return call.kind == 'line'
    end)

    assert_nil(polygon_stroke,
        'CircleShape solid stroke should not use closed polygon line rendering at the seam')
    assert_true(line_stroke ~= nil,
        'CircleShape solid stroke should use line rendering')
    assert_true(line_stroke.points ~= nil and #line_stroke.points > 4,
        'CircleShape solid stroke should render as one continuous polyline rather than independent segments')
end

local function run_circle_solid_stroke_prefers_ellipse_when_available_tests()
    local circle = UI.CircleShape.new({
        x = 10,
        y = 20,
        width = 40,
        height = 20,
        strokeColor = { 1, 0, 0, 1 },
        strokeWidth = 2,
        strokePattern = 'solid',
    })
    local graphics = make_fake_graphics()

    function graphics.ellipse(mode, x, y, radius_x, radius_y, segments)
        graphics.calls[#graphics.calls + 1] = {
            kind = 'ellipse',
            mode = mode,
            x = x,
            y = y,
            radius_x = radius_x,
            radius_y = radius_y,
            segments = segments,
        }
    end

    circle:draw(graphics)

    local ellipse_stroke = find_call(graphics.calls, function(call)
        return call.kind == 'ellipse' and call.mode == 'line'
    end)
    local line_stroke = find_call(graphics.calls, function(call)
        return call.kind == 'line'
    end)

    assert_true(ellipse_stroke ~= nil,
        'CircleShape solid stroke should prefer ellipse rendering when the graphics adapter supports it')
    assert_nil(line_stroke,
        'CircleShape solid stroke should bypass the polyline fallback when ellipse rendering is available')
end

local function run_outward_stroke_hit_testing_tests()
    local stage = UI.Stage.new({
        width = 200,
        height = 120,
    })
    local shape = UI.RectShape.new({
        tag = 'stroked-rect',
        interactive = true,
        x = 20,
        y = 30,
        width = 40,
        height = 20,
        strokeColor = { 1, 0, 0, 1 },
        strokeWidth = 6,
    })

    stage.baseSceneLayer:addChild(shape)
    stage:update()

    local inside_x, inside_y = shape:localToWorld(20, 10)
    local stroke_only_x, stroke_only_y = shape:localToWorld(-2, 10)

    assert_equal(stage:resolveTarget(inside_x, inside_y), shape,
        'Shape should still target interior fill geometry when stroked')
    assert_nil(stage:resolveTarget(stroke_only_x, stroke_only_y),
        'Outward stroke extent should not expand hit targeting')
    assert_true(not shape:containsPoint(stroke_only_x, stroke_only_y),
        'Outward stroke extent should not expand containsPoint')

    stage:destroy()
end

local function run()
    run_every_shape_stroke_tests()
    run_stroke_color_absent_noop_tests()
    run_circle_join_inert_tests()
    run_circle_solid_stroke_seam_regression_tests()
    run_circle_solid_stroke_prefers_ellipse_when_available_tests()
    run_outward_stroke_hit_testing_tests()
end

return {
    run = run,
}
