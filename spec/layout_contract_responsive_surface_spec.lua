local Insets = require('lib.ui.core.insets')
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

local function assert_rectangle_equal(actual, expected, message)
    assert_true(actual:equals(expected, 1e-9),
        message .. ': expected ' .. tostring(expected) ..
        ', got ' .. tostring(actual))
end

local function run_public_surface_tests()
    local Stack = UI.Stack
    local Row = UI.Row
    local Column = UI.Column
    local Flow = UI.Flow
    local SafeAreaContainer = UI.SafeAreaContainer

    local stack = Stack.new({
        gap = 8,
        padding = { 4, 6 },
        wrap = true,
        justify = 'center',
        align = 'stretch',
        width = 'content',
        height = 'content',
    })
    local row = Row.new({
        direction = 'rtl',
        gap = 12,
    })
    local column = Column.new({
        responsive = {
            compact = {
                maxWidth = 320,
                props = {
                    width = '100%',
                },
            },
        },
    })
    local flow = Flow.new({
        wrap = true,
        gap = 10,
    })
    local safe_area_container = SafeAreaContainer.new({
        applyTop = false,
        applyBottom = true,
        applyLeft = false,
        applyRight = true,
        padding = 5,
    })

    assert_equal(stack.gap, 8, 'Stack should expose the common gap prop')
    assert_true(stack.padding == Insets.new(4, 6, 4, 6),
        'Stack should normalize the common padding prop')
    assert_equal(stack.wrap, true, 'Stack should expose the common wrap prop')
    assert_equal(stack.justify, 'center',
        'Stack should expose the common justify prop')
    assert_equal(stack.align, 'stretch',
        'Stack should expose the common align prop')

    assert_equal(row.direction, 'rtl', 'Row should expose direction')
    assert_equal(column.responsive ~= nil, true,
        'Column should expose the common responsive prop')
    assert_equal(flow.gap, 10, 'Flow should expose the common gap prop')

    assert_equal(safe_area_container.applyTop, false,
        'SafeAreaContainer should expose applyTop')
    assert_equal(safe_area_container.applyBottom, true,
        'SafeAreaContainer should expose applyBottom')
    assert_equal(safe_area_container.applyLeft, false,
        'SafeAreaContainer should expose applyLeft')
    assert_equal(safe_area_container.applyRight, true,
        'SafeAreaContainer should expose applyRight')

    assert_error(function()
        Flow.new({ gapX = 4 })
    end, 'gapX',
        'Flow should reject unsupported gapX props')

    assert_error(function()
        Flow.new({ gapY = 4 })
    end, 'gapY',
        'Flow should reject unsupported gapY props')

    assert_error(function()
        Column.new({ direction = 'rtl' })
    end, 'direction',
        'Column should reject Row-only direction')

    assert_error(function()
        Stack.new({ applyTop = false })
    end, 'applyTop',
        'Stack should reject SafeAreaContainer-only props')
end

local function run_dual_source_invalidity_tests()
    local Row = UI.Row

    assert_error(function()
        Row.new({
            breakpoints = {
                compact = {
                    maxWidth = 400,
                    props = {
                        width = '100%',
                    },
                },
            },
            responsive = {
                compact = {
                    maxWidth = 400,
                    props = {
                        width = '50%',
                    },
                },
            },
        })
    end, 'responsive and breakpoints',
        'Supplying responsive and breakpoints together at construction should fail')

    local node = Row.new({})

    node.responsive = {
        compact = {
            maxWidth = 400,
            props = {
                width = '100%',
            },
        },
    }

    assert_error(function()
        node.breakpoints = {
            compact = {
                maxWidth = 400,
                props = {
                    width = '50%',
                },
            },
        }
    end, 'responsive and breakpoints',
        'Supplying breakpoints after responsive should fail deterministically')
end

local function run_pre_measure_resolution_tests()
    local Stage = UI.Stage
    local Container = UI.Container
    local Row = UI.Row
    local Column = UI.Column

    local stage = Stage.new({
        width = 400,
        height = 240,
        safeAreaInsets = { 20, 30, 40, 10 },
    })
    local parent = Container.new({
        width = 300,
        height = 160,
    })
    local breakpoints_child = Container.new({
        width = 40,
        height = 20,
        breakpoints = {
            compact = {
                maxWidth = 420,
                orientation = 'landscape',
                safeArea = {
                    minWidth = 300,
                },
                props = {
                    width = '50%',
                    x = 25,
                },
            },
        },
    })
    local responsive_child = Row.new({
        width = 10,
        height = 20,
        responsive = {
            parent_driven = {
                parent = {
                    minWidth = 280,
                    minHeight = 150,
                },
                props = {
                    width = '25%',
                    x = 15,
                },
            },
        },
    })

    stage.baseSceneLayer:addChild(parent)
    parent:addChild(breakpoints_child)
    parent:addChild(responsive_child)

    stage:update()

    assert_rectangle_equal(parent:getLocalBounds(),
        Rectangle.new(0, 0, 300, 160),
        'Parent container should resolve before responsive children measure')
    assert_rectangle_equal(breakpoints_child:getLocalBounds(),
        Rectangle.new(0, 0, 150, 20),
        'Breakpoint-driven overrides should affect measurement on the first update')
    assert_equal(breakpoints_child:localToWorld(0, 0), 25,
        'Breakpoint-driven overrides should affect placement inputs on the first update')
    assert_rectangle_equal(responsive_child:getLocalBounds(),
        Rectangle.new(0, 0, 75, 20),
        'Responsive overrides should resolve against parent dimensions before measurement')

    stage:resize(240, 400, { 10, 10, 10, 10 })
    stage:update()

    assert_rectangle_equal(breakpoints_child:getLocalBounds(),
        Rectangle.new(0, 0, 40, 20),
        'Orientation and safe-area responsive inputs should be re-evaluated on resize')

    stage:destroy()

    local second_stage = Stage.new({
        width = 320,
        height = 200,
    })
    local callback_parent = Container.new({
        width = 240,
        height = 100,
    })
    local callback_child = Column.new({
        width = 20,
        height = 30,
        responsive = function(context)
            if context.parent.width >= 200 then
                return {
                    width = '50%',
                    x = 11,
                }, 'wide-parent'
            end

            return nil
        end,
    })

    second_stage.baseSceneLayer:addChild(callback_parent)
    callback_parent:addChild(callback_child)
    second_stage:update()

    assert_rectangle_equal(callback_child:getLocalBounds(),
        Rectangle.new(0, 0, 120, 30),
        'Function responsive rules should also resolve before measurement')

    second_stage:destroy()
end

local function run()
    run_public_surface_tests()
    run_dual_source_invalidity_tests()
    run_pre_measure_resolution_tests()
end

return {
    run = run,
}
