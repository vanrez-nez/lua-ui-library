local UI = require('lib.ui')

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
    end
end

local function assert_same(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected same reference', 2)
    end
end

local function assert_true(value, message)
    if not value then
        error(message, 2)
    end
end

local function assert_near(actual, expected, tolerance, message)
    tolerance = tolerance or 0.01

    if math.abs(actual - expected) > tolerance then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
    end
end

local function assert_error(fn, needle, message)
    local ok, err = pcall(fn)
    if ok then
        error(message .. ': expected an error', 2)
    end

    local text = tostring(err)
    if needle ~= nil and not text:find(needle, 1, true) then
        error(message .. ': expected error containing "' .. needle ..
            '", got "' .. text .. '"', 2)
    end
end

local function find_call(calls, predicate)
    for index = 1, #calls do
        if predicate(calls[index]) then
            return calls[index], index
        end
    end

    return nil, nil
end

local function collect_calls(calls, predicate)
    local matches = {}

    for index = 1, #calls do
        if predicate(calls[index]) then
            matches[#matches + 1] = calls[index]
        end
    end

    return matches
end

local function copy_points(points)
    local copy = {}

    for index = 1, #points do
        copy[index] = points[index]
    end

    return copy
end

local function copy_vertices(vertices)
    local copy = {}

    for index = 1, #vertices do
        copy[index] = copy_points(vertices[index])
    end

    return copy
end

local function make_texture(width, height)
    local source = {
        width = width,
        height = height,
    }

    return UI.Texture.new({
        source = source,
        width = width,
        height = height,
    }), source
end

local function make_fake_graphics(opts)
    opts = opts or {}

    local graphics = {
        calls = {},
        color = opts.color or { 0.25, 0.5, 0.75, 0.9 },
        line_width = 1,
        line_style = 'smooth',
        line_join = 'none',
        miter_limit = 4,
        current_scissor = nil,
        stencil_compare = opts.stencil_compare,
        stencil_value = opts.stencil_value,
        current_canvas = nil,
        current_shader = nil,
        current_blend_mode = 'alpha',
        current_alpha_mode = 'alphamultiply',
        next_canvas_id = 1,
    }

    function graphics.getColor()
        return graphics.color[1], graphics.color[2], graphics.color[3], graphics.color[4]
    end

    function graphics.setColor(r, g, b, a)
        graphics.color = { r, g, b, a }
        graphics.calls[#graphics.calls + 1] = {
            kind = 'color',
            r = r,
            g = g,
            b = b,
            a = a,
        }
    end

    function graphics.getStencilTest()
        return graphics.stencil_compare, graphics.stencil_value
    end

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
            graphics.calls[#graphics.calls + 1] = {
                kind = 'scissor',
                x = nil,
                y = nil,
                width = nil,
                height = nil,
            }
            return
        end

        graphics.current_scissor = {
            x = x,
            y = y,
            width = width,
            height = height,
        }
        graphics.calls[#graphics.calls + 1] = {
            kind = 'scissor',
            x = x,
            y = y,
            width = width,
            height = height,
        }
    end

    function graphics.setStencilTest(compare, value)
        graphics.stencil_compare = compare
        graphics.stencil_value = value
        graphics.calls[#graphics.calls + 1] = {
            kind = 'stencil_test',
            compare = compare,
            value = value,
        }
    end

    function graphics.stencil(callback, action, value, keepvalues)
        graphics.calls[#graphics.calls + 1] = {
            kind = 'stencil',
            action = action,
            value = value,
            keepvalues = keepvalues,
        }
        callback()
    end

    function graphics.getLineWidth()
        return graphics.line_width
    end

    function graphics.setLineWidth(value)
        graphics.line_width = value
        graphics.calls[#graphics.calls + 1] = {
            kind = 'line_width',
            value = value,
        }
    end

    function graphics.getLineStyle()
        return graphics.line_style
    end

    function graphics.setLineStyle(value)
        graphics.line_style = value
        graphics.calls[#graphics.calls + 1] = {
            kind = 'line_style',
            value = value,
        }
    end

    function graphics.getLineJoin()
        return graphics.line_join
    end

    function graphics.setLineJoin(value)
        graphics.line_join = value
        graphics.calls[#graphics.calls + 1] = {
            kind = 'line_join',
            value = value,
        }
    end

    function graphics.getMiterLimit()
        return graphics.miter_limit
    end

    function graphics.setMiterLimit(value)
        graphics.miter_limit = value
        graphics.calls[#graphics.calls + 1] = {
            kind = 'miter_limit',
            value = value,
        }
    end

    function graphics.polygon(mode, points)
        graphics.calls[#graphics.calls + 1] = {
            kind = 'polygon',
            mode = tostring(mode),
            points = copy_points(points),
        }
    end

    function graphics.line(x1, y1, x2, y2)
        graphics.calls[#graphics.calls + 1] = {
            kind = 'line',
            x1 = x1,
            y1 = y1,
            x2 = x2,
            y2 = y2,
        }
    end

    function graphics.newCanvas(width, height)
        local canvas = {
            id = 'canvas-' .. tostring(graphics.next_canvas_id),
            width = width,
            height = height,
        }

        graphics.next_canvas_id = graphics.next_canvas_id + 1
        graphics.calls[#graphics.calls + 1] = {
            kind = 'new_canvas',
            canvas = canvas,
            width = width,
            height = height,
        }

        return canvas
    end

    function graphics.getCanvas()
        return graphics.current_canvas
    end

    function graphics.setCanvas(canvas)
        graphics.current_canvas = canvas
        graphics.calls[#graphics.calls + 1] = {
            kind = 'set_canvas',
            canvas = canvas,
        }
    end

    function graphics.clear()
        graphics.calls[#graphics.calls + 1] = {
            kind = 'clear',
        }
    end

    function graphics.origin()
        graphics.calls[#graphics.calls + 1] = {
            kind = 'origin',
        }
    end

    function graphics.getShader()
        return graphics.current_shader
    end

    function graphics.setShader(shader)
        graphics.current_shader = shader
        graphics.calls[#graphics.calls + 1] = {
            kind = 'shader',
            shader = shader,
        }
    end

    function graphics.getBlendMode()
        return graphics.current_blend_mode, graphics.current_alpha_mode
    end

    function graphics.setBlendMode(mode, alpha_mode)
        graphics.current_blend_mode = mode
        if alpha_mode ~= nil then
            graphics.current_alpha_mode = alpha_mode
        end
        graphics.calls[#graphics.calls + 1] = {
            kind = 'blend_mode',
            mode = mode,
            alpha_mode = graphics.current_alpha_mode,
        }
    end

    if opts.disable_new_mesh ~= true then
        function graphics.newMesh(format, vertices, mode, usage)
            if opts.mesh_returns_nil == true then
                return nil
            end

            local mesh = {
                format = format,
                vertices = copy_vertices(vertices),
                mode = mode,
                usage = usage,
                texture = nil,
            }

            if opts.mesh_has_set_texture ~= false then
                function mesh:setTexture(texture)
                    self.texture = texture
                end
            end

            graphics.calls[#graphics.calls + 1] = {
                kind = 'new_mesh',
                mesh = mesh,
            }

            return mesh
        end
    end

    function graphics.draw(target, ...)
        if opts.draw_error ~= nil then
            error(opts.draw_error, 0)
        end

        graphics.calls[#graphics.calls + 1] = {
            kind = 'draw',
            target = target,
            args = { ... },
        }
    end

    return graphics
end

local function build_expected_circle_points(shape, segments)
    local points = {}
    local bounds = shape:getLocalBounds()
    local radius_x = bounds.width / 2
    local radius_y = bounds.height / 2
    local center_x = bounds.x + radius_x
    local center_y = bounds.y + radius_y

    for index = 0, segments - 1 do
        local angle = (-math.pi / 2) + ((index / segments) * (math.pi * 2))
        local world_x, world_y = shape:localToWorld(
            center_x + math.cos(angle) * radius_x,
            center_y + math.sin(angle) * radius_y
        )
        points[#points + 1] = world_x
        points[#points + 1] = world_y
    end

    return points
end

local function run_flat_color_fast_path_tests()
    local shape = UI.RectShape.new({
        x = 2,
        y = 3,
        width = 20,
        height = 10,
        fillColor = { 0.2, 0.4, 0.6, 0.5 },
        fillOpacity = 0.4,
    })
    local graphics = make_fake_graphics()

    shape:draw(graphics)

    local stencil_call = find_call(graphics.calls, function(call)
        return call.kind == 'stencil'
    end)
    local mesh_call = find_call(graphics.calls, function(call)
        return call.kind == 'new_mesh'
    end)
    local draw_call = find_call(graphics.calls, function(call)
        return call.kind == 'draw'
    end)
    local fill_call = find_call(graphics.calls, function(call)
        return call.kind == 'polygon' and call.mode == 'fill'
    end)

    assert_true(stencil_call == nil,
        'Flat-color shape fill should not allocate stencil work on the fast path')
    assert_true(mesh_call == nil,
        'Flat-color shape fill should not allocate meshes on the fast path')
    assert_true(draw_call == nil,
        'Flat-color shape fill should not invoke the mesh draw path on the fast path')
    assert_true(fill_call ~= nil,
        'Flat-color shape fill should still draw the shape polygon directly')
end

local function run_gradient_fill_and_order_tests()
    local shape = UI.RectShape.new({
        x = 5,
        y = 7,
        width = 20,
        height = 10,
        fillOpacity = 0.4,
        fillGradient = {
            kind = 'linear',
            direction = 'horizontal',
            colors = {
                { 1, 0, 0, 1 },
                { 0, 0, 1, 0.5 },
            },
        },
        strokeColor = { 0, 1, 0, 1 },
        strokeWidth = 2,
    })
    local graphics = make_fake_graphics()

    shape:draw(graphics)

    local clip_call, clip_index = find_call(graphics.calls, function(call)
        return call.kind == 'polygon' and call.mode == 'fill'
    end)
    local mesh_call = find_call(graphics.calls, function(call)
        return call.kind == 'new_mesh'
    end)
    local draw_call, draw_index = find_call(graphics.calls, function(call)
        return call.kind == 'draw'
    end)
    local stroke_call, stroke_index = find_call(graphics.calls, function(call)
        return call.kind == 'polygon' and call.mode == 'line'
    end)
    local vertices = mesh_call.mesh.vertices

    assert_true(clip_call ~= nil,
        'Gradient-backed shape fill should stencil the silhouette polygon before drawing')
    assert_true(mesh_call ~= nil,
        'Gradient-backed shape fill should build a mesh over the local bounds AABB')
    assert_true(draw_call ~= nil,
        'Gradient-backed shape fill should draw the generated mesh')
    assert_true(stroke_call ~= nil,
        'Gradient-backed shape fill should still draw stroke afterward')
    assert_true(clip_index < draw_index and draw_index < stroke_index,
        'Shape fill rendering should clip and draw fill before stroke')
    assert_equal(#vertices, 6,
        'A two-stop linear gradient should emit one rectangle worth of mesh triangles')
    assert_near(vertices[1][1], 5, 0.01,
        'Gradient mesh should begin at the local-bounds left edge in world space')
    assert_near(vertices[1][2], 7, 0.01,
        'Gradient mesh should begin at the local-bounds top edge in world space')
    assert_near(vertices[3][1], 25, 0.01,
        'Gradient mesh should end at the local-bounds right edge in world space')
    assert_near(vertices[2][2], 17, 0.01,
        'Gradient mesh should span the full local-bounds height in world space')
    assert_near(vertices[1][6], 0.4, 0.001,
        'Gradient mesh should multiply stop alpha by fillOpacity at the leading edge')
    assert_near(vertices[3][6], 0.2, 0.001,
        'Gradient mesh should multiply stop alpha by fillOpacity at the trailing edge')
    assert_equal(graphics.stencil_compare, nil,
        'Gradient-backed shape fill should restore stencil compare after drawing')
    assert_equal(graphics.stencil_value, nil,
        'Gradient-backed shape fill should restore stencil value after drawing')
end

local function run_texture_fill_tiling_tests()
    local texture, texture_source = make_texture(64, 32)
    local sprite = UI.Sprite.new({
        texture = texture,
        region = {
            x = 8,
            y = 4,
            width = 16,
            height = 12,
        },
    })
    local shape = UI.RectShape.new({
        width = 32,
        height = 12,
        fillTexture = sprite,
        fillRepeatX = true,
        fillAlignX = 'start',
        fillAlignY = 'start',
    })
    local graphics = make_fake_graphics()

    shape:draw(graphics)

    local mesh_calls = collect_calls(graphics.calls, function(call)
        return call.kind == 'new_mesh'
    end)
    local draw_calls = collect_calls(graphics.calls, function(call)
        return call.kind == 'draw'
    end)
    local first_mesh = mesh_calls[1].mesh
    local first_vertices = first_mesh.vertices

    assert_equal(#mesh_calls, 2,
        'Texture-backed tiled shape fill should emit one mesh per covering tile')
    assert_equal(#draw_calls, 2,
        'Texture-backed tiled shape fill should draw every emitted tile mesh')
    assert_same(first_mesh.texture, texture_source,
        'Texture-backed tiled shape fill should bind the underlying drawable resource to the mesh')
    assert_same(draw_calls[1].target, first_mesh,
        'Texture-backed tiled shape fill should draw the mesh object it created')
    assert_near(first_vertices[1][1], 0, 0.01,
        'Texture-backed tiled shape fill should position the first tile at the local-bounds start edge')
    assert_near(first_vertices[2][1], 16, 0.01,
        'Texture-backed tiled shape fill should preserve intrinsic sprite width in tiling mode')
    assert_near(first_vertices[6][2], 12, 0.01,
        'Texture-backed tiled shape fill should preserve intrinsic sprite height in tiling mode')
    assert_near(first_vertices[1][3], 8 / 64, 0.0001,
        'Texture-backed tiled shape fill should map sprite region u0 into mesh UVs')
    assert_near(first_vertices[1][4], 4 / 32, 0.0001,
        'Texture-backed tiled shape fill should map sprite region v0 into mesh UVs')
    assert_near(first_vertices[2][3], 24 / 64, 0.0001,
        'Texture-backed tiled shape fill should map sprite region u1 into mesh UVs')
    assert_near(first_vertices[6][4], 16 / 32, 0.0001,
        'Texture-backed tiled shape fill should map sprite region v1 into mesh UVs')
end

local function run_circle_silhouette_clip_tests()
    local shape = UI.CircleShape.new({
        x = 10,
        y = 20,
        width = 40,
        height = 20,
        fillGradient = {
            kind = 'linear',
            direction = 'vertical',
            colors = {
                '#112233',
                '#445566',
            },
        },
    })
    local graphics = make_fake_graphics()

    shape:draw(graphics)

    local clip_call = find_call(graphics.calls, function(call)
        return call.kind == 'polygon' and call.mode == 'fill'
    end)
    local draw_call = find_call(graphics.calls, function(call)
        return call.kind == 'draw'
    end)
    local expected_points = build_expected_circle_points(shape, 32)

    assert_true(clip_call ~= nil,
        'Non-rect shape fill should write the concrete silhouette into stencil before drawing fill')
    assert_true(draw_call ~= nil,
        'Non-rect shape fill should still render through the shared non-flat fill pipeline')
    assert_equal(#clip_call.points, #expected_points,
        'Non-rect shape silhouette clipping should use the full concrete world-point outline')

    for index = 1, #expected_points do
        assert_near(clip_call.points[index], expected_points[index], 0.01,
            'Non-rect shape silhouette clipping should use the transformed local outline at point ' .. index)
    end
end

local function run_renderer_failure_tests()
    local gradient_shape = UI.RectShape.new({
        width = 20,
        height = 10,
        fillGradient = {
            kind = 'linear',
            direction = 'horizontal',
            colors = {
                '#ff0000',
                '#00ff00',
            },
        },
        fillColor = '#0000ff',
    })
    local unsupported_graphics = make_fake_graphics({
        disable_new_mesh = true,
    })

    assert_error(function()
        gradient_shape:draw(unsupported_graphics)
    end, 'Unsupported shape fill renderer path for fillGradient',
        'Active gradient fill should fail hard when the renderer cannot provide a clipped non-flat fill path')

    local texture = select(1, make_texture(64, 32))
    local sprite = UI.Sprite.new({
        texture = texture,
        region = {
            x = 8,
            y = 4,
            width = 16,
            height = 12,
        },
    })
    local texture_shape = UI.RectShape.new({
        width = 16,
        height = 12,
        fillTexture = sprite,
    })
    local no_texture_binding_graphics = make_fake_graphics({
        mesh_has_set_texture = false,
    })

    assert_error(function()
        texture_shape:draw(no_texture_binding_graphics)
    end, 'Unsupported shape fill renderer path for fillTexture: mesh texture binding is unavailable',
        'Active texture fill should fail hard when the renderer cannot bind texture data to the mesh path')
end

local function run_unusable_texture_source_tests()
    local texture = select(1, make_texture(16, 12))
    local shape = UI.RectShape.new({
        width = 16,
        height = 12,
        fillTexture = texture,
        fillColor = '#00ff00',
    })
    local graphics = make_fake_graphics()

    rawset(texture, 'source', nil)

    assert_error(function()
        shape:draw(graphics)
    end, 'Active fillTexture source is unusable at draw time',
        'Active texture fill should fail hard when the previously valid source becomes unusable at draw time')
end

local function run_state_restore_on_draw_failure_tests()
    local shape = UI.RectShape.new({
        width = 20,
        height = 10,
        fillGradient = {
            kind = 'linear',
            direction = 'horizontal',
            colors = {
                '#ff0000',
                '#00ff00',
            },
        },
    })
    local graphics = make_fake_graphics({
        stencil_compare = 'equal',
        stencil_value = 7,
        draw_error = 'mesh exploded',
    })

    assert_error(function()
        shape:draw(graphics)
    end, 'mesh exploded',
        'Shape fill renderer should surface draw failures from the active mesh path')
    assert_equal(graphics.stencil_compare, 'equal',
        'Shape fill renderer should restore stencil compare after a clipped fill draw failure')
    assert_equal(graphics.stencil_value, 7,
        'Shape fill renderer should restore stencil value after a clipped fill draw failure')
    assert_near(graphics.color[1], 0.25, 0.001,
        'Shape fill renderer should restore color state after a clipped fill draw failure')
    assert_near(graphics.color[4], 0.9, 0.001,
        'Shape fill renderer should restore alpha state after a clipped fill draw failure')
end

local function run_root_compositing_after_local_fill_tests()
    local shape = UI.RectShape.new({
        width = 20,
        height = 10,
        fillOpacity = 0.5,
        fillGradient = {
            kind = 'linear',
            direction = 'horizontal',
            colors = {
                '#ff0000',
                '#00ff00',
            },
        },
        strokeColor = '#0000ff',
        strokeWidth = 2,
        opacity = 0.6,
        shader = { id = 'shape-fx' },
        blendMode = 'screen',
    })
    local graphics = make_fake_graphics()

    shape:_draw_subtree(graphics, function(node)
        node:draw(graphics)
    end)

    local fill_clip_index = select(2, find_call(graphics.calls, function(call)
        return call.kind == 'polygon' and call.mode == 'fill'
    end))
    local mesh_draw_index = select(2, find_call(graphics.calls, function(call)
        return call.kind == 'draw' and type(call.target) == 'table' and call.target.usage == 'static'
    end))
    local stroke_index = select(2, find_call(graphics.calls, function(call)
        return call.kind == 'polygon' and call.mode == 'line'
    end))
    local opacity_index = select(2, find_call(graphics.calls, function(call)
        return call.kind == 'color' and math.abs((call.a or 0) - 0.6) <= 0.0001
    end))
    local shader_index = select(2, find_call(graphics.calls, function(call)
        return call.kind == 'shader' and call.shader ~= nil and call.shader.id == 'shape-fx'
    end))
    local blend_index = select(2, find_call(graphics.calls, function(call)
        return call.kind == 'blend_mode' and call.mode == 'screen'
    end))
    local canvas_draw_index = select(2, find_call(graphics.calls, function(call)
        return call.kind == 'draw' and type(call.target) == 'table' and call.target.id == 'canvas-1'
    end))

    assert_true(fill_clip_index ~= nil and mesh_draw_index ~= nil and stroke_index ~= nil,
        'Shape root compositing acceptance should still draw the full local fill-and-stroke result into the isolated target first')
    assert_true(opacity_index ~= nil and shader_index ~= nil and blend_index ~= nil and canvas_draw_index ~= nil,
        'Shape root compositing acceptance should apply opacity, shader, and blend state during canvas composite-back')
    assert_true(fill_clip_index < mesh_draw_index and mesh_draw_index < stroke_index,
        'Shape local fill should resolve before stroke inside the isolated target')
    assert_true(stroke_index < opacity_index and stroke_index < shader_index and stroke_index < blend_index,
        'Root compositing effects should be applied only after local fill and stroke resolution is complete')
    assert_true(opacity_index < canvas_draw_index and shader_index < canvas_draw_index and blend_index < canvas_draw_index,
        'Root compositing effects should be installed before the isolated result is drawn back into the parent target')
end

local M = {}

function M.run()
    run_flat_color_fast_path_tests()
    run_gradient_fill_and_order_tests()
    run_texture_fill_tiling_tests()
    run_circle_silhouette_clip_tests()
    run_renderer_failure_tests()
    run_unusable_texture_source_tests()
    run_state_restore_on_draw_failure_tests()
    run_root_compositing_after_local_fill_tests()
end

return M
