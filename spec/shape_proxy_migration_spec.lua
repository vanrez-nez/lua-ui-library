local UI = require('lib.ui')
local Shape = require('lib.ui.core.shape')

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

local function assert_same(actual, expected, message)
    if actual ~= expected then
        error(message, 2)
    end
end

local function make_graphics()
    local graphics = {
        color = { 1, 1, 1, 1 },
    }

    function graphics.getColor()
        return graphics.color[1], graphics.color[2], graphics.color[3], graphics.color[4]
    end

    function graphics.setColor(r, g, b, a)
        graphics.color = { r, g, b, a }
    end

    function graphics.polygon() end
    function graphics.line() end
    function graphics.getLineWidth() return 1 end
    function graphics.setLineWidth() end
    function graphics.getLineStyle() return 'smooth' end
    function graphics.setLineStyle() end
    function graphics.getLineJoin() return 'none' end
    function graphics.setLineJoin() end
    function graphics.getMiterLimit() return 10 end
    function graphics.setMiterLimit() end

    return graphics
end

local function run_paint_dirty_tests()
    local shape = UI.RectShape.new({
        width = 20,
        height = 10,
    })

    shape:draw(make_graphics())
    assert_true(not shape.shape_dirty:is_dirty('paint'),
        'Shape draw should clear the initial paint dirty flag')

    shape.fillColor = { 1, 0, 0, 1 }
    assert_true(shape.shape_dirty:is_dirty('paint'),
        'Setting a paint prop should mark shape paint dirty')

    shape:draw(make_graphics())
    assert_true(not shape.shape_dirty:is_dirty('paint'),
        'Shape draw should clear paint dirty after refreshing paint scratch')
end

local function run_geometry_dirty_tests()
    local shape = UI.RectShape.new({
        width = 20,
        height = 10,
    })

    shape:draw(make_graphics())
    assert_true(not shape.shape_dirty:is_dirty('geometry'),
        'Shape draw should clear the initial geometry dirty flag')

    shape.width = 30
    assert_true(shape.shape_dirty:is_dirty('geometry'),
        'Setting width should mark shape geometry dirty')

    shape:draw(make_graphics())
    assert_true(not shape.shape_dirty:is_dirty('geometry'),
        'Shape draw should clear geometry dirty after refreshing point scratch')
end

local function run_scratch_identity_tests()
    local shape = UI.RectShape.new({
        width = 20,
        height = 10,
        strokeColor = { 1, 0, 0, 1 },
        strokeWidth = 2,
    })
    local graphics = make_graphics()

    shape:draw(graphics)

    local local_points = rawget(shape, '_local_points')
    local world_points = rawget(shape, '_world_points')
    local stroke_options = rawget(shape, '_stroke_options')

    shape:draw(graphics)

    assert_same(rawget(shape, '_local_points'), local_points,
        'Local-point scratch should keep identity across clean draw frames')
    assert_same(rawget(shape, '_world_points'), world_points,
        'World-point scratch should keep identity across clean draw frames')
    assert_same(rawget(shape, '_stroke_options'), stroke_options,
        'Stroke-option scratch should keep identity across clean draw frames')
end

local function run_fallback_tests()
    local shapes = {
        UI.RectShape.new({ width = 10, height = 10 }),
        UI.CircleShape.new({ width = 10, height = 10 }),
        UI.TriangleShape.new({ width = 10, height = 10 }),
        UI.DiamondShape.new({ width = 10, height = 10 }),
    }

    assert_equal(rawget(UI.RectShape, 'draw'), nil,
        'RectShape should inherit Shape.draw')
    assert_equal(rawget(UI.CircleShape, 'draw'), nil,
        'CircleShape should inherit Shape.draw')
    assert_equal(rawget(UI.TriangleShape, 'draw'), nil,
        'TriangleShape should inherit Shape.draw')
    assert_equal(rawget(UI.DiamondShape, 'draw'), nil,
        'DiamondShape should inherit Shape.draw')

    for index = 1, #shapes do
        local result = shapes[index]:draw('not graphics')
        assert_equal(result, nil,
            'Shape subclass should use the shared non-table graphics fallback')
    end

    assert_equal(Shape.draw, UI.RectShape.draw,
        'RectShape draw lookup should resolve to Shape.draw')
    assert_equal(Shape.draw, UI.CircleShape.draw,
        'CircleShape draw lookup should resolve to Shape.draw')
    assert_equal(Shape.draw, UI.TriangleShape.draw,
        'TriangleShape draw lookup should resolve to Shape.draw')
    assert_equal(Shape.draw, UI.DiamondShape.draw,
        'DiamondShape draw lookup should resolve to Shape.draw')
end

local function run()
    run_paint_dirty_tests()
    run_geometry_dirty_tests()
    run_scratch_identity_tests()
    run_fallback_tests()
end

return {
    run = run,
}
