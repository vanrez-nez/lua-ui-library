local Rectangle = require('lib.ui.core.rectangle')
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

local function assert_rectangle_equal(actual, expected, message)
    assert_true(actual:equals(expected, 1e-9),
        message .. ': expected ' .. tostring(expected) ..
        ', got ' .. tostring(actual))
end

local function get_world_origin(node)
    local bounds = node:getWorldBounds()
    return bounds.x, bounds.y
end

local function run_safe_area_content_region_tests()
    local stage = UI.Stage.new({
        width = 300,
        height = 200,
        safeAreaInsets = { 20, 30, 40, 10 },
    })
    local safe = UI.SafeAreaContainer.new({
        width = 300,
        height = 200,
        padding = { 3, 4, 5, 6 },
    })
    local child = UI.Container.new({
        width = '100%',
        height = '100%',
    })

    safe:addChild(child)
    stage.baseSceneLayer:addChild(safe)
    stage:update()

    assert_rectangle_equal(safe:_get_effective_content_rect(),
        Rectangle.new(16, 23, 250, 132),
        'SafeAreaContainer should derive its content rect from Stage safe-area bounds plus padding')
    assert_rectangle_equal(child:getLocalBounds(),
        Rectangle.new(0, 0, 250, 132),
        'Percentage-sized descendants should resolve against the safe-area-derived content region')

    local child_x, child_y = get_world_origin(child)

    assert_equal(child_x, 16,
        'SafeAreaContainer should place descendants at the derived content origin on the x axis')
    assert_equal(child_y, 23,
        'SafeAreaContainer should place descendants at the derived content origin on the y axis')

    stage:destroy()
end

local function run_zero_inset_and_passthrough_tests()
    local zero_stage = UI.Stage.new({
        width = 240,
        height = 160,
        safeAreaInsets = { 0, 0, 0, 0 },
    })
    local zero_safe = UI.SafeAreaContainer.new({
        width = 240,
        height = 160,
    })
    local zero_child = UI.Container.new({
        width = '100%',
        height = '100%',
    })

    zero_safe:addChild(zero_child)
    zero_stage.baseSceneLayer:addChild(zero_safe)
    zero_stage:update()

    assert_rectangle_equal(zero_safe:_get_effective_content_rect(),
        Rectangle.new(0, 0, 240, 160),
        'Zero-inset environments should match plain non-inset layout')
    assert_rectangle_equal(zero_child:getLocalBounds(),
        Rectangle.new(0, 0, 240, 160),
        'Zero-inset environments should not shrink descendant percentages')

    zero_stage:destroy()

    local stage = UI.Stage.new({
        width = 300,
        height = 200,
        safeAreaInsets = { 20, 30, 40, 10 },
    })
    local safe = UI.SafeAreaContainer.new({
        width = 300,
        height = 200,
        applyTop = false,
        applyBottom = false,
        applyLeft = false,
        applyRight = false,
    })
    local child = UI.Container.new({
        width = '100%',
        height = '100%',
    })

    safe:addChild(child)
    stage.baseSceneLayer:addChild(safe)
    stage:update()

    assert_rectangle_equal(safe:_get_effective_content_rect(),
        Rectangle.new(0, 0, 300, 200),
        'When all apply flags are false, SafeAreaContainer should not apply inset adjustment')
    assert_rectangle_equal(child:getLocalBounds(),
        Rectangle.new(0, 0, 300, 200),
        'When all apply flags are false, descendants should resolve against the raw container region')

    stage:destroy()
end

local function run_nested_safe_area_tests()
    local stage = UI.Stage.new({
        width = 300,
        height = 200,
        safeAreaInsets = { 20, 30, 40, 10 },
    })
    local outer = UI.SafeAreaContainer.new({
        width = 300,
        height = 200,
    })
    local inner = UI.SafeAreaContainer.new({
        width = '100%',
        height = '100%',
    })
    local leaf = UI.Container.new({
        width = '100%',
        height = '100%',
    })

    inner:addChild(leaf)
    outer:addChild(inner)
    stage.baseSceneLayer:addChild(outer)
    stage:update()

    assert_rectangle_equal(outer:_get_effective_content_rect(),
        Rectangle.new(10, 20, 260, 140),
        'The outer SafeAreaContainer should expose the Stage safe-area-derived content region')
    assert_rectangle_equal(inner:getLocalBounds(),
        Rectangle.new(0, 0, 260, 140),
        'A nested SafeAreaContainer should size itself from the parent safe-area content region')
    assert_rectangle_equal(inner:_get_effective_content_rect(),
        Rectangle.new(0, 0, 260, 140),
        'Nested SafeAreaContainers should not compound safe-area insets relative to the parent content')
    assert_rectangle_equal(leaf:getLocalBounds(),
        Rectangle.new(0, 0, 260, 140),
        'Nested SafeAreaContainer descendants should continue resolving percentages from the effective safe-area region')

    local inner_x, inner_y = get_world_origin(inner)
    local leaf_x, leaf_y = get_world_origin(leaf)

    assert_equal(inner_x, 10,
        'Nested SafeAreaContainer placement should preserve the Stage safe-area origin on the x axis')
    assert_equal(inner_y, 20,
        'Nested SafeAreaContainer placement should preserve the Stage safe-area origin on the y axis')
    assert_equal(leaf_x, 10,
        'Nested descendants should remain aligned with the same Stage safe-area origin on the x axis')
    assert_equal(leaf_y, 20,
        'Nested descendants should remain aligned with the same Stage safe-area origin on the y axis')

    stage:destroy()
end

local function run_safe_area_change_tests()
    local stage = UI.Stage.new({
        width = 300,
        height = 200,
        safeAreaInsets = { 20, 30, 40, 10 },
    })
    local safe = UI.SafeAreaContainer.new({
        width = 300,
        height = 200,
    })
    local child = UI.Container.new({
        width = '100%',
        height = '100%',
    })

    safe:addChild(child)
    stage.baseSceneLayer:addChild(safe)
    stage:update()
    stage:resize(300, 200, { 10, 5, 15, 25 })

    assert_true(safe.dirty:is_dirty('layout'),
        'Safe-area changes should dirty SafeAreaContainer for the next layout pass')

    stage:update()

    assert_rectangle_equal(safe:_get_effective_content_rect(),
        Rectangle.new(25, 10, 270, 175),
        'SafeAreaContainer should re-derive its content region when safe-area bounds change')
    assert_rectangle_equal(child:getLocalBounds(),
        Rectangle.new(0, 0, 270, 175),
        'Descendants should re-measure from the updated safe-area-derived region')

    local child_x, child_y = get_world_origin(child)

    assert_equal(child_x, 25,
        'Updated safe-area bounds should move descendants to the new content origin on the x axis')
    assert_equal(child_y, 10,
        'Updated safe-area bounds should move descendants to the new content origin on the y axis')

    stage:destroy()
end

local function run_safe_area_margin_composition_tests()
    local stage = UI.Stage.new({
        width = 300,
        height = 200,
        safeAreaInsets = { 20, 30, 40, 10 },
    })
    local safe = UI.SafeAreaContainer.new({
        width = 300,
        height = 200,
        padding = { 3, 4, 5, 6 },
    })
    local child = UI.Drawable.new({
        width = 20,
        height = 10,
        margin = { 5, 6, 7, 8 },
    })

    safe:addChild(child)
    stage.baseSceneLayer:addChild(safe)
    stage:update()

    local child_x, child_y = get_world_origin(child)

    assert_equal(child_x, 24,
        'SafeAreaContainer should apply child margin after safe-area and padding reduction on the x axis')
    assert_equal(child_y, 28,
        'SafeAreaContainer should apply child margin after safe-area and padding reduction on the y axis')

    stage:destroy()
end

local M = {}

function M.run()
    run_safe_area_content_region_tests()
    run_zero_inset_and_passthrough_tests()
    run_nested_safe_area_tests()
    run_safe_area_change_tests()
    run_safe_area_margin_composition_tests()
end

return M
