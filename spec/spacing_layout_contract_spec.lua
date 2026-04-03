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

local M = {}

function M.run()
    run_spacing_validation_tests()
    run_effective_layout_read_tests()
    run_non_layout_margin_inert_tests()
end

return M
