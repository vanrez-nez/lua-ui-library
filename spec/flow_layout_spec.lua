local UI = require('lib.ui')

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
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

local function make_box(width, height, opts)
    opts = opts or {}
    opts.width = width
    opts.height = height
    if opts.margin ~= nil or opts.marginTop ~= nil or opts.marginRight ~= nil or
        opts.marginBottom ~= nil or opts.marginLeft ~= nil then
        return UI.Drawable.new(opts)
    end
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
    local hidden = make_box(30, 10, {
        visible = false,
        marginLeft = 50,
        marginRight = 60,
    })
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

local function run_margin_wrap_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 240,
    })
    local flow = UI.Flow.new({
        width = 50,
        height = 60,
        gap = 0,
        wrap = true,
    })
    local first = make_box(20, 10, {
        marginRight = 10,
    })
    local second = make_box(20, 10, {
        marginLeft = 5,
    })

    flow:addChild(first)
    flow:addChild(second)
    stage.baseSceneLayer:addChild(flow)
    stage:update()

    local first_x, first_y = get_world_origin(first)
    local second_x, second_y = get_world_origin(second)

    assert_equal(first_x, 0,
        'Flow should keep the first child at the content origin when consuming child margin')
    assert_equal(first_y, 0,
        'Flow should keep the first row baseline at the content origin')
    assert_equal(second_x, 5,
        'Flow should place wrapped children after their leading horizontal margin')
    assert_equal(second_y, 10,
        'Flow wrapping should advance by the prior row outer footprint')

    stage:destroy()
end

local function run_direction_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 240,
    })
    local ltr_flow = UI.Flow.new({
        width = 90,
        height = 40,
    })
    local rtl_flow = UI.Flow.new({
        y = 60,
        width = 90,
        height = 40,
        direction = 'rtl',
    })
    local ltr_first = make_box(20, 10)
    local ltr_second = make_box(20, 10)
    local ltr_third = make_box(20, 10)
    local rtl_first = make_box(20, 10)
    local rtl_second = make_box(20, 10)
    local rtl_third = make_box(20, 10)

    ltr_flow:addChild(ltr_first)
    ltr_flow:addChild(ltr_second)
    ltr_flow:addChild(ltr_third)
    rtl_flow:addChild(rtl_first)
    rtl_flow:addChild(rtl_second)
    rtl_flow:addChild(rtl_third)

    stage.baseSceneLayer:addChild(ltr_flow)
    stage.baseSceneLayer:addChild(rtl_flow)
    stage:update()

    local ltr_first_x = get_world_origin(ltr_first)
    local ltr_second_x = get_world_origin(ltr_second)
    local ltr_third_x = get_world_origin(ltr_third)
    local rtl_first_x = get_world_origin(rtl_first)
    local rtl_second_x = get_world_origin(rtl_second)
    local rtl_third_x = get_world_origin(rtl_third)

    assert_equal(ltr_first_x, 0,
        'Flow should keep default direction aligned with ltr placement')
    assert_equal(ltr_second_x, 20,
        'Flow should keep default direction advancing left to right')
    assert_equal(ltr_third_x, 40,
        'Flow should keep default direction behavior unchanged')

    assert_equal(rtl_first_x, 70,
        'Flow rtl should place the first child against the right edge')
    assert_equal(rtl_second_x, 50,
        'Flow rtl should continue placement right-to-left in insertion order')
    assert_equal(rtl_third_x, 30,
        'Flow rtl should place later children farther left on the same row')

    stage:destroy()

    assert_error(function()
        UI.Flow.new({
            direction = 'invalid',
        })
    end, 'Flow.direction must be "ltr" or "rtl"',
        'Flow should reject invalid direction values deterministically')
end

local function run()
    run_last_row_alignment_tests()
    run_overflow_and_visibility_tests()
    run_oversized_child_tests()
    run_margin_wrap_tests()
    run_direction_tests()
end

return {
    run = run,
}
