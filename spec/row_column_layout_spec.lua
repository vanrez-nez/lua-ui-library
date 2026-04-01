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

local function run_row_layout_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 180,
    })
    local row = UI.Row.new({
        width = 200,
        height = 60,
        justify = 'space-between',
    })
    local single = make_box(20, 10)
    local rtl_row = UI.Row.new({
        width = 200,
        height = 40,
        direction = 'rtl',
        gap = 5,
    })
    local rtl_first = make_box(30, 10)
    local rtl_second = make_box(20, 10)

    row:addChild(single)
    rtl_row:addChild(rtl_first)
    rtl_row:addChild(rtl_second)

    stage.baseSceneLayer:addChild(row)
    stage.baseSceneLayer:addChild(rtl_row)
    stage:update()

    local row_x, row_y = get_world_origin(single)
    local rtl_first_x = get_world_origin(rtl_first)
    local rtl_second_x = get_world_origin(rtl_second)

    assert_equal(row_x, 0,
        'Row space-between should place a single child at the start position')
    assert_equal(row_y, 0,
        'Row should place a single child on the first row baseline')
    assert_equal(rtl_first_x, 170,
        'Row rtl should place the first child against the right edge')
    assert_equal(rtl_second_x, 145,
        'Row rtl should continue placement right-to-left in insertion order')

    stage:destroy()
end

local function run_wrap_and_stretch_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 240,
    })
    local row = UI.Row.new({
        width = 130,
        height = 80,
        gap = 10,
        wrap = true,
    })
    local first = make_box(40, 10)
    local second = make_box(40, 20)
    local third = make_box(40, 30)
    local stretch_row = UI.Row.new({
        y = 100,
        width = 120,
        height = 50,
        align = 'stretch',
    })
    local stretched = make_box(20, 10)

    row:addChild(first)
    row:addChild(second)
    row:addChild(third)
    stretch_row:addChild(stretched)

    stage.baseSceneLayer:addChild(row)
    stage.baseSceneLayer:addChild(stretch_row)
    stage:update()

    local first_x, first_y = get_world_origin(first)
    local second_x, second_y = get_world_origin(second)
    local third_x, third_y = get_world_origin(third)

    assert_equal(first_x, 0,
        'Wrapped Row should place the first child at the content origin')
    assert_equal(first_y, 0,
        'Wrapped Row should place the first child on the first row')
    assert_equal(second_x, 50,
        'Wrapped Row should apply gap spacing within a row')
    assert_equal(second_y, 0,
        'Wrapped Row should keep fitting children on the same row')
    assert_equal(third_x, 0,
        'Wrapped Row should reset the main-axis offset after wrapping')
    assert_equal(third_y, 30,
        'Wrapped Row should advance by prior row height plus gap when wrapping')
    assert_equal(stretched:getWorldBounds().height, 50,
        'Row align stretch should resolve the child cross-axis size to the row height')

    stage:destroy()
end

local function run_nested_layout_measurement_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 180,
    })
    local outer = UI.Row.new({
        width = 200,
        height = 100,
        gap = 5,
    })
    local inner = UI.Column.new({
        width = 'content',
        height = 'content',
        gap = 3,
    })
    local tail = make_box(10, 10)

    inner:addChild(make_box(30, 10))
    inner:addChild(make_box(20, 20))
    outer:addChild(inner)
    outer:addChild(tail)
    stage.baseSceneLayer:addChild(outer)
    stage:update()

    local tail_x, tail_y = get_world_origin(tail)

    assert_equal(inner:getLocalBounds().width, 30,
        'Nested Column should measure to the widest child before outer Row placement')
    assert_equal(inner:getLocalBounds().height, 33,
        'Nested Column should measure content height including gap before outer placement')
    assert_equal(tail_x, 35,
        'Outer Row should place later children after the nested layout primitive is measured')
    assert_equal(tail_y, 0,
        'Outer Row should keep later children on the same row when space remains')

    stage:destroy()
end

local function run_column_layout_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 220,
    })
    local column = UI.Column.new({
        width = 100,
        height = 100,
        gap = 10,
        wrap = true,
    })
    local first = make_box(20, 40)
    local second = make_box(30, 40)
    local third = make_box(25, 40)

    column:addChild(first)
    column:addChild(second)
    column:addChild(third)
    stage.baseSceneLayer:addChild(column)
    stage:update()

    local first_x, first_y = get_world_origin(first)
    local second_x, second_y = get_world_origin(second)
    local third_x, third_y = get_world_origin(third)

    assert_equal(first_x, 0,
        'Column should place the first child at the content origin')
    assert_equal(first_y, 0,
        'Column should place the first child at the top of the first column')
    assert_equal(second_x, 0,
        'Column should keep fitting children in the same column before wrap')
    assert_equal(second_y, 50,
        'Column should apply gap spacing along the main axis')
    assert_equal(third_x, 40,
        'Column should advance to the next wrapped column using prior column width plus gap')
    assert_equal(third_y, 0,
        'Column should reset the main-axis offset after wrapping')

    stage:destroy()
end

local function run_nested_world_offset_read_tests()
    local stage = UI.Stage.new({
        width = 1024,
        height = 768,
    })
    local root = UI.Column.new({
        width = 'fill',
        height = 'fill',
        padding = { 24, 24, 24, 24 },
        align = 'center',
        justify = 'center',
    })
    local content = UI.Column.new({
        width = 820,
        height = 360,
        gap = 12,
        padding = { 20, 20, 20, 20 },
        align = 'stretch',
        justify = 'start',
    })
    local title = make_box(200, 30)
    local row = UI.Row.new({
        width = 'fill',
        height = 'content',
        gap = 24,
        align = 'start',
        justify = 'center',
    })
    local left = UI.Column.new({
        width = 360,
        height = 'content',
        gap = 8,
        align = 'center',
        justify = 'start',
    })
    local right = UI.Column.new({
        width = 360,
        height = 'content',
        gap = 8,
        align = 'center',
        justify = 'start',
    })
    local nested = make_box(320, 42)

    root:addChild(content)
    content:addChild(title)
    content:addChild(row)
    row:addChild(left)
    row:addChild(right)
    left:addChild(nested)
    left:addChild(make_box(320, 42))
    right:addChild(make_box(320, 42))
    right:addChild(make_box(320, 42))
    stage.baseSceneLayer:addChild(root)
    stage:update()

    local nested_x, nested_y = get_world_origin(nested)

    assert_equal(nested_x, 160,
        'Nested child world x should include all ancestor layout offsets during read synchronization')
    assert_equal(nested_y, 266,
        'Nested child world y should include all ancestor layout offsets during read synchronization')

    stage:destroy()
end

local function run_circular_dependency_tests()
    local stage = UI.Stage.new({
        width = 200,
        height = 120,
    })
    local ok, err = pcall(function()
        local row = UI.Row.new({
            width = 'content',
            height = 20,
        })

        row:addChild(make_box('fill', 10))
        stage.baseSceneLayer:addChild(row)
        stage:update()
    end)

    stage:destroy()

    if ok then
        error(
            'Row should fail deterministically on a content-width to fill-width cycle: expected an error',
            2
        )
    end

    if not tostring(err):find('circular measurement dependency', 1, true) then
        error(
            'Row should fail deterministically on a content-width to fill-width cycle: expected error containing "circular measurement dependency", got "' ..
                tostring(err) .. '"',
            2
        )
    end

    stage = UI.Stage.new({
        width = 200,
        height = 120,
    })
    ok, err = pcall(function()
        local column = UI.Column.new({
            width = 20,
            height = 'content',
        })

        column:addChild(make_box(10, 'fill'))
        stage.baseSceneLayer:addChild(column)
        stage:update()
    end)

    stage:destroy()

    if ok then
        error(
            'Column should fail deterministically on a content-height to fill-height cycle: expected an error',
            2
        )
    end

    if not tostring(err):find('circular measurement dependency', 1, true) then
        error(
            'Column should fail deterministically on a content-height to fill-height cycle: expected error containing "circular measurement dependency", got "' ..
                tostring(err) .. '"',
            2
        )
    end
end

local function run()
    run_row_layout_tests()
    run_wrap_and_stretch_tests()
    run_nested_layout_measurement_tests()
    run_column_layout_tests()
    run_nested_world_offset_read_tests()
    run_circular_dependency_tests()
end

return {
    run = run,
}
