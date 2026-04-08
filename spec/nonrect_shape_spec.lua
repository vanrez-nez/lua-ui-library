local UI = require('lib.ui')
local Container = require('lib.ui.core.container')

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

local function assert_color_call(call, r, g, b, a, message)
    assert_equal(call.kind, 'color', message .. ' kind')
    assert_near(call.r, r, 0.01, message .. ' r')
    assert_near(call.g, g, 0.01, message .. ' g')
    assert_near(call.b, b, 0.01, message .. ' b')
    assert_near(call.a, a, 0.01, message .. ' a')
end

local function assert_polygon_call(call, expected_points, message)
    assert_equal(call.kind, 'polygon', message .. ' kind')
    assert_equal(call.mode, 'fill', message .. ' mode')
    assert_equal(#call.points, #expected_points, message .. ' point count')

    for index = 1, #expected_points do
        assert_near(call.points[index], expected_points[index], 0.01,
            message .. ' point ' .. index)
    end
end

local function build_expected_circle_points(shape, segments)
    local points = {}
    local bounds = shape:getLocalBounds()
    local radius_x = bounds.width / 2
    local radius_y = bounds.height / 2
    local center_x = bounds.x + radius_x
    local center_y = bounds.y + radius_y

    for index = 0, segments - 1 do
        local angle = (-math.pi / 2) + ((index / segments) * (math.pi * 2))
        local world_x, world_y = shape:localToWorld(
            center_x + math.cos(angle) * radius_x,
            center_y + math.sin(angle) * radius_y
        )
        points[#points + 1] = world_x
        points[#points + 1] = world_y
    end

    return points
end

local function build_expected_world_points(shape, local_points)
    local points = {}

    for index = 1, #local_points do
        local point = local_points[index]
        local world_x, world_y = shape:localToWorld(point[1], point[2])
        points[#points + 1] = world_x
        points[#points + 1] = world_y
    end

    return points
end

local function run_public_surface_tests()
    assert_equal(UI.CircleShape, require('lib.ui.shapes.circle_shape'),
        'lib.ui should expose the CircleShape module')
    assert_equal(UI.TriangleShape, require('lib.ui.shapes.triangle_shape'),
        'lib.ui should expose the TriangleShape module')
    assert_equal(UI.DiamondShape, require('lib.ui.shapes.diamond_shape'),
        'lib.ui should expose the DiamondShape module')
end

local function run_circle_tests()
    local shape = UI.CircleShape.new({
        x = 10,
        y = 20,
        width = 40,
        height = 20,
    })
    local graphics = make_fake_graphics()

    shape:draw(graphics)

    assert_equal(#graphics.calls, 3,
        'CircleShape should emit color, polygon, and restore-color calls')
    assert_color_call(graphics.calls[1], 1, 1, 1, 1,
        'CircleShape should set fill color')
    assert_polygon_call(graphics.calls[2], build_expected_circle_points(shape, 32),
        'CircleShape should draw the inscribed ellipse polygon')
    assert_color_call(graphics.calls[3], 0.25, 0.5, 0.75, 0.9,
        'CircleShape should restore the previous color')

    assert_true(shape:_contains_local_point(20, 10),
        'CircleShape should contain its center')
    assert_true(shape:_contains_local_point(20, 0),
        'CircleShape should include its top edge')
    assert_true(not shape:_contains_local_point(0, 0),
        'CircleShape should exclude a rectangular corner outside the ellipse')
end

local function run_circle_stroke_tests()
    local solid = UI.CircleShape.new({
        x = 10,
        y = 20,
        width = 40,
        height = 20,
        strokeColor = { 1, 0, 0, 1 },
        strokeWidth = 2,
        strokeJoin = 'bevel',
        strokeMiterLimit = 9,
    })
    local solid_graphics = make_fake_graphics()

    solid:draw(solid_graphics)

    local solid_fill, solid_fill_index = find_call(solid_graphics.calls, function(call)
        return call.kind == 'polygon' and call.mode == 'fill'
    end)
    local solid_stroke, solid_stroke_index = find_call(solid_graphics.calls, function(call)
        return call.kind == 'line'
    end)
    local solid_polygon_stroke = find_call(solid_graphics.calls, function(call)
        return call.kind == 'polygon' and call.mode == 'line'
    end)

    assert_true(solid_fill ~= nil,
        'CircleShape should still render fill when stroke is enabled')
    assert_true(solid_stroke ~= nil,
        'CircleShape solid stroke should emit line segments')
    assert_nil(solid_polygon_stroke,
        'CircleShape solid stroke should avoid closed polygon line seam rendering')
    assert_true(solid_fill_index < solid_stroke_index,
        'CircleShape solid stroke should render after fill')

    local dashed = UI.CircleShape.new({
        x = 10,
        y = 20,
        width = 40,
        height = 20,
        strokeColor = { 0, 1, 0, 1 },
        strokeWidth = 2,
        strokePattern = 'dashed',
        strokeDashLength = 6,
        strokeGapLength = 4,
        strokeDashOffset = 0,
        strokeJoin = 'miter',
    })
    local dashed_graphics = make_fake_graphics()

    dashed:draw(dashed_graphics)

    local dash_call = find_call(dashed_graphics.calls, function(call)
        return call.kind == 'line'
    end)
    local seam_call = find_call(dashed_graphics.calls, function(call)
        return call.kind == 'line' and (
            (math.abs(call.x1 - 30) <= 0.01 and math.abs(call.y1 - 20) <= 0.01) or
            (math.abs(call.x2 - 30) <= 0.01 and math.abs(call.y2 - 20) <= 0.01)
        )
    end)

    assert_true(dash_call ~= nil,
        'CircleShape dashed stroke should emit line segments')
    assert_nil(seam_call,
        'CircleShape dashed stroke should avoid emitting a dash cap at the top-center seam')
end

local function run_triangle_tests()
    local shape = UI.TriangleShape.new({
        x = 5,
        y = 7,
        width = 20,
        height = 18,
    })
    local graphics = make_fake_graphics()

    shape:draw(graphics)

    assert_equal(#graphics.calls, 3,
        'TriangleShape should emit color, polygon, and restore-color calls')
    assert_color_call(graphics.calls[1], 1, 1, 1, 1,
        'TriangleShape should set fill color')
    assert_polygon_call(graphics.calls[2], build_expected_world_points(shape, {
        { 10, 0 },
        { 20, 18 },
        { 0, 18 },
    }), 'TriangleShape should draw the full-bounds canonical triangle')
    assert_color_call(graphics.calls[3], 0.25, 0.5, 0.75, 0.9,
        'TriangleShape should restore the previous color')

    assert_true(shape:_contains_local_point(10, 9),
        'TriangleShape should contain an interior point')
    assert_true(shape:_contains_local_point(10, 0),
        'TriangleShape should include its top vertex')
    assert_true(not shape:_contains_local_point(0, 0),
        'TriangleShape should exclude the top-left corner outside the silhouette')
    assert_true(shape:_contains_local_point(10, 9),
        'TriangleShape should contain the local bounds center when pivotX/Y are 0.5')
    assert_true(shape:_contains_local_point(10, 16),
        'TriangleShape should use the full local height for its base')
end

local function run_diamond_tests()
    local shape = UI.DiamondShape.new({
        x = 3,
        y = 4,
        width = 24,
        height = 12,
    })
    local graphics = make_fake_graphics()

    shape:draw(graphics)

    assert_equal(#graphics.calls, 3,
        'DiamondShape should emit color, polygon, and restore-color calls')
    assert_color_call(graphics.calls[1], 1, 1, 1, 1,
        'DiamondShape should set fill color')
    assert_polygon_call(graphics.calls[2], build_expected_world_points(shape, {
        { 12, 0 },
        { 24, 6 },
        { 12, 12 },
        { 0, 6 },
    }), 'DiamondShape should draw the midpoint-based diamond')
    assert_color_call(graphics.calls[3], 0.25, 0.5, 0.75, 0.9,
        'DiamondShape should restore the previous color')

    assert_true(shape:_contains_local_point(12, 6),
        'DiamondShape should contain its center')
    assert_true(shape:_contains_local_point(12, 0),
        'DiamondShape should include its top midpoint')
    assert_true(not shape:_contains_local_point(0, 0),
        'DiamondShape should exclude the corner outside the silhouette')
end

local function run_polygon_stroke_tests()
    local triangle = UI.TriangleShape.new({
        x = 5,
        y = 7,
        width = 20,
        height = 18,
        strokeColor = { 1, 0, 0, 1 },
        strokeWidth = 2,
        strokeJoin = 'miter',
        strokeMiterLimit = 9,
    })
    local triangle_graphics = make_fake_graphics()

    triangle:draw(triangle_graphics)

    local triangle_stroke, triangle_stroke_index = find_call(triangle_graphics.calls, function(call)
        return call.kind == 'polygon' and call.mode == 'line'
    end)
    local triangle_fill, triangle_fill_index = find_call(triangle_graphics.calls, function(call)
        return call.kind == 'polygon' and call.mode == 'fill'
    end)

    assert_true(triangle_fill ~= nil,
        'TriangleShape should still render fill when stroke is enabled')
    assert_true(triangle_stroke ~= nil,
        'TriangleShape solid stroke should use polygon line rendering')
    assert_true(triangle_fill_index < triangle_stroke_index,
        'TriangleShape stroke should render after fill')
    assert_equal(triangle_graphics.line_width, 1,
        'TriangleShape stroke should restore line width')
    assert_equal(triangle_graphics.line_style, 'smooth',
        'TriangleShape stroke should restore line style')
    assert_equal(triangle_graphics.line_join, 'none',
        'TriangleShape stroke should restore line join')
    assert_equal(triangle_graphics.miter_limit, 4,
        'TriangleShape stroke should restore miter limit')

    local diamond = UI.DiamondShape.new({
        x = 3,
        y = 4,
        width = 24,
        height = 12,
        strokeColor = { 0, 1, 0, 1 },
        strokeWidth = 2,
        strokePattern = 'dashed',
        strokeDashLength = 6,
        strokeGapLength = 4,
        strokeDashOffset = 0,
    })
    local diamond_graphics = make_fake_graphics()

    diamond:draw(diamond_graphics)

    local diamond_dash = find_call(diamond_graphics.calls, function(call)
        return call.kind == 'line'
    end)

    assert_true(diamond_dash ~= nil,
        'DiamondShape dashed stroke should emit line segments')
    assert_near(diamond_dash.x1, 15, 0.01,
        'DiamondShape dashed stroke should start at the top vertex world x')
    assert_near(diamond_dash.y1, 4, 0.01,
        'DiamondShape dashed stroke should start at the top vertex world y')
end

local function run_centroid_helper_behavior_tests()
    local shapes = {
        {
            label = 'RectShape',
            node = UI.RectShape.new({
                width = 40,
                height = 20,
                pivotX = 0,
                pivotY = 0,
            }),
        },
        {
            label = 'CircleShape',
            node = UI.CircleShape.new({
                width = 40,
                height = 20,
                pivotX = 0,
                pivotY = 0,
            }),
        },
        {
            label = 'TriangleShape',
            node = UI.TriangleShape.new({
                width = 40,
                height = 20,
                pivotX = 0,
                pivotY = 0,
            }),
        },
        {
            label = 'DiamondShape',
            node = UI.DiamondShape.new({
                width = 40,
                height = 20,
                pivotX = 0,
                pivotY = 0,
            }),
        },
    }

    for index = 1, #shapes do
        local entry = shapes[index]
        local centroid_x, centroid_y = entry.node:get_local_centroid()

        assert_equal(centroid_x, 20,
            entry.label .. ' should keep bounds-center centroid helper x')
        assert_equal(centroid_y, 10,
            entry.label .. ' should keep bounds-center centroid helper y')

        entry.node:set_centroid_pivot()

        assert_equal(entry.node.pivotX, 0.5,
            entry.label .. ' should keep bounds-center pivotX when using centroid helper')
        assert_equal(entry.node.pivotY, 0.5,
            entry.label .. ' should keep bounds-center pivotY when using centroid helper')
    end
end

local function run_transformed_targeting_tests()
    local stage = UI.Stage.new({
        width = 260,
        height = 220,
    })
    local circle = UI.CircleShape.new({
        tag = 'circle',
        interactive = true,
        x = 100,
        y = 80,
        width = 60,
        height = 30,
        pivotX = 0.5,
        pivotY = 0.5,
        rotation = math.rad(25),
        scaleX = 1.2,
        scaleY = 0.9,
    })
    local triangle = UI.TriangleShape.new({
        tag = 'triangle',
        interactive = true,
        x = 180,
        y = 120,
        width = 50,
        height = 40,
        pivotX = 0.5,
        pivotY = 0.5,
        rotation = math.rad(-20),
        skewX = math.rad(10),
    })
    local diamond = UI.DiamondShape.new({
        tag = 'diamond',
        interactive = true,
        x = 70,
        y = 170,
        width = 48,
        height = 28,
        pivotX = 0.5,
        pivotY = 0.5,
        rotation = math.rad(35),
        skewY = math.rad(-12),
    })

    stage.baseSceneLayer:addChild(circle)
    stage.baseSceneLayer:addChild(triangle)
    stage.baseSceneLayer:addChild(diamond)
    stage:update()

    local circle_inside_x, circle_inside_y = circle:localToWorld(30, 15)
    local circle_outside_x, circle_outside_y = circle:localToWorld(0, 0)
    local triangle_inside_x, triangle_inside_y = triangle:localToWorld(25, 30)
    local triangle_outside_x, triangle_outside_y = triangle:localToWorld(0, 0)
    local diamond_inside_x, diamond_inside_y = diamond:localToWorld(24, 14)
    local diamond_outside_x, diamond_outside_y = diamond:localToWorld(0, 0)

    assert_true(circle:containsPoint(circle_inside_x, circle_inside_y),
        'CircleShape should contain transformed interior points')
    assert_true(not circle:containsPoint(circle_outside_x, circle_outside_y),
        'CircleShape should reject transformed exterior corner points')
    assert_equal(stage:resolveTarget(circle_inside_x, circle_inside_y), circle,
        'Stage should target transformed CircleShape nodes through local ellipse containment')
    assert_nil(stage:resolveTarget(circle_outside_x, circle_outside_y),
        'Stage should not target transformed CircleShape nodes outside the ellipse')

    assert_true(triangle:containsPoint(triangle_inside_x, triangle_inside_y),
        'TriangleShape should contain transformed interior points')
    assert_true(not triangle:containsPoint(triangle_outside_x, triangle_outside_y),
        'TriangleShape should reject transformed exterior corner points')
    assert_equal(stage:resolveTarget(triangle_inside_x, triangle_inside_y), triangle,
        'Stage should target transformed TriangleShape nodes through local polygon containment')
    assert_nil(stage:resolveTarget(triangle_outside_x, triangle_outside_y),
        'Stage should not target transformed TriangleShape nodes outside the silhouette')

    assert_true(diamond:containsPoint(diamond_inside_x, diamond_inside_y),
        'DiamondShape should contain transformed interior points')
    assert_true(not diamond:containsPoint(diamond_outside_x, diamond_outside_y),
        'DiamondShape should reject transformed exterior corner points')
    assert_equal(stage:resolveTarget(diamond_inside_x, diamond_inside_y), diamond,
        'Stage should target transformed DiamondShape nodes through local midpoint geometry')
    assert_nil(stage:resolveTarget(diamond_outside_x, diamond_outside_y),
        'Stage should not target transformed DiamondShape nodes outside the silhouette')

    stage:destroy()
end

local function run_stage_draw_tests()
    local stage = UI.Stage.new({
        width = 260,
        height = 220,
    })
    local circle = UI.CircleShape.new({
        x = 100,
        y = 80,
        width = 60,
        height = 30,
        pivotX = 0.5,
        pivotY = 0.5,
        rotation = math.rad(25),
    })
    local triangle = UI.TriangleShape.new({
        x = 180,
        y = 120,
        width = 50,
        height = 40,
        pivotX = 0.5,
        pivotY = 0.5,
        rotation = math.rad(-20),
    })
    local diamond = UI.DiamondShape.new({
        x = 70,
        y = 170,
        width = 48,
        height = 28,
        pivotX = 0.5,
        pivotY = 0.5,
        rotation = math.rad(35),
    })
    local graphics = make_fake_graphics()

    stage.baseSceneLayer:addChild(circle)
    stage.baseSceneLayer:addChild(triangle)
    stage.baseSceneLayer:addChild(diamond)
    stage:update()
    stage:draw(graphics)

    assert_equal(#graphics.calls, 9,
        'Stage draw should render all non-rect shapes through the retained draw path')
    assert_polygon_call(graphics.calls[2], build_expected_circle_points(circle, 32),
        'Stage draw should render CircleShape from transformed local ellipse points')
    assert_polygon_call(graphics.calls[5], build_expected_world_points(triangle, {
        { 25, 0 },
        { 50, 40 },
        { 0, 40 },
    }), 'Stage draw should render TriangleShape from transformed full-bounds local triangle points')
    assert_polygon_call(graphics.calls[8], build_expected_world_points(diamond, {
        { 24, 0 },
        { 48, 14 },
        { 24, 28 },
        { 0, 14 },
    }), 'Stage draw should render DiamondShape from transformed local midpoint points')

    stage:destroy()
end

local function run_rectangular_clip_behavior_tests()
    local stage = UI.Stage.new({
        width = 240,
        height = 200,
    })
    local diamond = UI.DiamondShape.new({
        tag = 'clip-diamond',
        x = 60,
        y = 40,
        width = 100,
        height = 100,
        clipChildren = true,
        fillColor = { 0.2, 0.4, 0.6, 0.4 },
    })
    local child = Container.new({
        tag = 'corner-child',
        interactive = true,
        x = 0,
        y = 0,
        width = 24,
        height = 24,
    })

    stage.baseSceneLayer:addChild(diamond)
    Container.addChild(diamond, child)
    stage:update()

    local probe_x, probe_y = child:localToWorld(12, 12)

    assert_true(not diamond:containsPoint(probe_x, probe_y),
        'DiamondShape should not contain a corner probe outside its visible silhouette')
    assert_equal(stage:resolveTarget(probe_x, probe_y), child,
        'Shape clipChildren should remain rectangular and allow descendant hits inside bounds')

    stage:destroy()
end

local function run()
    run_public_surface_tests()
    run_circle_tests()
    run_circle_stroke_tests()
    run_triangle_tests()
    run_diamond_tests()
    run_polygon_stroke_tests()
    run_centroid_helper_behavior_tests()
    run_transformed_targeting_tests()
    run_stage_draw_tests()
    run_rectangular_clip_behavior_tests()
end

return {
    run = run,
}
