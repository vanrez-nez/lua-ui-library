local Container = require('lib.ui.core.container')
local Drawable = require('lib.ui.core.drawable')
local Shape = require('lib.ui.core.shape')
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

local function assert_near(actual, expected, tolerance, message)
    tolerance = tolerance or 0.01

    if math.abs(actual - expected) > tolerance then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
    end
end

local function assert_nil(value, message)
    if value ~= nil then
        error(message .. ': expected nil, got ' .. tostring(value), 2)
    end
end

local function assert_error(fn, needle, message)
    local ok, err = pcall(fn)

    if ok then
        error(message .. ': expected an error', 2)
    end

    local text = tostring(err)

    if needle and not text:find(needle, 1, true) then
        error(message .. ': expected error containing "' .. needle ..
            '", got "' .. text .. '"', 2)
    end
end

local function run_public_surface_tests()
    local node = Shape.new({
        tag = 'shape',
        width = 80,
        height = 40,
        interactive = true,
        fillColor = '#336699cc',
        fillOpacity = 0.25,
        strokeColor = '#ff8800cc',
        strokeOpacity = 0.5,
        strokeWidth = 3,
        strokeStyle = 'rough',
        strokeJoin = 'bevel',
        strokeMiterLimit = 7,
        strokePattern = 'dashed',
        strokeDashLength = 12,
        strokeGapLength = 5,
        strokeDashOffset = -2.5,
        opacity = 0.75,
    })

    assert_equal(UI.Shape, Shape,
        'lib.ui should expose the Shape module')
    assert_equal(node.tag, 'shape',
        'Shape should preserve inherited Container props')
    assert_equal(node.width, 80,
        'Shape should preserve inherited width')
    assert_equal(node.height, 40,
        'Shape should preserve inherited height')
    assert_equal(node.interactive, true,
        'Shape should preserve inherited interactive')
    assert_equal(node.pivotX, 0.5,
        'Shape should preserve inherited default pivotX')
    assert_equal(node.pivotY, 0.5,
        'Shape should preserve inherited default pivotY')
    assert_true(rawget(node, '_ui_shape_instance') == true,
        'Shape should mark shape-family instances internally')
    assert_true(node.fillColor[1] == 0x33 / 255 and
        node.fillColor[2] == 0x66 / 255 and
        node.fillColor[3] == 0x99 / 255 and
        node.fillColor[4] == 0xcc / 255,
        'Shape should resolve fillColor through the shared color parser')
    assert_equal(node.fillOpacity, 0.25,
        'Shape should preserve fillOpacity')
    assert_true(node.strokeColor[1] == 1 and
        node.strokeColor[2] == 0x88 / 255 and
        node.strokeColor[3] == 0 and
        node.strokeColor[4] == 0xcc / 255,
        'Shape should resolve strokeColor through the shared color parser')
    assert_equal(node.strokeOpacity, 0.5,
        'Shape should preserve strokeOpacity')
    assert_equal(node.strokeWidth, 3,
        'Shape should preserve strokeWidth')
    assert_equal(node.strokeStyle, 'rough',
        'Shape should preserve strokeStyle')
    assert_equal(node.strokeJoin, 'bevel',
        'Shape should preserve strokeJoin')
    assert_equal(node.strokeMiterLimit, 7,
        'Shape should preserve strokeMiterLimit')
    assert_equal(node.strokePattern, 'dashed',
        'Shape should preserve strokePattern')
    assert_equal(node.strokeDashLength, 12,
        'Shape should preserve strokeDashLength')
    assert_equal(node.strokeGapLength, 5,
        'Shape should preserve strokeGapLength')
    assert_equal(node.strokeDashOffset, -2.5,
        'Shape should preserve strokeDashOffset')
    assert_equal(node.opacity, 0.75,
        'Shape should preserve opacity')

    local default_opacity = Shape.new({
        width = 10,
        height = 10,
    })

    assert_true(default_opacity.fillColor[1] == 1 and
        default_opacity.fillColor[2] == 1 and
        default_opacity.fillColor[3] == 1 and
        default_opacity.fillColor[4] == 1,
        'Shape should default fillColor to white')
    assert_equal(default_opacity.fillOpacity, 1,
        'Shape should default fillOpacity to 1')
    assert_equal(default_opacity.strokeOpacity, 1,
        'Shape should default strokeOpacity to 1')
    assert_equal(default_opacity.strokeWidth, 0,
        'Shape should default strokeWidth to 0')
    assert_equal(default_opacity.strokeStyle, 'smooth',
        'Shape should default strokeStyle to smooth')
    assert_equal(default_opacity.strokeJoin, 'miter',
        'Shape should default strokeJoin to miter')
    assert_equal(default_opacity.strokeMiterLimit, 10,
        'Shape should default strokeMiterLimit to 10')
    assert_equal(default_opacity.strokePattern, 'solid',
        'Shape should default strokePattern to solid')
    assert_equal(default_opacity.strokeDashLength, 8,
        'Shape should default strokeDashLength to 8')
    assert_equal(default_opacity.strokeGapLength, 4,
        'Shape should default strokeGapLength to 4')
    assert_equal(default_opacity.strokeDashOffset, 0,
        'Shape should default strokeDashOffset to 0')
    assert_equal(default_opacity.opacity, 1,
        'Shape should default opacity to 1')
    assert_nil(default_opacity.strokeColor,
        'Shape should not default strokeColor')
    assert_equal(UI.RectShape, RectShape,
        'lib.ui should expose the RectShape module')
end

local function run_validation_tests()
    assert_error(function()
        Shape.new({
            fillOpacity = -0.01,
        })
    end, 'fillOpacity must be in [0, 1]',
    'Shape should reject negative fillOpacity')

    assert_error(function()
        Shape.new({
            fillOpacity = 1.01,
        })
    end, 'fillOpacity must be in [0, 1]',
    'Shape should reject fillOpacity above 1')

    assert_error(function()
        Shape.new({
            fillOpacity = 'opaque',
        })
    end, 'fillOpacity must be a number',
    'Shape should reject non-numeric fillOpacity')

    assert_error(function()
        Shape.new({
            fillColor = false,
        })
    end, 'expected a table or string',
    'Shape should reject invalid fillColor input')

    assert_error(function()
        Shape.new({
            strokeWidth = { 1, 2, 3, 4 },
        })
    end, 'strokeWidth must be a number',
    'Shape should reject non-scalar strokeWidth')

    assert_error(function()
        Shape.new({
            strokeStyle = 'dashed',
        })
    end, "strokeStyle: 'dashed' is not a valid value",
    'Shape should reject invalid strokeStyle values')

    assert_error(function()
        Shape.new({
            strokePattern = 'rough',
        })
    end, "strokePattern: 'rough' is not a valid value",
    'Shape should reject invalid strokePattern values')

    assert_error(function()
        Shape.new({
            strokeDashLength = 0,
        })
    end, 'strokeDashLength must be > 0',
    'Shape should reject non-positive strokeDashLength')

    assert_error(function()
        Shape.new({
            strokeGapLength = -1,
        })
    end, 'strokeGapLength must be >= 0',
    'Shape should reject negative strokeGapLength')

    assert_error(function()
        Shape.new({
            opacity = 2,
        })
    end, 'opacity must be in [0, 1]',
    'Shape should reject opacity above 1')
end

local function run_surface_exclusion_tests()
    local unsupported_props = {
        'padding',
        'alignX',
        'skin',
        'shader',
        'mask',
        'blendMode',
        'backgroundColor',
        'borderWidth',
        'borderPattern',
        'cornerRadius',
        'shadowColor',
    }

    for index = 1, #unsupported_props do
        local key = unsupported_props[index]

        assert_error(function()
            Shape.new({
                [key] = true,
            })
        end, 'Unsupported prop "' .. key .. '"',
        'Shape should reject unsupported Drawable prop ' .. key)
    end
end

local function run_leaf_only_tests()
    local parent = Container.new({
        width = 120,
        height = 80,
    })
    local shape = Shape.new({
        tag = 'leaf-shape',
        width = 60,
        height = 40,
    })
    local child = Container.new({
        tag = 'child',
        width = 20,
        height = 20,
    })

    parent:addChild(shape)

    assert_equal(shape.parent, parent,
        'Shape should remain attachable as a retained node')

    assert_error(function()
        shape:addChild(child)
    end, 'Shape may not contain child nodes',
    'Shape should reject child attachment')

    assert_error(function()
        shape:removeChild(child)
    end, 'Shape may not contain child nodes',
    'Shape should reject child removal APIs')

    assert_equal(#shape:getChildren(), 0,
        'Failed leaf-only composition should not mutate Shape children')
    assert_equal(child.parent, nil,
        'Failed leaf-only composition should not reparent the child')
end

local function run_stage_compatibility_tests()
    local stage = UI.Stage.new({
        width = 160,
        height = 120,
    })
    local shape = Shape.new({
        tag = 'shape',
        x = 20,
        y = 30,
        width = 50,
        height = 25,
        interactive = true,
    })

    stage.baseSceneLayer:addChild(shape)
    stage:update()

    assert_equal(shape.parent, stage.baseSceneLayer,
        'Shape should integrate into the retained tree under Stage')
    assert_equal(stage:resolveTarget(30, 40), shape,
        'Base Shape should use inherited rectangular containment until task 03')

    stage:destroy()
end

local function run_centroid_helper_tests()
    local shape = Shape.new({
        width = 80,
        height = 40,
    })
    local centroid_x, centroid_y = shape:get_local_centroid()

    assert_equal(centroid_x, 40,
        'Base Shape centroid helper should return the local horizontal center')
    assert_equal(centroid_y, 20,
        'Base Shape centroid helper should return the local vertical center')

    shape.pivotX = 0
    shape.pivotY = 0
    shape:set_centroid_pivot()

    assert_equal(shape.pivotX, 0.5,
        'Base Shape centroid helper should assign centered pivotX')
    assert_equal(shape.pivotY, 0.5,
        'Base Shape centroid helper should assign centered pivotY')

    local zero_width = Shape.new({
        width = 0,
        height = 20,
        pivotX = 0.2,
        pivotY = 0.8,
    })

    zero_width:set_centroid_pivot()

    assert_equal(zero_width.pivotX, 0.2,
        'Shape centroid helper should not mutate pivotX when width is zero')
    assert_equal(zero_width.pivotY, 0.8,
        'Shape centroid helper should not mutate pivotY when width is zero')

    local zero_height = Shape.new({
        width = 20,
        height = 0,
        pivotX = 0.3,
        pivotY = 0.7,
    })

    zero_height:set_centroid_pivot()

    assert_equal(zero_height.pivotX, 0.3,
        'Shape centroid helper should not mutate pivotX when height is zero')
    assert_equal(zero_height.pivotY, 0.7,
        'Shape centroid helper should not mutate pivotY when height is zero')

    local VertexCentroidShape = Shape:extends('VertexCentroidShapeSpec')

    function VertexCentroidShape:constructor(opts)
        Shape.constructor(self, opts)
    end

    function VertexCentroidShape.new(opts)
        return VertexCentroidShape(opts)
    end

    function VertexCentroidShape:get_local_vertices()
        local bounds = self:getLocalBounds()

        return {
            { bounds.x, bounds.y },
            { bounds.x + bounds.width, bounds.y },
            { bounds.x, bounds.y + bounds.height },
        }
    end

    function VertexCentroidShape:get_local_centroid()
        local vertices = self:get_local_vertices()
        local sum_x = 0
        local sum_y = 0

        for index = 1, #vertices do
            sum_x = sum_x + vertices[index][1]
            sum_y = sum_y + vertices[index][2]
        end

        return sum_x / #vertices, sum_y / #vertices
    end

    local custom_shape = VertexCentroidShape.new({
        width = 12,
        height = 18,
    })
    local custom_x, custom_y = custom_shape:get_local_centroid()

    assert_equal(custom_x, 4,
        'Custom shapes should be able to derive centroid x from local vertices')
    assert_equal(custom_y, 6,
        'Custom shapes should be able to derive centroid y from local vertices')

    custom_shape:set_centroid_pivot()

    assert_near(custom_shape.pivotX, 1 / 3, 0.0001,
        'Custom centroid helper should assign normalized pivotX from local geometry')
    assert_near(custom_shape.pivotY, 1 / 3, 0.0001,
        'Custom centroid helper should assign normalized pivotY from local geometry')

    custom_shape.width = 24

    assert_near(custom_shape.pivotX, 1 / 3, 0.0001,
        'Shape centroid helper should remain one-time after later width changes')
    assert_near(custom_shape.pivotY, 1 / 3, 0.0001,
        'Shape centroid helper should remain one-time after later size changes')
end

local function run_transformed_rect_shape_targeting_tests()
    local stage = UI.Stage.new({
        width = 240,
        height = 200,
    })
    local shape = UI.RectShape.new({
        tag = 'transformed-rect',
        interactive = true,
        x = 120,
        y = 100,
        width = 60,
        height = 30,
        rotation = math.rad(30),
        scaleX = 1.25,
        scaleY = 0.85,
        skewX = math.rad(12),
        skewY = math.rad(-8),
    })

    stage.baseSceneLayer:addChild(shape)
    stage:update()

    local inside_x, inside_y = shape:localToWorld(30, 15)
    local outside_left_x, outside_left_y = shape:localToWorld(-6, 15)
    local outside_bottom_x, outside_bottom_y = shape:localToWorld(30, 34)

    assert_true(shape:containsPoint(inside_x, inside_y),
        'RectShape should contain an interior point after transform inversion')
    assert_true(not shape:containsPoint(outside_left_x, outside_left_y),
        'RectShape should reject local points left of the transformed bounds')
    assert_true(not shape:containsPoint(outside_bottom_x, outside_bottom_y),
        'RectShape should reject local points below the transformed bounds')
    assert_equal(stage:resolveTarget(inside_x, inside_y), shape,
        'Stage should target transformed RectShape nodes through containsPoint')
    assert_nil(stage:resolveTarget(outside_left_x, outside_left_y),
        'Stage should not target transformed RectShape nodes for exterior points')

    stage:destroy()
end

local function run_mixed_sibling_targeting_tests()
    local stage = UI.Stage.new({
        width = 220,
        height = 180,
    })
    local container = Container.new({
        tag = 'container',
        interactive = true,
        x = 40,
        y = 40,
        width = 80,
        height = 60,
        zIndex = 1,
    })
    local drawable = Drawable.new({
        tag = 'drawable',
        interactive = true,
        x = 40,
        y = 40,
        width = 80,
        height = 60,
        zIndex = 2,
    })
    local rect_shape = UI.RectShape.new({
        tag = 'rect-shape',
        interactive = true,
        x = 40,
        y = 40,
        width = 80,
        height = 60,
        zIndex = 3,
    })

    stage.baseSceneLayer:addChild(container)
    stage.baseSceneLayer:addChild(drawable)
    stage.baseSceneLayer:addChild(rect_shape)
    stage:update()

    assert_equal(stage:resolveTarget(60, 60), rect_shape,
        'RectShape should participate in topmost-hit resolution beside Container and Drawable siblings')

    rect_shape.zIndex = 0
    stage:update()

    assert_equal(stage:resolveTarget(60, 60), drawable,
        'Lowering a RectShape should expose the next topmost mixed sibling target')

    drawable.zIndex = 0
    stage:update()

    assert_equal(stage:resolveTarget(60, 60), container,
        'Mixed sibling trees should preserve normal topmost-hit behavior across node families')

    stage:destroy()
end

local function run()
    run_public_surface_tests()
    run_validation_tests()
    run_surface_exclusion_tests()
    run_leaf_only_tests()
    run_stage_compatibility_tests()
    run_centroid_helper_tests()
    run_transformed_rect_shape_targeting_tests()
    run_mixed_sibling_targeting_tests()
end

return {
    run = run,
}
