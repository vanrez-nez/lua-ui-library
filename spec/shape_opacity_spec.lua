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

local function assert_contains(values, needle, message)
    for index = 1, #values do
        if values[index] == needle then
            return
        end
    end

    error(message .. ': missing "' .. tostring(needle) .. '"', 2)
end

local function assert_not_contains(values, needle, message)
    for index = 1, #values do
        if values[index] == needle then
            error(message .. ': unexpected "' .. tostring(needle) .. '"', 2)
        end
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

    function graphics.origin()
        graphics.calls[#graphics.calls + 1] = 'origin'
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

    function graphics.polygon(mode, points)
        graphics.calls[#graphics.calls + 1] =
            'polygon:' .. tostring(mode) .. ':' .. tostring(#points)
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

local function run_direct_shape_opacity_tests()
    local shape = UI.RectShape.new({
        tag = 'shape',
        width = 80,
        height = 40,
        interactive = true,
        opacity = 0.5,
    })
    local graphics = make_fake_graphics()
    local draw_order = {}

    shape:_draw_subtree(graphics, function(node)
        draw_order[#draw_order + 1] = node.tag
        node:draw(graphics)
    end)

    assert_equal(#draw_order, 1,
        'Shape opacity isolation should preserve subtree traversal count')
    assert_equal(draw_order[1], 'shape',
        'Shape opacity isolation should still visit the root node')
    assert_contains(graphics.calls, 'set_canvas:canvas-1',
        'Shape opacity should isolate subtree rendering to a canvas')
    assert_contains(graphics.calls, 'color:1.00:1.00:1.00:0.50',
        'Shape opacity should modulate isolated subtree compositing alpha')
    assert_contains(graphics.calls, 'draw:canvas-1:0.00:0.00:0.00:1.00:1.00:0.00:0.00',
        'Isolated Shape subtrees should be composited back into the parent target')
    assert_equal(shape:_hit_test(5, 5), shape,
        'Shape opacity should not suppress hit targeting by itself')
end

local function run_motion_shape_opacity_tests()
    local shape = UI.RectShape.new({
        tag = 'shape',
        width = 60,
        height = 30,
        interactive = true,
        opacity = 1,
    })
    local graphics = make_fake_graphics()

    shape:_apply_motion_value('root', 'opacity', 0.25)
    shape:_draw_subtree(graphics, function(node)
        node:draw(graphics)
    end)

    assert_contains(graphics.calls, 'set_canvas:canvas-1',
        'Motion-owned Shape opacity should isolate subtree rendering')
    assert_contains(graphics.calls, 'color:1.00:1.00:1.00:0.25',
        'Motion-owned Shape opacity should modulate isolated subtree compositing alpha')
end

local function run_shape_root_shader_and_blend_mode_tests()
    local shape = UI.RectShape.new({
        tag = 'shape',
        width = 70,
        height = 35,
        shader = { id = 'shape-fx' },
        blendMode = 'screen',
    })
    local graphics = make_fake_graphics()

    shape:_draw_subtree(graphics, function(node)
        node:draw(graphics)
    end)

    assert_contains(graphics.calls, 'set_canvas:canvas-1',
        'Shape root shader and blendMode should isolate subtree rendering through the shared capability surface')
    assert_contains(graphics.calls, 'shader:shape-fx',
        'Shape root shader should be applied during isolated subtree compositing')
    assert_contains(graphics.calls, 'blend:screen:alphamultiply',
        'Shape root blendMode should be applied during isolated subtree compositing')
end

local function run_shape_default_root_compositing_fast_path_tests()
    local shape = UI.RectShape.new({
        tag = 'shape',
        width = 70,
        height = 35,
        blendMode = 'normal',
    })
    local graphics = make_fake_graphics()
    local draw_order = {}

    shape:_draw_subtree(graphics, function(node)
        draw_order[#draw_order + 1] = node.tag
    end)

    assert_equal(#draw_order, 1,
        'Shape default root compositing state should still traverse the node')
    assert_equal(#graphics.calls, 0,
        'Shape default root compositing state should stay on the fast path without canvas or graphics-state mutation')
    assert_not_contains(graphics.calls, 'set_canvas:canvas-1',
        'Shape default root compositing state should not isolate the subtree')
end

local function run_shape_shader_capability_failure_tests()
    local shape = UI.RectShape.new({
        tag = 'shape',
        width = 70,
        height = 35,
        shader = { id = 'shape-fx' },
    })
    local graphics = make_fake_graphics()

    graphics.setShader = nil
    graphics.getShader = nil

    assert_error(function()
        shape:_draw_subtree(graphics, function(node)
            node:draw(graphics)
        end)
    end, 'graphics adapter must support setShader for root shader compositing',
        'Shape root shader should fail deterministically when the graphics adapter cannot install shaders')
end

local function run_zero_opacity_targeting_tests()
    local shape = UI.RectShape.new({
        width = 40,
        height = 20,
        interactive = true,
        opacity = 0,
    })

    assert_equal(shape:_hit_test(5, 5), shape,
        'Shape with opacity = 0 should remain targetable')
end

local function run()
    run_direct_shape_opacity_tests()
    run_motion_shape_opacity_tests()
    run_shape_root_shader_and_blend_mode_tests()
    run_shape_default_root_compositing_fast_path_tests()
    run_shape_shader_capability_failure_tests()
    run_zero_opacity_targeting_tests()
end

return {
    run = run,
}
