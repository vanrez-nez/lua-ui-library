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

local function assert_contains(values, needle, message)
    for index = 1, #values do
        if values[index] == needle then
            return
        end
    end

    error(message .. ': missing "' .. tostring(needle) .. '"', 2)
end

local function make_fake_graphics()
    local graphics = {
        calls = {},
        current_scissor = nil,
        stencil_compare = nil,
        stencil_value = nil,
        current_canvas = nil,
        current_shader = nil,
        current_blend_mode = 'alpha',
        current_alpha_mode = 'alphamultiply',
        current_color = { 1, 1, 1, 1 },
        next_canvas_id = 1,
    }

    function graphics.getScissor()
        local rect = graphics.current_scissor
        if rect == nil then
            return nil
        end

        return rect.x, rect.y, rect.width, rect.height
    end

    function graphics.setScissor(x, y, width, height)
        if x == nil then
            graphics.current_scissor = nil
            graphics.calls[#graphics.calls + 1] = 'scissor:nil'
            return
        end

        graphics.current_scissor = {
            x = x,
            y = y,
            width = width,
            height = height,
        }
        graphics.calls[#graphics.calls + 1] = string.format(
            'scissor:%.2f:%.2f:%.2f:%.2f',
            x,
            y,
            width,
            height
        )
    end

    function graphics.getStencilTest()
        return graphics.stencil_compare, graphics.stencil_value
    end

    function graphics.setStencilTest(compare, value)
        graphics.stencil_compare = compare
        graphics.stencil_value = value

        if compare == nil then
            graphics.calls[#graphics.calls + 1] = 'stencil_test:nil'
            return
        end

        graphics.calls[#graphics.calls + 1] =
            'stencil_test:' .. tostring(compare) .. ':' .. tostring(value)
    end

    function graphics.stencil(callback, action, value, keepvalues)
        graphics.calls[#graphics.calls + 1] =
            'stencil:' .. tostring(action) .. ':' .. tostring(value) ..
            ':' .. tostring(keepvalues)
        callback()
    end

    function graphics.polygon(mode, points)
        graphics.calls[#graphics.calls + 1] =
            'polygon:' .. tostring(mode) .. ':' .. tostring(#points)
    end

    function graphics.newCanvas(width, height)
        local canvas = {
            id = 'canvas-' .. tostring(graphics.next_canvas_id),
            width = width,
            height = height,
        }
        graphics.next_canvas_id = graphics.next_canvas_id + 1
        graphics.calls[#graphics.calls + 1] =
            'new_canvas:' .. canvas.id .. ':' .. tostring(width) .. ':' .. tostring(height)
        return canvas
    end

    function graphics.getCanvas()
        return graphics.current_canvas
    end

    function graphics.setCanvas(canvas)
        graphics.current_canvas = canvas
        graphics.calls[#graphics.calls + 1] =
            'set_canvas:' .. tostring(canvas and canvas.id or 'nil')
    end

    function graphics.clear()
        graphics.calls[#graphics.calls + 1] = 'clear'
    end

    function graphics.getColor()
        return graphics.current_color[1], graphics.current_color[2],
            graphics.current_color[3], graphics.current_color[4]
    end

    function graphics.setColor(r, g, b, a)
        graphics.current_color = { r, g, b, a }
        graphics.calls[#graphics.calls + 1] =
            string.format('color:%.2f:%.2f:%.2f:%.2f', r, g, b, a)
    end

    function graphics.getShader()
        return graphics.current_shader
    end

    function graphics.setShader(shader)
        graphics.current_shader = shader
        graphics.calls[#graphics.calls + 1] =
            'shader:' .. tostring(shader and shader.id or 'nil')
    end

    function graphics.getBlendMode()
        return graphics.current_blend_mode, graphics.current_alpha_mode
    end

    function graphics.setBlendMode(mode, alpha_mode)
        graphics.current_blend_mode = mode
        graphics.current_alpha_mode = alpha_mode or graphics.current_alpha_mode
        graphics.calls[#graphics.calls + 1] =
            'blend:' .. tostring(mode) .. ':' .. tostring(graphics.current_alpha_mode)
    end

    function graphics.draw(drawable, x, y, rotation, sx, sy, ox, oy)
        graphics.calls[#graphics.calls + 1] = string.format(
            'draw:%s:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f',
            tostring(drawable and drawable.id or drawable),
            x or 0,
            y or 0,
            rotation or 0,
            sx or 1,
            sy or 1,
            ox or 0,
            oy or 0
        )
    end

    return graphics
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

local function run_visual_effect_isolation_tests()
    local root = Drawable.new({
        tag = 'root',
        width = 100,
        height = 60,
        interactive = true,
        opacity = 0.5,
        shader = { id = 'stored' },
        blendMode = 'add',
    })
    local child = Drawable.new({
        tag = 'child',
        width = 40,
        height = 20,
    })
    local graphics = make_fake_graphics()
    local order = {}

    root:addChild(child)
    root:_draw_subtree(graphics, function(node)
        order[#order + 1] = node.tag
    end)

    assert_equal(#order, 2,
        'Drawable render effects should preserve subtree traversal count')
    assert_equal(order[1], 'root',
        'Drawable draw traversal should still visit the root first')
    assert_equal(order[2], 'child',
        'Drawable draw traversal should still visit descendants in tree order')
    assert_contains(graphics.calls, 'set_canvas:canvas-1',
        'Drawable visual effects should isolate subtree rendering to a canvas')
    assert_contains(graphics.calls, 'shader:stored',
        'Drawable shaders should be applied during isolated subtree compositing')
    assert_contains(graphics.calls, 'blend:add:alphamultiply',
        'Drawable blendMode should be applied during isolated subtree compositing')
    assert_contains(graphics.calls, 'color:1.00:1.00:1.00:0.50',
        'Drawable opacity should modulate isolated subtree compositing alpha')
    assert_contains(graphics.calls, 'draw:canvas-1:0.00:0.00:0.00:1.00:1.00:0.00:0.00',
        'Isolated Drawable subtrees should be composited back into the parent target')
    assert_equal(root:_hit_test(5, 5), root,
        'Drawable visual effects should not suppress hit targeting by themselves')
end

local function run_multiply_blend_mode_tests()
    local root = Drawable.new({
        tag = 'root',
        width = 100,
        height = 60,
        blendMode = 'multiply',
    })
    local graphics = make_fake_graphics()

    root:_draw_subtree(graphics, function()
    end)

    assert_contains(graphics.calls, 'blend:multiply:premultiplied',
        'Drawable multiply blendMode should use premultiplied alpha during isolated subtree compositing')
end

local function run_mask_failure_tests()
    local root = Drawable.new({
        width = 100,
        height = 60,
        mask = { id = 'mask.asset' },
    })

    assert_error(function()
        root:_draw_subtree(make_fake_graphics(), function()
        end)
    end, 'mask rendering is not implemented',
        'Unsupported Drawable mask rendering should fail deterministically')
end

local function run()
    run_public_surface_tests()
    run_content_box_tests()
    run_alignment_resolution_tests()
    run_visual_effect_isolation_tests()
    run_multiply_blend_mode_tests()
    run_mask_failure_tests()
end

return {
    run = run,
}
