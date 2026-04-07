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

local function run()
    run_public_surface_tests()
    run_default_draw_tests()
    run_explicit_fill_tests()
    run_noop_edge_tests()
    run_stage_draw_tests()
end

return {
    run = run,
}
