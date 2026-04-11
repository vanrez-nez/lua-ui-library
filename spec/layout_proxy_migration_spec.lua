local Rectangle = require('lib.ui.core.rectangle')
local UI = require('lib.ui')
local Direction = require('lib.ui.layout.direction')
local Responsive = require('lib.ui.layout.responsive')

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

local function make_box(width, height)
    return UI.Container.new({
        width = width,
        height = height,
    })
end

local function world_origin(node)
    local bounds = node:getWorldBounds()
    return bounds.x, bounds.y
end

local function run_stack_fixture_tests()
    local stage = UI.Stage.new({ width = 200, height = 120 })
    local stack = UI.Stack.new({
        width = 120,
        height = 90,
        padding = { 5, 10, 15, 20 },
    })
    local child = make_box(30, 20)

    stack:addChild(child)
    stage.baseSceneLayer:addChild(stack)
    stage:update()

    local x, y = world_origin(child)

    assert_equal(x, 20,
        'Stack should preserve content-box child x placement after migration')
    assert_equal(y, 5,
        'Stack should preserve content-box child y placement after migration')

    stage:destroy()
end

local function run_row_column_fixture_tests()
    local stage = UI.Stage.new({ width = 240, height = 180 })
    local row = UI.Row.new({
        width = 100,
        height = 40,
        gap = 10,
    })
    local row_first = make_box(20, 10)
    local row_second = make_box(30, 10)
    local column = UI.Column.new({
        y = 80,
        width = 80,
        height = 80,
        gap = 5,
    })
    local column_first = make_box(20, 10)
    local column_second = make_box(20, 30)

    row:addChild(row_first)
    row:addChild(row_second)
    column:addChild(column_first)
    column:addChild(column_second)
    stage.baseSceneLayer:addChild(row)
    stage.baseSceneLayer:addChild(column)
    stage:update()

    local row_first_x = world_origin(row_first)
    local row_second_x = world_origin(row_second)
    local _, column_first_y = world_origin(column_first)
    local _, column_second_y = world_origin(column_second)

    assert_equal(row_first_x, 0,
        'Row should keep first child at the main-axis origin')
    assert_equal(row_second_x, 30,
        'Row should preserve gap-based main-axis placement')
    assert_equal(column_first_y, 80,
        'Column should keep first child at the column origin')
    assert_equal(column_second_y, 95,
        'Column should preserve gap-based vertical placement')

    stage:destroy()
end

local function run_flow_fixture_tests()
    local stage = UI.Stage.new({ width = 200, height = 160 })
    local flow = UI.Flow.new({
        width = 50,
        height = 100,
        gap = 10,
        wrap = true,
    })
    local first = make_box(30, 10)
    local second = make_box(30, 10)

    flow:addChild(first)
    flow:addChild(second)
    stage.baseSceneLayer:addChild(flow)
    stage:update()

    local first_x, first_y = world_origin(first)
    local second_x, second_y = world_origin(second)

    assert_equal(first_x, 0,
        'Flow should keep the first wrapped child at x origin')
    assert_equal(first_y, 0,
        'Flow should keep the first wrapped child at y origin')
    assert_equal(second_x, 0,
        'Flow should wrap the second child back to x origin')
    assert_equal(second_y, 20,
        'Flow should advance by row height plus gap after wrapping')

    stage:destroy()
end

local function run_safe_area_apply_flag_tests()
    local stage = UI.Stage.new({
        width = 300,
        height = 200,
        safeAreaInsets = { 20, 30, 40, 10 },
    })
    local safe = UI.SafeAreaContainer.new({
        width = 300,
        height = 200,
    })

    stage.baseSceneLayer:addChild(safe)
    stage:update()

    assert_true(not safe.dirty:is_dirty('layout'),
        'SafeAreaContainer layout dirty should be clear after update')

    safe:set_apply_flag('top', false)

    assert_true(safe.dirty:is_dirty('layout'),
        'set_apply_flag should mark layout dirty through the schema set callback')

    stage:update()

    assert_rectangle_equal(safe:_get_effective_content_rect(),
        Rectangle.new(10, 0, 260, 160),
        'SafeAreaContainer should relayout with the updated apply flag')

    stage:destroy()
end

local function run_rule_factory_tests()
    local direction_rule = Direction.schema_rule('Row')
    local responsive_rule = Responsive.schema_rule('Layout')
    local node = UI.Container.new()

    assert_true(direction_rule._is_rule == true,
        'Direction.schema_rule should return a Rule table')
    assert_true(responsive_rule._is_rule == true,
        'Responsive.schema_rule should return a Rule table')

    node.schema:define({
        direction = direction_rule,
        responsive = responsive_rule,
    })

    node.direction = 'rtl'
    node.responsive = {
        {
            when = { minWidth = 1 },
            props = { width = 20 },
        },
    }

    assert_equal(node.direction, 'rtl',
        'Schema should accept the Direction rule factory output')
    assert_true(type(node.responsive) == 'table',
        'Schema should accept the Responsive rule factory output')
end

local function run()
    run_stack_fixture_tests()
    run_row_column_fixture_tests()
    run_flow_fixture_tests()
    run_safe_area_apply_flag_tests()
    run_rule_factory_tests()
end

return {
    run = run,
}
