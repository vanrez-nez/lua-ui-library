local UI = require('lib.ui')

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
    end
end

local function make_box(width, height, opts)
    opts = opts or {}
    opts.width = width
    opts.height = height
    return UI.Container.new(opts)
end

local function get_world_origin(node)
    local bounds = node:getWorldBounds()
    return bounds.x, bounds.y
end

local function run_last_row_alignment_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 240,
    })
    local centered = UI.Flow.new({
        width = 100,
        height = 100,
        gap = 10,
        wrap = true,
        justify = 'space-between',
        align = 'center',
    })
    local no_stretch = UI.Flow.new({
        width = 100,
        height = 80,
        gap = 10,
        wrap = true,
        justify = 'space-between',
        align = 'start',
    })
    local first = make_box(30, 10)
    local second = make_box(30, 10)
    local third = make_box(30, 10)
    local full_first = make_box(45, 10)
    local full_second = make_box(45, 10)
    local last_first = make_box(20, 10)
    local last_second = make_box(20, 10)

    centered:addChild(first)
    centered:addChild(second)
    centered:addChild(third)

    no_stretch:addChild(full_first)
    no_stretch:addChild(full_second)
    no_stretch:addChild(last_first)
    no_stretch:addChild(last_second)

    stage.baseSceneLayer:addChild(centered)
    stage.baseSceneLayer:addChild(no_stretch)
    stage:update()

    local first_x = get_world_origin(first)
    local second_x = get_world_origin(second)
    local third_x, third_y = get_world_origin(third)
    local last_first_x, last_first_y = get_world_origin(last_first)
    local last_second_x, last_second_y = get_world_origin(last_second)

    assert_equal(first_x, 0,
        'Flow should place the first wrapped-row child at the content origin')
    assert_equal(second_x, 70,
        'Flow should still apply justify spacing on non-final wrapped rows')
    assert_equal(third_x, 35,
        'Flow should align the final wrapped row using Flow.align')
    assert_equal(third_y, 20,
        'Flow should advance to the next row using prior row height plus gap')

    assert_equal(last_first_x, 0,
        'Flow should place the final wrapped row at the aligned origin when align is start')
    assert_equal(last_first_y, 20,
        'Flow should stack wrapped rows from top to bottom in reading order')
    assert_equal(last_second_x, 30,
        'Flow should keep the declared gap on the last wrapped row instead of stretching it')
    assert_equal(last_second_y, 20,
        'Flow should keep later children on the same final wrapped row when space remains')

    stage:destroy()
end

local function run_overflow_and_visibility_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 240,
    })
    local overflow_flow = UI.Flow.new({
        width = 100,
        height = 60,
        gap = 10,
        wrap = false,
    })
    local invisible_flow = UI.Flow.new({
        width = 80,
        height = 40,
        gap = 5,
        wrap = true,
    })
    local overflow_first = make_box(60, 10)
    local overflow_second = make_box(60, 10)
    local visible_first = make_box(20, 10)
    local hidden = make_box(30, 10, { visible = false })
    local visible_second = make_box(20, 10)

    overflow_flow:addChild(overflow_first)
    overflow_flow:addChild(overflow_second)

    invisible_flow:addChild(visible_first)
    invisible_flow:addChild(hidden)
    invisible_flow:addChild(visible_second)

    stage.baseSceneLayer:addChild(overflow_flow)
    stage.baseSceneLayer:addChild(invisible_flow)
    stage:update()

    local overflow_first_x, overflow_first_y = get_world_origin(overflow_first)
    local overflow_second_x, overflow_second_y = get_world_origin(overflow_second)
    local visible_first_x, visible_first_y = get_world_origin(visible_first)
    local visible_second_x, visible_second_y = get_world_origin(visible_second)

    assert_equal(overflow_first_x, 0,
        'Flow should place the first child at the content origin when wrapping is disabled')
    assert_equal(overflow_first_y, 0,
        'Flow should keep the first non-wrapping child on the first row')
    assert_equal(overflow_second_x, 70,
        'Flow should allow overflow on the same row when wrap is false')
    assert_equal(overflow_second_y, 0,
        'Flow should not create a new row when wrap is false')

    assert_equal(visible_first_x, 0,
        'Flow should place the first visible child at the content origin')
    assert_equal(visible_first_y, 0,
        'Flow should keep the first visible child on the first row baseline')
    assert_equal(visible_second_x, 25,
        'Invisible Flow children must not consume row width or gap space')
    assert_equal(visible_second_y, 0,
        'Invisible Flow children must not force later visible children onto a new row')

    stage:destroy()
end

local function run_oversized_child_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 240,
    })
    local flow = UI.Flow.new({
        width = 100,
        height = 120,
        gap = 5,
        wrap = true,
    })
    local first = make_box(40, 10)
    local oversized = make_box(120, 20)
    local third = make_box(30, 10)

    flow:addChild(first)
    flow:addChild(oversized)
    flow:addChild(third)
    stage.baseSceneLayer:addChild(flow)
    stage:update()

    local first_x, first_y = get_world_origin(first)
    local oversized_x, oversized_y = get_world_origin(oversized)
    local third_x, third_y = get_world_origin(third)

    assert_equal(first_x, 0,
        'Flow should place the first child at the first-row origin')
    assert_equal(first_y, 0,
        'Flow should keep the first child on the first row')
    assert_equal(oversized_x, 0,
        'A child wider than the row should occupy its own wrapped row')
    assert_equal(oversized_y, 15,
        'Flow should advance to the oversized child row by prior row height plus gap')
    assert_equal(third_x, 0,
        'Flow should restart the row origin after an oversized child row')
    assert_equal(third_y, 40,
        'Flow should place following children after the oversized child row height plus gap')

    stage:destroy()
end

local function run()
    run_last_row_alignment_tests()
    run_overflow_and_visibility_tests()
    run_oversized_child_tests()
end

return {
    run = run,
}
