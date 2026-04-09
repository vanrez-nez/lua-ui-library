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

local function assert_occurs_at_least(values, needle_prefix, minimum, message)
    local count = 0

    for index = 1, #values do
        if values[index]:sub(1, #needle_prefix) == needle_prefix then
            count = count + 1
        end
    end

    if count < minimum then
        error(message .. ': expected at least ' .. tostring(minimum) ..
            ' matches for "' .. tostring(needle_prefix) .. '", got ' ..
            tostring(count), 2)
    end
end

local function collect_prefixed_values(values, needle_prefix)
    local matches = {}

    for index = 1, #values do
        if values[index]:sub(1, #needle_prefix) == needle_prefix then
            matches[#matches + 1] = values[index]
        end
    end

    return matches
end

local function assert_prefixed_groups_match(values, needle_prefix, group_count, message)
    local matches = collect_prefixed_values(values, needle_prefix)

    if group_count == nil or group_count <= 0 then
        error('group_count must be positive', 2)
    end

    if #matches == 0 or (#matches % group_count) ~= 0 then
        error(message .. ': expected the match count for "' ..
            tostring(needle_prefix) .. '" to be divisible by ' ..
            tostring(group_count) .. ', got ' .. tostring(#matches), 2)
    end

    local group_size = #matches / group_count

    for group_index = 2, group_count do
        local offset = (group_index - 1) * group_size

        for index = 1, group_size do
            if matches[index] ~= matches[index + offset] then
                error(message .. ': mismatch at group ' .. tostring(group_index) ..
                    ', entry ' .. tostring(index) .. ', expected "' ..
                    tostring(matches[index]) .. '", got "' ..
                    tostring(matches[index + offset]) .. '"', 2)
            end
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
        current_line_width = 1,
        current_line_style = 'smooth',
        current_line_join = 'miter',
        current_miter_limit = 10,
        next_canvas_id = 1,
        next_shader_id = 1,
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
            'stencil:' .. tostring(action) .. ':' .. tostring(value) .. ':' .. tostring(keepvalues)
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

    function graphics.newShader()
        local shader = {
            id = 'root-compositor-alpha-clip',
            ordinal = graphics.next_shader_id,
        }

        graphics.next_shader_id = graphics.next_shader_id + 1
        graphics.calls[#graphics.calls + 1] = 'new_shader:' .. tostring(shader.id)

        return shader
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

    function graphics.line(...)
        local points = { ... }
        graphics.calls[#graphics.calls + 1] = string.format(
            'line:%.2f:%.2f:%.2f:%.2f',
            points[1],
            points[2],
            points[3],
            points[4]
        )
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
    assert_contains(graphics.calls, 'color:0.50:0.50:0.50:0.50',
        'Shape opacity should preserve premultiplied alpha when modulating isolated subtree compositing opacity')
    assert_contains(graphics.calls, 'draw_quad:canvas-1:0.00:0.00:80.00:40.00:0.00:0.00:0.00:1.00:1.00:0.00:0.00',
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
    assert_contains(graphics.calls, 'color:0.25:0.25:0.25:0.25',
        'Motion-owned Shape opacity should preserve premultiplied alpha when modulating isolated subtree compositing opacity')
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
    assert_contains(graphics.calls, 'blend:screen:premultiplied',
        'Shape root blendMode should use premultiplied alpha during isolated subtree compositing')
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

local function run_stage_attached_shape_blend_mode_bounds_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 180,
    })
    local shape = UI.RectShape.new({
        tag = 'shape',
        x = 24,
        y = 18,
        width = 70,
        height = 35,
        blendMode = 'screen',
    })
    local graphics = make_fake_graphics()

    stage.baseSceneLayer:addChild(shape)
    stage:update()

    shape:_draw_subtree(graphics, function(node)
        node:draw(graphics)
    end)

    assert_contains(graphics.calls, 'new_canvas:canvas-1:320:192',
        'Stage-attached Shape blendMode should still allocate against the stage-sized composition target')
    assert_contains(graphics.calls, 'draw_quad:canvas-1:24.00:18.00:70.00:35.00:24.00:18.00:0.00:1.00:1.00:0.00:0.00',
        'Stage-attached Shape blendMode should composite only the resolved node result instead of the full isolation canvas')
    assert_contains(graphics.calls, 'scissor:24.00:18.00:70.00:35.00',
        'Stage-attached Shape blendMode should restrict composite-back to the node result bounds')

    stage:destroy()
end

local function run_stage_attached_circle_shape_result_clip_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 180,
    })
    local shape = UI.CircleShape.new({
        tag = 'shape',
        x = 24,
        y = 18,
        width = 70,
        height = 35,
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

    assert_contains(graphics.calls, 'stencil:replace:1:true',
        'Non-rect Shape root compositing should push an internal result clip before composite-back')
    assert_contains(graphics.calls, 'stencil:replace:0:true',
        'Non-rect Shape root compositing should pop the internal result clip after composite-back')
    assert_not_contains(graphics.calls, 'stencil:increment:1:true',
        'Non-rect Shape root compositing should not double-count overlapping fill and stroke coverage in the result clip')
    assert_contains(graphics.calls, 'draw:canvas-1:0.00:0.00:0.00:1.00:1.00:0.00:0.00',
        'Non-rect Shape root compositing should draw the isolated target through the internal result clip')
    assert_not_contains(graphics.calls, 'draw_quad:canvas-1:24.00:18.00:70.00:35.00:24.00:18.00:0.00:1.00:1.00:0.00:0.00',
        'Non-rect Shape root compositing should not fall back to rectangular composite-back')
    assert_occurs_at_least(graphics.calls, 'polygon:fill:64', 3,
        'Non-rect Shape root compositing should render the circle fill plus the outer clip geometry during push and pop')
    assert_occurs_at_least(graphics.calls, 'line:', 1,
        'Non-rect Shape root compositing should still render the visible stroke into the isolated target')

    stage:destroy()
end

local function run_stage_attached_stroke_only_circle_shape_result_clip_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 180,
    })
    local shape = UI.CircleShape.new({
        tag = 'shape',
        x = 24,
        y = 18,
        width = 70,
        height = 70,
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

    assert_contains(graphics.calls, 'stencil:replace:1:true',
        'Stroke-only CircleShape root compositing should push an outer clip region before composite-back')
    assert_occurs_at_least(graphics.calls, 'stencil:replace:0:true', 2,
        'Stroke-only CircleShape root compositing should punch the inner hole and restore the clip on pop')
    assert_occurs_at_least(graphics.calls, 'polygon:fill:64', 3,
        'Stroke-only CircleShape root compositing should draw outer and inner clip fills instead of a stroked stencil mask')
    assert_contains(graphics.calls, 'draw:canvas-1:0.00:0.00:0.00:1.00:1.00:0.00:0.00',
        'Stroke-only CircleShape root compositing should still composite the isolated target through the internal clip')

    stage:destroy()
end

local function run_stage_attached_dashed_circle_shape_result_clip_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 180,
    })
    local shape = UI.CircleShape.new({
        tag = 'shape',
        x = 24,
        y = 18,
        width = 70,
        height = 35,
        fillOpacity = 0,
        strokeColor = { 1, 0, 0, 1 },
        strokeWidth = 6,
        strokePattern = 'dashed',
        strokeDashLength = 7,
        strokeGapLength = 5,
        strokeDashOffset = 3,
        blendMode = 'screen',
    })
    local graphics = make_fake_graphics()

    stage.baseSceneLayer:addChild(shape)
    stage:update()

    shape:_draw_subtree(graphics, function(node)
        node:draw(graphics)
    end)

    assert_contains(graphics.calls, 'stencil:replace:1:true',
        'Dashed CircleShape root compositing should push the internal result clip before composite-back')
    assert_not_contains(graphics.calls, 'new_shader:root-compositor-alpha-clip',
        'Dashed CircleShape root compositing should stay on geometry-driven result clipping')
    assert_occurs_at_least(graphics.calls, 'line:', 3,
        'Dashed CircleShape root compositing should reuse line-based stroke geometry across draw, push, and pop')

    stage:destroy()
end

local function run_stage_attached_rect_shape_stroke_result_clip_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 180,
    })
    local shape = UI.RectShape.new({
        tag = 'shape',
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

    assert_contains(graphics.calls, 'stencil:replace:1:true',
        'RectShape with outward stroke extent should push an internal result clip before composite-back')
    assert_contains(graphics.calls, 'draw:canvas-1:0.00:0.00:0.00:1.00:1.00:0.00:0.00',
        'RectShape with outward stroke extent should composite back through the internal result clip')
    assert_not_contains(graphics.calls, 'draw_quad:canvas-1:24.00:18.00:70.00:35.00:24.00:18.00:0.00:1.00:1.00:0.00:0.00',
        'RectShape with outward stroke extent should not crop composite-back to the fill bounds rectangle')

    stage:destroy()
end

local function run()
    run_direct_shape_opacity_tests()
    run_motion_shape_opacity_tests()
    run_shape_root_shader_and_blend_mode_tests()
    run_shape_default_root_compositing_fast_path_tests()
    run_shape_shader_capability_failure_tests()
    run_zero_opacity_targeting_tests()
    run_stage_attached_shape_blend_mode_bounds_tests()
    run_stage_attached_circle_shape_result_clip_tests()
    run_stage_attached_stroke_only_circle_shape_result_clip_tests()
    run_stage_attached_dashed_circle_shape_result_clip_tests()
    run_stage_attached_rect_shape_stroke_result_clip_tests()
end

return {
    run = run,
}
