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

local function assert_not_contains(values, needle, message)
    for index = 1, #values do
        if values[index] == needle then
            error(message .. ': unexpected "' .. tostring(needle) .. '"', 2)
        end
    end
end

local function find_index(values, needle)
    for index = 1, #values do
        if values[index] == needle then
            return index
        end
    end

    return nil
end

local function count_prefix(values, prefix)
    local count = 0

    for index = 1, #values do
        if values[index]:sub(1, #prefix) == prefix then
            count = count + 1
        end
    end

    return count
end

local function get_world_origin(node)
    local bounds = node:getWorldBounds()
    return bounds.x, bounds.y
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
        blendMode = 'normal',
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
    assert_equal(node.blendMode, 'normal', 'Drawable should preserve blendMode')
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

local function run_union_alignment_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 240,
    })
    local centered = Drawable.new({
        width = 200,
        height = 80,
        alignX = 'center',
    })
    local ended = Drawable.new({
        y = 100,
        width = 120,
        height = 100,
        alignY = 'end',
    })
    local stretched = Drawable.new({
        y = 210,
        width = 200,
        height = 60,
        alignX = 'stretch',
        alignY = 'stretch',
    })
    local center_first = Drawable.new({
        x = 10,
        width = 20,
        height = 10,
    })
    local center_second = Drawable.new({
        x = 60,
        width = 20,
        height = 10,
    })
    local end_first = Drawable.new({
        y = 10,
        width = 10,
        height = 15,
    })
    local end_second = Drawable.new({
        y = 35,
        width = 10,
        height = 15,
    })
    local stretch_first = Drawable.new({
        x = 15,
        y = 10,
        width = 20,
        height = 10,
    })
    local stretch_second = Drawable.new({
        x = 55,
        y = 25,
        width = 30,
        height = 15,
    })

    centered:addChild(center_first)
    centered:addChild(center_second)
    ended:addChild(end_first)
    ended:addChild(end_second)
    stretched:addChild(stretch_first)
    stretched:addChild(stretch_second)

    stage.baseSceneLayer:addChild(centered)
    stage.baseSceneLayer:addChild(ended)
    stage.baseSceneLayer:addChild(stretched)
    stage:update()

    local center_first_x = get_world_origin(center_first)
    local center_second_x = get_world_origin(center_second)
    local _, end_first_y = get_world_origin(end_first)
    local _, end_second_y = get_world_origin(end_second)

    assert_equal(center_first_x, 70,
        'Drawable center alignment should shift the visible child union as one unit on x')
    assert_equal(center_second_x, 120,
        'Drawable center alignment should preserve relative child spacing inside the shifted union')
    assert_equal(end_first_y, 160,
        'Drawable end alignment should shift the visible child union as one unit on y')
    assert_equal(end_second_y, 185,
        'Drawable end alignment should preserve relative child spacing on y')
    assert_equal(stretch_first:getWorldBounds().x, 0,
        'Drawable stretch alignment should anchor stretched children at the content-box origin')
    assert_equal(stretch_first:getWorldBounds().y, 210,
        'Drawable stretch alignment should anchor stretched children at the content-box origin on y')
    assert_equal(stretch_first:getWorldBounds().width, 200,
        'Drawable stretch alignment should expand each child to the full content-box width')
    assert_equal(stretch_first:getWorldBounds().height, 60,
        'Drawable stretch alignment should expand each child to the full content-box height')
    assert_equal(stretch_second:getWorldBounds().x, 0,
        'Drawable stretch alignment should apply independently to later children on x')
    assert_equal(stretch_second:getWorldBounds().y, 210,
        'Drawable stretch alignment should apply independently to later children on y')
    assert_equal(stretch_second:getWorldBounds().width, 200,
        'Drawable stretch alignment should set every child width to the full content-box width')
    assert_equal(stretch_second:getWorldBounds().height, 60,
        'Drawable stretch alignment should set every child height to the full content-box height')

    stage:destroy()
end

local function run_content_sizing_contract_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 240,
    })
    local negative = Drawable.new({
        width = 'content',
        height = 'content',
        padding = { 6, 8 },
    })
    local hidden_negative = Drawable.new({
        x = -50,
        y = -40,
        width = 20,
        height = 10,
    })

    negative:addChild(hidden_negative)
    stage.baseSceneLayer:addChild(negative)
    stage:update()

    assert_equal(negative:getLocalBounds().width, 16,
        'Drawable content sizing should collapse to horizontal padding when visible children stay left of the positive quadrant')
    assert_equal(negative:getLocalBounds().height, 12,
        'Drawable content sizing should collapse to vertical padding when visible children stay above the positive quadrant')
    assert_equal(hidden_negative:getWorldBounds().x, -50,
        'Drawable content sizing should still allow fully negative-offset children to overflow without error')
    assert_equal(hidden_negative:getWorldBounds().y, -40,
        'Drawable content sizing should preserve negative overflow on y without error')

    stage:destroy()

    stage = UI.Stage.new({
        width = 320,
        height = 240,
    })

    assert_error(function()
        local guarded = Drawable.new({
            width = 'content',
            height = 20,
        })

        guarded:addChild(Drawable.new({
            width = 'fill',
            height = 10,
        }))
        stage.baseSceneLayer:addChild(guarded)
        stage:update()
    end, 'Drawable has a circular measurement dependency because width = "content" and a visible child has width = "fill"',
        'Drawable content sizing should fail hard when a visible child uses fill on the same axis')

    stage:destroy()
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
    assert_contains(graphics.calls, 'blend:add:premultiplied',
        'Drawable blendMode should use premultiplied alpha during isolated subtree compositing')
    assert_contains(graphics.calls, 'color:0.50:0.50:0.50:0.50',
        'Drawable opacity should preserve premultiplied alpha when modulating isolated subtree compositing opacity')
    assert_contains(graphics.calls, 'draw_quad:canvas-1:0.00:0.00:100.00:60.00:0.00:0.00:0.00:1.00:1.00:0.00:0.00',
        'Isolated Drawable subtrees should be composited back into the parent target')
    assert_equal(root:_hit_test(5, 5), root,
        'Drawable visual effects should not suppress hit targeting by themselves')
end

local function run_default_root_compositing_fast_path_tests()
    local root = Drawable.new({
        tag = 'root',
        width = 100,
        height = 60,
        blendMode = 'normal',
    })
    local graphics = make_fake_graphics()
    local order = {}

    root:_draw_subtree(graphics, function(node)
        order[#order + 1] = node.tag
    end)

    assert_equal(#order, 1,
        'Drawable default root compositing state should still traverse the node')
    assert_equal(#graphics.calls, 0,
        'Drawable default root compositing state should not mutate graphics state or allocate a canvas')
    assert_not_contains(graphics.calls, 'set_canvas:canvas-1',
        'Drawable default root compositing state should not isolate the subtree')
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

local function run_stage_attached_blend_mode_bounds_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 180,
    })
    local root = Drawable.new({
        tag = 'root',
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

    assert_contains(graphics.calls, 'new_canvas:canvas-1:320:192',
        'Stage-attached isolated blendMode should still allocate against the stage-sized composition target')
    assert_contains(graphics.calls, 'draw_quad:canvas-1:40.00:30.00:100.00:60.00:40.00:30.00:0.00:1.00:1.00:0.00:0.00',
        'Stage-attached isolated blendMode should composite only the resolved node result instead of the full isolation canvas')
    assert_contains(graphics.calls, 'scissor:40.00:30.00:100.00:60.00',
        'Stage-attached isolated blendMode should restrict composite-back to the node result bounds')
end

local function run_nested_isolation_stack_tests()
    local root = Drawable.new({
        tag = 'root',
        width = 100,
        height = 60,
        opacity = 0.5,
    })
    local child = UI.RectShape.new({
        tag = 'child',
        width = 40,
        height = 20,
        blendMode = 'screen',
    })
    local graphics = make_fake_graphics()

    root:addChild(child)
    root:_draw_subtree(graphics, function()
    end)

    assert_contains(graphics.calls, 'set_canvas:canvas-1',
        'Parent isolation should push the first composition target')
    assert_contains(graphics.calls, 'set_canvas:canvas-2',
        'Nested child isolation should push a second composition target')
    assert_contains(graphics.calls, 'draw_quad:canvas-2:0.00:0.00:40.00:20.00:0.00:0.00:0.00:1.00:1.00:0.00:0.00',
        'Nested isolated children should composite back into the immediate parent target')
    assert_contains(graphics.calls, 'draw_quad:canvas-1:0.00:0.00:100.00:60.00:0.00:0.00:0.00:1.00:1.00:0.00:0.00',
        'The parent isolated subtree should then composite back into its own parent target')
    assert_true(
        find_index(graphics.calls, 'draw_quad:canvas-2:0.00:0.00:40.00:20.00:0.00:0.00:0.00:1.00:1.00:0.00:0.00') <
            find_index(graphics.calls, 'draw_quad:canvas-1:0.00:0.00:100.00:60.00:0.00:0.00:0.00:1.00:1.00:0.00:0.00'),
        'Nested isolated composition should unwind from child target back to parent target in stack order'
    )
end

local function run_isolated_failure_restore_tests()
    local root = Drawable.new({
        tag = 'root',
        width = 100,
        height = 60,
        opacity = 0.5,
        shader = { id = 'stored' },
        blendMode = 'screen',
    })
    local root_canvas = { id = 'root-target' }
    local baseline_shader = { id = 'baseline' }
    local graphics = make_fake_graphics()

    graphics.current_canvas = root_canvas
    graphics.current_shader = baseline_shader
    graphics.current_blend_mode = 'multiply'
    graphics.current_alpha_mode = 'premultiplied'
    graphics.current_color = { 0.2, 0.3, 0.4, 0.5 }
    graphics.current_scissor = {
        x = 1,
        y = 2,
        width = 3,
        height = 4,
    }
    graphics.stencil_compare = 'equal'
    graphics.stencil_value = 7

    assert_error(function()
        root:_draw_subtree(graphics, function()
            error('draw boom')
        end)
    end, 'draw boom',
        'Isolated root compositing should re-raise subtree draw failures')

    assert_true(graphics.current_canvas == root_canvas,
        'Isolated root compositing should restore the active canvas after failure')
    assert_true(graphics.current_shader == baseline_shader,
        'Isolated root compositing should restore the active shader after failure')
    assert_equal(graphics.current_blend_mode, 'multiply',
        'Isolated root compositing should restore the blend mode after failure')
    assert_equal(graphics.current_alpha_mode, 'premultiplied',
        'Isolated root compositing should restore the alpha mode after failure')
    assert_equal(graphics.current_color[1], 0.2,
        'Isolated root compositing should restore color r after failure')
    assert_equal(graphics.current_color[2], 0.3,
        'Isolated root compositing should restore color g after failure')
    assert_equal(graphics.current_color[3], 0.4,
        'Isolated root compositing should restore color b after failure')
    assert_equal(graphics.current_color[4], 0.5,
        'Isolated root compositing should restore color a after failure')
    assert_equal(graphics.current_scissor.x, 1,
        'Isolated root compositing should restore scissor x after failure')
    assert_equal(graphics.current_scissor.y, 2,
        'Isolated root compositing should restore scissor y after failure')
    assert_equal(graphics.current_scissor.width, 3,
        'Isolated root compositing should restore scissor width after failure')
    assert_equal(graphics.current_scissor.height, 4,
        'Isolated root compositing should restore scissor height after failure')
    assert_equal(graphics.stencil_compare, 'equal',
        'Isolated root compositing should restore stencil compare after failure')
    assert_equal(graphics.stencil_value, 7,
        'Isolated root compositing should restore stencil value after failure')

    root:_draw_subtree(graphics, function()
    end)

    assert_equal(count_prefix(graphics.calls, 'new_canvas:'), 1,
        'Isolated root compositing should release pooled canvases even when a prior draw failed')
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
    run_union_alignment_tests()
    run_content_sizing_contract_tests()
    run_visual_effect_isolation_tests()
    run_default_root_compositing_fast_path_tests()
    run_multiply_blend_mode_tests()
    run_stage_attached_blend_mode_bounds_tests()
    run_nested_isolation_stack_tests()
    run_isolated_failure_restore_tests()
    run_mask_failure_tests()
end

return {
    run = run,
}
