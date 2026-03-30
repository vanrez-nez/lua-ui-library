local Drawable = require('lib.ui.core.drawable')
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
    local skin = { id = 'panel' }
    local shader = { id = 'fx' }
    local mask = { id = 'mask' }
    local node = Drawable.new({
        tag = 'surface',
        width = 120,
        height = 80,
        padding = { 4, 6, 8, 10 },
        margin = { 12, 14 },
        alignX = 'center',
        alignY = 'stretch',
        skin = skin,
        shader = shader,
        opacity = 0.35,
        blendMode = 'alpha',
        mask = mask,
    })

    assert_equal(UI.Drawable, Drawable,
        'lib.ui should expose the Drawable module')
    assert_true(Drawable.is_drawable(node),
        'Drawable.is_drawable should recognize drawable instances')
    assert_true(node.padding == Insets.new(4, 6, 8, 10),
        'Drawable should normalize padding into canonical insets')
    assert_true(node.margin == Insets.new(12, 14, 12, 14),
        'Drawable should normalize margin into canonical insets')
    assert_equal(node.alignX, 'center', 'Drawable should preserve alignX')
    assert_equal(node.alignY, 'stretch', 'Drawable should preserve alignY')
    assert_equal(node.skin, skin, 'Drawable should preserve skin by reference')
    assert_equal(node.shader, shader, 'Drawable should preserve shader by reference')
    assert_equal(node.opacity, 0.35, 'Drawable should preserve opacity')
    assert_equal(node.blendMode, 'alpha', 'Drawable should preserve blendMode')
    assert_equal(node.mask, mask, 'Drawable should preserve mask by reference')
    assert_equal(node.focused, nil,
        'Drawable should not expose a persistent public focused property')
end

local function run_content_box_tests()
    local node = Drawable.new({
        width = 100,
        height = 60,
        padding = {
            top = 5,
            right = 7,
            bottom = 11,
            left = 13,
        },
        margin = 20,
    })

    local content_rect = node:getContentRect()

    assert_rectangle_equal(node:getLocalBounds(), Rectangle.new(0, 0, 100, 60),
        'Drawable margin should not change local bounds')
    assert_rectangle_equal(content_rect, Rectangle.new(13, 5, 80, 44),
        'Drawable getContentRect should inset local bounds by padding')

    node.padding = { 30, 40, 50, 60 }

    assert_rectangle_equal(node:getContentRect(), Rectangle.new(60, 30, 0, 0),
        'Drawable content boxes should clamp to zero area when padding collapses them')
    assert_rectangle_equal(node:getLocalBounds(), Rectangle.new(0, 0, 100, 60),
        'Drawable padding changes should not mutate the node bounds')
end

local function run_alignment_resolution_tests()
    local centered = Drawable.new({
        width = 100,
        height = 80,
        padding = { 10, 15, 20, 25 },
        alignX = 'center',
        alignY = 'end',
    })
    local stretched = Drawable.new({
        width = 100,
        height = 80,
        padding = { 10, 15, 20, 25 },
        alignX = 'stretch',
        alignY = 'stretch',
    })
    local collapsed = Drawable.new({
        width = 8,
        height = 6,
        padding = 10,
        alignX = 'end',
        alignY = 'center',
    })

    assert_rectangle_equal(centered:resolveContentRect(20, 10),
        Rectangle.new(45, 50, 20, 10),
        'Drawable alignment should resolve relative to the content box')
    assert_rectangle_equal(stretched:resolveContentRect(20, 10),
        Rectangle.new(25, 10, 60, 50),
        'Drawable stretch alignment should fill the content-box extent')
    assert_rectangle_equal(collapsed:resolveContentRect(20, 12),
        Rectangle.new(10, 10, 20, 12),
        'Collapsed content boxes should place aligned content at the content origin')
    assert_rectangle_equal(collapsed:resolveContentRect(0, 0),
        Rectangle.new(10, 10, 0, 0),
        'Collapsed content boxes should preserve zero-sized aligned content')

    assert_error(function()
        Drawable.new({ alignX = 'left' })
    end, 'Drawable.alignX',
    'Drawable should reject unsupported horizontal alignment values')

    assert_error(function()
        Drawable.new({ alignX = false })
    end, 'Drawable.alignX',
    'Drawable should fail deterministically instead of coercing falsy alignX input')

    assert_error(function()
        centered.alignY = 'bottom'
    end, 'Drawable.alignY',
        'Drawable should reject unsupported vertical alignment values')
end

local function run_deferred_visual_surface_tests()
    local root = Drawable.new({
        tag = 'root',
        width = 100,
        height = 60,
        interactive = true,
        opacity = 0,
        shader = { id = 'stored' },
        mask = { id = 'stored-mask' },
    })
    local child = Drawable.new({
        tag = 'child',
        width = 40,
        height = 20,
    })
    local order = {}

    root:addChild(child)
    root:_draw_subtree({}, function(node)
        order[#order + 1] = node.tag
    end)

    assert_equal(#order, 2,
        'Deferred visual props should not change subtree draw traversal count')
    assert_equal(order[1], 'root',
        'Drawable draw traversal should still visit the root first')
    assert_equal(order[2], 'child',
        'Drawable draw traversal should still visit descendants in tree order')
    assert_equal(root:_hit_test(5, 5), root,
        'Drawable opacity=0 should not suppress hit targeting by itself')
end

local function run()
    run_public_surface_tests()
    run_content_box_tests()
    run_alignment_resolution_tests()
    run_deferred_visual_surface_tests()
end

return {
    run = run,
}
