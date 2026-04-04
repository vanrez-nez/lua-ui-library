local Insets = require('lib.ui.core.insets')
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

local function run_spacing_validation_tests()
    assert_error(function()
        UI.Stack.new({ padding = -1 })
    end, 'padding',
        'Layout-family padding should reject negative aggregate values')

    assert_error(function()
        UI.Stack.new({ paddingLeft = -1 })
    end, 'paddingLeft',
        'Layout-family flat padding overrides should reject negative values')

    assert_error(function()
        UI.Row.new({ gap = -1 })
    end, 'gap',
        'Layout-family gap should reject negative values')

    assert_error(function()
        UI.Row.new({ gap = 0 / 0 })
    end, 'finite',
        'Layout-family gap should reject NaN')

    assert_error(function()
        UI.Drawable.new({ paddingBottom = -1 })
    end, 'paddingBottom',
        'Drawable flat padding overrides should reject negative values')

    assert_error(function()
        UI.Drawable.new({ marginLeft = 0 / 0 })
    end, 'finite',
        'Drawable flat margin overrides should reject non-finite values')

    local drawable = UI.Drawable.new({
        marginLeft = -12,
    })

    assert_equal(drawable.marginLeft, -12,
        'Drawable flat margin overrides should preserve signed values')
end

local function run_effective_layout_read_tests()
    local stack = UI.Stack.new({
        padding = 10,
        paddingLeft = 3,
    })

    assert_true(stack.padding == Insets.new(10, 10, 10, 3),
        'Layout-family padding reads should expose merged effective insets')
    assert_equal(stack.paddingLeft, 3,
        'Layout-family flat padding reads should respect member overrides')
    assert_equal(stack.paddingTop, 10,
        'Layout-family flat padding reads should inherit aggregate values when not overridden')
end

local function run_common_layout_default_and_dual_supply_tests()
    local row = UI.Row.new({})
    local responsive_only = UI.Row.new({
        responsive = {
            compact = {
                maxWidth = 320,
                props = {
                    width = '100%',
                },
            },
        },
    })
    local breakpoints_only = UI.Row.new({
        breakpoints = {
            compact = {
                maxWidth = 320,
                props = {
                    width = '100%',
                },
            },
        },
    })

    assert_equal(row.gap, 0,
        'Layout-family gap should default to zero')
    assert_equal(row.wrap, false,
        'Layout-family wrap should default to false')
    assert_equal(row.justify, 'start',
        'Layout-family justify should default to start')
    assert_equal(row.align, 'start',
        'Layout-family align should default to start')
    assert_equal(row.clipChildren, false,
        'Layout-family clipChildren should default to false')
    assert_equal(row.responsive, nil,
        'Layout-family responsive should default to nil')

    assert_true(responsive_only.responsive ~= nil,
        'Layout-family nodes should still accept responsive without breakpoints')
    assert_true(breakpoints_only.breakpoints ~= nil,
        'Layout-family nodes should still accept breakpoints without responsive')

    assert_error(function()
        UI.Row.new({
            responsive = {},
            breakpoints = {},
        })
    end, 'responsive and breakpoints',
        'Layout-family nodes should fail deterministically when responsive and breakpoints are both supplied at construction')

    local node = UI.Row.new({})

    node.breakpoints = {
        compact = {
            maxWidth = 320,
            props = {
                width = '100%',
            },
        },
    }

    assert_error(function()
        node.responsive = {}
    end, 'responsive and breakpoints',
        'Layout-family nodes should fail deterministically when responsive is written after breakpoints')
end

local function run_non_layout_margin_inert_tests()
    local stage = UI.Stage.new({
        width = 200,
        height = 160,
    })
    local plain_container = UI.Container.new({
        width = 80,
        height = 60,
    })
    local container_child = UI.Drawable.new({
        x = 5,
        y = 7,
        width = 20,
        height = 10,
        marginLeft = 30,
        marginTop = 40,
    })
    local plain_drawable = UI.Drawable.new({
        y = 80,
        width = 80,
        height = 40,
        padding = 10,
    })
    local drawable_child = UI.Drawable.new({
        x = 6,
        y = 8,
        width = 15,
        height = 12,
        marginLeft = 25,
        marginTop = 35,
    })

    plain_container:addChild(container_child)
    plain_drawable:addChild(drawable_child)
    stage.baseSceneLayer:addChild(plain_container)
    stage.baseSceneLayer:addChild(plain_drawable)
    stage:update()

    assert_equal(container_child:getWorldBounds().x, 5,
        'Plain Container should leave child margin inert for placement')
    assert_equal(container_child:getWorldBounds().y, 7,
        'Plain Container should not offset children because of child margin')
    assert_equal(drawable_child:getWorldBounds().x, 6,
        'Plain Drawable should leave child margin inert for placement')
    assert_equal(drawable_child:getWorldBounds().y, 88,
        'Plain Drawable should not offset children because of child margin')

    stage:destroy()
end

local function assert_invalid_layout_update(layout, child, needle, message)
    local stage = UI.Stage.new({
        width = 240,
        height = 180,
    })

    layout:addChild(child)
    stage.baseSceneLayer:addChild(layout)

    assert_error(function()
        stage:update()
    end, needle, message)

    assert_equal(rawget(child, '_layout_offset_x'), 0,
        message .. ': child x offset should remain unchanged on failure')
    assert_equal(rawget(child, '_layout_offset_y'), 0,
        message .. ': child y offset should remain unchanged on failure')

    stage:destroy()
end

local function run_content_fill_layout_family_tests()
    assert_invalid_layout_update(
        UI.Row.new({
            width = 'content',
            height = 20,
        }),
        UI.Container.new({
            width = 'fill',
            height = 10,
        }),
        'width = "content" and a visible child has width = "fill"',
        'Row should reject main-axis fill children when width is content-sized'
    )

    local row_cross_fill_stage = UI.Stage.new({
        width = 240,
        height = 180,
    })
    local row_cross_fill = UI.Row.new({
        width = 'content',
        height = 40,
    })
    local row_cross_child = UI.Container.new({
        width = 30,
        height = 'fill',
    })

    row_cross_fill:addChild(row_cross_child)
    row_cross_fill_stage.baseSceneLayer:addChild(row_cross_fill)
    row_cross_fill_stage:update()

    assert_equal(row_cross_fill:getLocalBounds().width, 30,
        'Row should still allow cross-axis fill when the main axis is content-sized')
    assert_equal(row_cross_child:getWorldBounds().height, 40,
        'Row should still resolve cross-axis fill against the available row height')

    row_cross_fill_stage:destroy()

    local row_fill_stage = UI.Stage.new({
        width = 240,
        height = 180,
    })
    local fixed_row = UI.Row.new({
        width = 120,
        height = 20,
    })
    local fixed_row_child = UI.Container.new({
        width = 'fill',
        height = 10,
    })

    fixed_row:addChild(fixed_row_child)
    row_fill_stage.baseSceneLayer:addChild(fixed_row)
    row_fill_stage:update()

    assert_equal(fixed_row_child:getWorldBounds().width, 120,
        'Row should still allow main-axis fill when width is not content-sized')

    row_fill_stage:destroy()

    assert_invalid_layout_update(
        UI.Column.new({
            width = 20,
            height = 'content',
        }),
        UI.Container.new({
            width = 10,
            height = 'fill',
        }),
        'height = "content" and a visible child has height = "fill"',
        'Column should reject main-axis fill children when height is content-sized'
    )

    local column_fill_stage = UI.Stage.new({
        width = 240,
        height = 180,
    })
    local fixed_column = UI.Column.new({
        width = 30,
        height = 120,
    })
    local fixed_column_child = UI.Container.new({
        width = 10,
        height = 'fill',
    })

    fixed_column:addChild(fixed_column_child)
    column_fill_stage.baseSceneLayer:addChild(fixed_column)
    column_fill_stage:update()

    assert_equal(fixed_column_child:getWorldBounds().height, 120,
        'Column should still allow main-axis fill when height is not content-sized')

    column_fill_stage:destroy()

    assert_invalid_layout_update(
        UI.Stack.new({
            width = 'content',
            height = 100,
        }),
        UI.Drawable.new({
            width = 'fill',
            height = 10,
        }),
        'width = "content" and a visible child has width = "fill"',
        'Stack should reject width fill children when width is content-sized'
    )

    assert_invalid_layout_update(
        UI.Stack.new({
            width = 40,
            height = 'content',
        }),
        UI.Drawable.new({
            width = 10,
            height = 'fill',
        }),
        'height = "content" and a visible child has height = "fill"',
        'Stack should reject height fill children when height is content-sized'
    )

    local stack_cross_stage = UI.Stage.new({
        width = 240,
        height = 180,
    })
    local stack_cross = UI.Stack.new({
        width = 'content',
        height = 100,
    })
    local stack_cross_child = UI.Drawable.new({
        width = 30,
        height = 'fill',
    })

    stack_cross:addChild(stack_cross_child)
    stack_cross_stage.baseSceneLayer:addChild(stack_cross)
    stack_cross_stage:update()

    assert_equal(stack_cross:getLocalBounds().width, 30,
        'Stack should still allow non-content-axis fill when width alone is content-sized')
    assert_equal(stack_cross_child:getWorldBounds().height, 100,
        'Stack should continue resolving fill on fixed axes')

    stack_cross_stage:destroy()

    assert_invalid_layout_update(
        UI.Flow.new({
            width = 'content',
            height = 40,
        }),
        UI.Container.new({
            width = 'fill',
            height = 10,
        }),
        'width = "content" and a visible child has width = "fill"',
        'Flow should reject width fill children when width is content-sized'
    )
end

local M = {}

function M.run()
    run_spacing_validation_tests()
    run_effective_layout_read_tests()
    run_common_layout_default_and_dual_supply_tests()
    run_non_layout_margin_inert_tests()
    run_content_fill_layout_family_tests()
end

return M
