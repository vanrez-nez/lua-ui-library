local UI = require('lib.ui')

local Drawable = UI.Drawable
local RectShape = UI.RectShape

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

local function find_index(values, needle)
    for index = 1, #values do
        if values[index] == needle then
            return index
        end
    end

    return nil
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
        current_line_width = 1,
        current_line_style = 'smooth',
        current_line_join = 'miter',
        current_miter_limit = 10,
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

    function graphics.newQuad(x, y, width, height, sw, sh)
        return {
            id = 'quad',
            x = x,
            y = y,
            width = width,
            height = height,
            sw = sw,
            sh = sh,
        }
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

    function graphics.push()
        graphics.calls[#graphics.calls + 1] = 'push'
    end

    function graphics.pop()
        graphics.calls[#graphics.calls + 1] = 'pop'
    end

    function graphics.translate(x, y)
        graphics.calls[#graphics.calls + 1] =
            string.format('translate:%.2f:%.2f', x or 0, y or 0)
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

    function graphics.getLineWidth()
        return graphics.current_line_width
    end

    function graphics.setLineWidth(value)
        graphics.current_line_width = value
        graphics.calls[#graphics.calls + 1] = 'line_width:' .. tostring(value)
    end

    function graphics.getLineStyle()
        return graphics.current_line_style
    end

    function graphics.setLineStyle(value)
        graphics.current_line_style = value
        graphics.calls[#graphics.calls + 1] = 'line_style:' .. tostring(value)
    end

    function graphics.getLineJoin()
        return graphics.current_line_join
    end

    function graphics.setLineJoin(value)
        graphics.current_line_join = value
        graphics.calls[#graphics.calls + 1] = 'line_join:' .. tostring(value)
    end

    function graphics.getMiterLimit()
        return graphics.current_miter_limit
    end

    function graphics.setMiterLimit(value)
        graphics.current_miter_limit = value
        graphics.calls[#graphics.calls + 1] = 'miter_limit:' .. tostring(value)
    end

    function graphics.polygon(mode, points)
        graphics.calls[#graphics.calls + 1] =
            'polygon:' .. tostring(mode) .. ':' .. tostring(#points)
    end

    function graphics.draw(drawable, ...)
        local args = { ... }

        if type(args[1]) == 'table' and args[1].id == 'quad' then
            local quad = args[1]
            graphics.calls[#graphics.calls + 1] = string.format(
                'draw_quad:%s:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f',
                tostring(drawable and drawable.id or drawable),
                quad.x,
                quad.y,
                quad.width,
                quad.height,
                args[2] or 0,
                args[3] or 0,
                args[4] or 0,
                args[5] or 1,
                args[6] or 1,
                args[7] or 0,
                args[8] or 0
            )
            return
        end

        graphics.calls[#graphics.calls + 1] = string.format(
            'draw:%s:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f',
            tostring(drawable and drawable.id or drawable),
            args[1] or 0,
            args[2] or 0,
            args[3] or 0,
            args[4] or 1,
            args[5] or 1,
            args[6] or 0,
            args[7] or 0
        )
    end

    return graphics
end

local function run_small_stage_attached_blend_mode_canvas_size_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 180,
    })
    local root = Drawable.new({
        x = 40,
        y = 30,
        width = 100,
        height = 60,
        blendMode = 'multiply',
    })
    local graphics = make_fake_graphics()

    stage.baseSceneLayer:addChild(root)
    stage:update()

    root:_draw_subtree(graphics, function()
    end)

    assert_contains(graphics.calls, 'new_canvas:canvas-1:128:64',
        'Bounds-aware isolation should bucket small stage-attached blendMode subtrees to their cropped paint bounds')
    assert_contains(graphics.calls, 'draw_quad:canvas-1:0.00:0.00:100.00:60.00:40.00:30.00:0.00:1.00:1.00:0.00:0.00',
        'Bounds-aware isolation should composite back a cropped subtree at the original world result position')
    assert_contains(graphics.calls, 'scissor:40.00:30.00:100.00:60.00',
        'Bounds-aware isolation should keep composite-back clipping aligned to the resolved subtree result bounds')

    stage:destroy()
end

local function run_paint_bounds_cropping_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 180,
    })
    local root = Drawable.new({
        x = 40,
        y = 30,
        width = 100,
        height = 60,
        borderColor = { 1, 1, 1, 1 },
        borderWidth = { 8, 10, 12, 14 },
        blendMode = 'multiply',
    })
    local graphics = make_fake_graphics()

    stage.baseSceneLayer:addChild(root)
    stage:update()

    root:_draw_subtree(graphics, function()
    end)

    assert_contains(graphics.calls, 'new_canvas:canvas-1:128:128',
        'Bounds-aware isolation should size cropped canvases from expanded paint bounds, not the full stage target')
    assert_contains(graphics.calls, 'draw_quad:canvas-1:0.00:0.00:112.00:70.00:33.00:26.00:0.00:1.00:1.00:0.00:0.00',
        'Bounds-aware isolation should composite border-expanded paint bounds back at the correct destination origin')
    assert_contains(graphics.calls, 'scissor:33.00:26.00:112.00:70.00',
        'Bounds-aware isolation should preserve expanded composite-back clipping for styled Drawable paint bounds')

    stage:destroy()
end

local function run_nested_isolation_origin_stack_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 180,
    })
    local root = Drawable.new({
        x = 40,
        y = 30,
        width = 100,
        height = 60,
        opacity = 0.5,
    })
    local child = Drawable.new({
        x = 10,
        y = 5,
        width = 20,
        height = 10,
        blendMode = 'multiply',
    })
    local graphics = make_fake_graphics()

    root:addChild(child)
    stage.baseSceneLayer:addChild(root)
    stage:update()

    root:_draw_subtree(graphics, function()
    end)

    assert_contains(graphics.calls, 'new_canvas:canvas-1:128:64',
        'Parent cropped isolation should use subtree paint bounds for the outer target')
    assert_contains(graphics.calls, 'new_canvas:canvas-2:64:64',
        'Nested cropped isolation should size child canvases against the child result bounds')
    assert_contains(graphics.calls, 'draw_quad:canvas-2:0.00:0.00:20.00:10.00:50.00:35.00:0.00:1.00:1.00:0.00:0.00',
        'Nested cropped isolation should still composite the child result at the original world-space placement before the parent unwinds')
    assert_contains(graphics.calls, 'draw_quad:canvas-1:0.00:0.00:100.00:60.00:40.00:30.00:0.00:1.00:1.00:0.00:0.00',
        'Parent cropped isolation should composite back after the child isolated target resolves')
    assert_true(
        find_index(graphics.calls, 'draw_quad:canvas-2:0.00:0.00:20.00:10.00:50.00:35.00:0.00:1.00:1.00:0.00:0.00') <
            find_index(graphics.calls, 'draw_quad:canvas-1:0.00:0.00:100.00:60.00:40.00:30.00:0.00:1.00:1.00:0.00:0.00'),
        'Nested cropped isolation should still unwind from child target back to parent target in stack order'
    )

    stage:destroy()
end

local function run_shader_fallback_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 180,
    })
    local root = Drawable.new({
        x = 40,
        y = 30,
        width = 100,
        height = 60,
        shader = { id = 'stored' },
        blendMode = 'multiply',
    })
    local graphics = make_fake_graphics()

    stage.baseSceneLayer:addChild(root)
    stage:update()

    root:_draw_subtree(graphics, function()
    end)

    assert_contains(graphics.calls, 'new_canvas:canvas-1:320:192',
        'Bounds-aware isolation should retain the full-target fallback when root shader compositing is still on the unproven path')
    assert_contains(graphics.calls, 'draw_quad:canvas-1:40.00:30.00:100.00:60.00:40.00:30.00:0.00:1.00:1.00:0.00:0.00',
        'Shader fallback should preserve the current full-target composite-back source rect')

    stage:destroy()
end

local function run_shape_result_clip_fallback_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 180,
    })
    local shape = RectShape.new({
        x = 24,
        y = 18,
        width = 70,
        height = 35,
        fillOpacity = 0,
        strokeColor = { 1, 0, 0, 1 },
        strokeWidth = 6,
        blendMode = 'screen',
    })
    local graphics = make_fake_graphics()

    stage.baseSceneLayer:addChild(shape)
    stage:update()

    shape:_draw_subtree(graphics, function(node)
        node:draw(graphics)
    end)

    assert_contains(graphics.calls, 'new_canvas:canvas-1:320:192',
        'Bounds-aware isolation should retain the full-target fallback when shape result clipping is still on the unproven path')
    assert_contains(graphics.calls, 'stencil:replace:1:true',
        'Shape result-clip fallback should still push the internal stencil clip before composite-back')
    assert_contains(graphics.calls, 'draw:canvas-1:0.00:0.00:0.00:1.00:1.00:0.00:0.00',
        'Shape result-clip fallback should keep the current full-target canvas draw path through the internal clip')

    stage:destroy()
end

local function run()
    run_small_stage_attached_blend_mode_canvas_size_tests()
    run_paint_bounds_cropping_tests()
    run_nested_isolation_origin_stack_tests()
    run_shader_fallback_tests()
    run_shape_result_clip_fallback_tests()
end

return {
    run = run,
}
