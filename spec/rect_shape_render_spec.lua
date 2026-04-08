local RectShape = require('lib.ui.shapes.rect_shape')
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
    }

    function graphics.getColor()
        return graphics.color[1], graphics.color[2], graphics.color[3], graphics.color[4]
    end

    function graphics.setColor(r, g, b, a)
        graphics.color = { r, g, b, a }
        graphics.calls[#graphics.calls + 1] = string.format(
            'color:%.2f:%.2f:%.2f:%.2f',
            r,
            g,
            b,
            a
        )
    end

    function graphics.rectangle(mode, x, y, width, height)
        graphics.calls[#graphics.calls + 1] = string.format(
            'rectangle:%s:%.2f:%.2f:%.2f:%.2f',
            tostring(mode),
            x,
            y,
            width,
            height
        )
    end

    return graphics
end

local function make_fake_polygon_graphics()
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

    function graphics.line(x1, y1, x2, y2)
        graphics.calls[#graphics.calls + 1] = {
            kind = 'line',
            x1 = x1,
            y1 = y1,
            x2 = x2,
            y2 = y2,
        }
    end

    return graphics
end

local function assert_sequence(actual, expected, message)
    assert_equal(#actual, #expected, message .. ' length')

    for index = 1, #expected do
        assert_equal(actual[index], expected[index], message .. ' index ' .. index)
    end
end

local function run_public_surface_tests()
    assert_equal(UI.RectShape, RectShape,
        'lib.ui should expose the RectShape module')
end

local function run_default_draw_tests()
    local shape = RectShape.new({
        x = 10,
        y = 20,
        width = 30,
        height = 40,
    })
    local graphics = make_fake_graphics()

    shape:draw(graphics)

    assert_sequence(graphics.calls, {
        'color:1.00:1.00:1.00:1.00',
        'rectangle:fill:10.00:20.00:30.00:40.00',
        'color:0.25:0.50:0.75:0.90',
    }, 'RectShape should render a default white filled rectangle and restore color')
end

local function run_explicit_fill_tests()
    local shape = RectShape.new({
        x = 4,
        y = 6,
        width = 12,
        height = 14,
        fillColor = { 0.2, 0.4, 0.6, 0.8 },
        fillOpacity = 0.5,
    })
    local graphics = make_fake_graphics()

    shape:draw(graphics)

    assert_sequence(graphics.calls, {
        'color:0.20:0.40:0.60:0.40',
        'rectangle:fill:4.00:6.00:12.00:14.00',
        'color:0.25:0.50:0.75:0.90',
    }, 'RectShape should combine fillColor alpha with fillOpacity')
end

local function run_noop_edge_tests()
    local zero_area = RectShape.new({
        width = 0,
        height = 20,
    })
    local transparent = RectShape.new({
        width = 20,
        height = 20,
        fillOpacity = 0,
    })
    local transparent_color = RectShape.new({
        width = 20,
        height = 20,
        fillColor = { 1, 0, 0, 0 },
    })

    local zero_graphics = make_fake_graphics()
    local transparent_graphics = make_fake_graphics()
    local transparent_color_graphics = make_fake_graphics()

    zero_area:draw(zero_graphics)
    transparent:draw(transparent_graphics)
    transparent_color:draw(transparent_color_graphics)

    assert_equal(#zero_graphics.calls, 0,
        'RectShape should skip drawing zero-area bounds')
    assert_equal(#transparent_graphics.calls, 0,
        'RectShape should skip drawing fully transparent opacity')
    assert_equal(#transparent_color_graphics.calls, 0,
        'RectShape should skip drawing fully transparent fillColor')
end

local function run_stage_draw_tests()
    local stage = UI.Stage.new({ width = 160, height = 90 })
    local shape = UI.RectShape.new({
        tag = 'rect-shape',
        x = 8,
        y = 12,
        width = 16,
        height = 18,
    })
    local graphics = make_fake_graphics()

    stage.baseSceneLayer:addChild(shape)
    stage:update()
    stage:draw(graphics)

    assert_sequence(graphics.calls, {
        'color:1.00:1.00:1.00:1.00',
        'rectangle:fill:8.00:12.00:16.00:18.00',
        'color:0.25:0.50:0.75:0.90',
    }, 'Stage should invoke RectShape draw through the ordinary retained draw path')

    stage:destroy()
end

local function run_polygon_stroke_tests()
    local solid = RectShape.new({
        x = 2,
        y = 4,
        width = 12,
        height = 8,
        fillColor = { 0.2, 0.3, 0.4, 1 },
        strokeColor = { 1, 0, 0, 0.5 },
        strokeOpacity = 0.5,
        strokeWidth = 3,
        strokeStyle = 'rough',
        strokeJoin = 'bevel',
    })
    local solid_graphics = make_fake_polygon_graphics()

    solid:draw(solid_graphics)

    local fill_call, fill_index = find_call(solid_graphics.calls, function(call)
        return call.kind == 'polygon' and call.mode == 'fill'
    end)
    local stroke_call, stroke_index = find_call(solid_graphics.calls, function(call)
        return call.kind == 'polygon' and call.mode == 'line'
    end)

    assert_true(fill_call ~= nil,
        'RectShape polygon path should fill before stroke')
    assert_true(stroke_call ~= nil,
        'RectShape solid stroke should use polygon line rendering')
    assert_true(fill_index < stroke_index,
        'RectShape solid stroke should render after fill')
    assert_equal(stroke_call.mode, 'line',
        'RectShape solid stroke should use line mode')
    assert_equal(solid_graphics.line_width, 1,
        'RectShape solid stroke should restore line width')
    assert_equal(solid_graphics.line_style, 'smooth',
        'RectShape solid stroke should restore line style')
    assert_equal(solid_graphics.line_join, 'none',
        'RectShape solid stroke should restore line join')
    assert_equal(solid_graphics.miter_limit, 4,
        'RectShape solid stroke should restore miter limit')

    local dashed = RectShape.new({
        x = 10,
        y = 20,
        width = 20,
        height = 10,
        strokeColor = { 0, 1, 0, 1 },
        strokeWidth = 2,
        strokePattern = 'dashed',
        strokeDashLength = 6,
        strokeGapLength = 4,
        strokeDashOffset = 0,
    })
    local dashed_graphics = make_fake_polygon_graphics()

    dashed:draw(dashed_graphics)

    local dashed_call = find_call(dashed_graphics.calls, function(call)
        return call.kind == 'line'
    end)

    assert_true(dashed_call ~= nil,
        'RectShape dashed stroke should emit line segments')
    assert_equal(dashed_call.x1, 10,
        'RectShape dashed stroke should start at the top-left world point')
    assert_equal(dashed_call.y1, 20,
        'RectShape dashed stroke should use the top-left canonical start point')
end

local function run()
    run_public_surface_tests()
    run_default_draw_tests()
    run_explicit_fill_tests()
    run_noop_edge_tests()
    run_stage_draw_tests()
    run_polygon_stroke_tests()
end

return {
    run = run,
}
