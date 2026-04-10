local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Rectangle = require('lib.ui.core.rectangle')
local CanvasPool = require('lib.ui.render.canvas_pool')
local GraphicsState = require('lib.ui.render.graphics_state')
local GraphicsValidation = require('lib.ui.render.graphics_validation')

local ceil = math.ceil
local cos = math.cos
local max = math.max
local sin = math.sin

local RootCompositor = {}

local EMPTY_ROOT_COMPOSITING_CAPABILITIES = {
    opacity = false,
    shader = false,
    blendMode = false,
}

local EMPTY_COMPOSITING_EXTRAS = {
    mask = nil,
    translationX = 0,
    translationY = 0,
    scaleX = 1,
    scaleY = 1,
    rotation = 0,
}

local canvas_pools = setmetatable({}, { __mode = 'k' })
local root_compositing_capability_cache = setmetatable({}, { __mode = 'k' })

local function walk_class_hierarchy(class, key)
    local current = class

    while current do
        local value = rawget(current, key)
        if value ~= nil then
            return value
        end

        current = rawget(current, 'super')
    end

    return nil
end

local function normalize_root_compositing_capabilities(declared)
    if not Types.is_table(declared) then
        return EMPTY_ROOT_COMPOSITING_CAPABILITIES
    end

    local capabilities = {
        opacity = declared.opacity == true,
        shader = declared.shader == true,
        blendMode = declared.blendMode == true,
    }

    if not capabilities.opacity and not capabilities.shader and not capabilities.blendMode then
        return EMPTY_ROOT_COMPOSITING_CAPABILITIES
    end

    return capabilities
end

local function get_class_root_compositing_capabilities(class)
    if not Types.is_table(class) then
        return EMPTY_ROOT_COMPOSITING_CAPABILITIES
    end

    local cached = root_compositing_capability_cache[class]
    if cached ~= nil then
        return cached
    end

    cached = normalize_root_compositing_capabilities(
        walk_class_hierarchy(class, '_root_compositing_capabilities')
    )
    root_compositing_capability_cache[class] = cached

    return cached
end

local function get_node_root_compositing_capabilities(node)
    return get_class_root_compositing_capabilities(getmetatable(node))
end

local function get_motion_surface_value(node, key)
    if not Types.is_table(node) then
        return nil
    end

    local state = rawget(node, '_motion_visual_state')
    if state == nil then
        return nil
    end

    return state[key]
end

local function get_canvas_pool(graphics)
    local pool = canvas_pools[graphics]

    if pool == nil then
        pool = CanvasPool.new({
            graphics = graphics,
        })
        canvas_pools[graphics] = pool
    end

    return pool
end

local function get_drawable_dimensions(drawable)
    if drawable == nil then
        return 0, 0
    end

    local width = nil
    local height = nil

    if Types.is_function(drawable.getWidth) then
        width = drawable:getWidth()
    elseif Types.is_number(drawable.width) then
        width = drawable.width
    end

    if Types.is_function(drawable.getHeight) then
        height = drawable:getHeight()
    elseif Types.is_number(drawable.height) then
        height = drawable.height
    end

    return width or 0, height or 0
end

local function create_source_quad(graphics, drawable, rect)
    if rect == nil or rect:is_empty() then
        return nil
    end

    local new_quad = nil

    if Types.is_function(graphics.newQuad) then
        new_quad = function(...)
            return graphics.newQuad(...)
        end
    elseif love ~= nil and love.graphics ~= nil and Types.is_function(love.graphics.newQuad) then
        new_quad = love.graphics.newQuad
    end

    if new_quad == nil then
        return nil
    end

    local source_width, source_height = get_drawable_dimensions(drawable)
    if source_width <= 0 or source_height <= 0 then
        return nil
    end

    return new_quad(
        rect.x,
        rect.y,
        rect.width,
        rect.height,
        source_width,
        source_height
    )
end

local function resolve_root_compositing_state(node, runtime)
    local capabilities = get_node_root_compositing_capabilities(node)
    if not (capabilities.opacity or capabilities.shader or capabilities.blendMode) then
        return nil
    end

    local get_effective_value = runtime.get_effective_value
    local opacity = nil

    if capabilities.opacity then
        opacity = get_motion_surface_value(node, 'opacity')
        if opacity == nil then
            opacity = get_effective_value(node, 'opacity')
        end
    end

    return GraphicsValidation.normalize_root_compositing_state({
        opacity = opacity,
        shader = capabilities.shader and get_effective_value(node, 'shader') or nil,
        blendMode = capabilities.blendMode and get_effective_value(node, 'blendMode') or nil,
    })
end

local function resolve_node_compositing_extras(node)
    local resolve_extras = node._resolve_root_compositing_extras

    if not Types.is_function(resolve_extras) then
        return nil
    end

    return node:_resolve_root_compositing_extras()
end

local function resolve_node_world_paint_bounds(node)
    local resolve_paint_bounds = node._resolve_root_compositing_world_paint_bounds

    if not Types.is_function(resolve_paint_bounds) then
        return node:getWorldBounds()
    end

    local bounds = node:_resolve_root_compositing_world_paint_bounds()

    if bounds == nil then
        return node:getWorldBounds()
    end

    if not Rectangle.is_rectangle(bounds) then
        Assert.fail('node root-compositing world paint bounds must resolve to a Rectangle', 3)
    end

    return bounds
end

local function resolve_node_result_clip(node)
    local resolve_result_clip = node._resolve_root_compositing_result_clip

    if not Types.is_function(resolve_result_clip) then
        return nil
    end

    return node:_resolve_root_compositing_result_clip()
end

function RootCompositor.resolve_node_plan(node, runtime)
    local root_compositing_state = resolve_root_compositing_state(node, runtime)
    local compositing_extras = resolve_node_compositing_extras(node)
    local result_clip = resolve_node_result_clip(node)

    if root_compositing_state == nil and compositing_extras == nil then
        return nil
    end

    return {
        root_compositing_state = root_compositing_state or
            GraphicsValidation.normalize_root_compositing_state(),
        compositing_extras = compositing_extras,
        result_clip = result_clip,
    }
end

local function compositing_extras_require_isolation(compositing_extras)
    if compositing_extras == nil then
        return false
    end

    return compositing_extras.mask ~= nil or
        compositing_extras.translationX ~= 0 or
        compositing_extras.translationY ~= 0 or
        compositing_extras.scaleX ~= 1 or
        compositing_extras.scaleY ~= 1 or
        compositing_extras.rotation ~= 0
end

function RootCompositor.plan_requires_isolation(compositing_plan)
    if compositing_plan == nil then
        return false
    end

    return not GraphicsValidation.is_default_root_compositing_state(
            compositing_plan.root_compositing_state
        ) or
        compositing_extras_require_isolation(compositing_plan.compositing_extras)
end

function RootCompositor.initialize_render_state(graphics, render_state)
    render_state = render_state or {}

    if render_state.composition_target_stack == nil then
        render_state.composition_target_stack = {
            GraphicsState.get_current_canvas(graphics),
        }
    end

    return render_state
end

local function ensure_composition_target_stack(render_state, graphics)
    render_state = RootCompositor.initialize_render_state(graphics, render_state)
    return render_state.composition_target_stack
end

local function peek_composition_target(render_state, graphics)
    local composition_target_stack = ensure_composition_target_stack(render_state, graphics)
    return composition_target_stack[#composition_target_stack]
end

local function push_composition_target(render_state, graphics, target)
    local composition_target_stack = ensure_composition_target_stack(render_state, graphics)
    composition_target_stack[#composition_target_stack + 1] = target
    return composition_target_stack
end

local function pop_composition_target(render_state, graphics)
    local composition_target_stack = ensure_composition_target_stack(render_state, graphics)
    local target = composition_target_stack[#composition_target_stack]
    composition_target_stack[#composition_target_stack] = nil
    return target
end

local function get_isolation_canvas_size(node, render_state, runtime, graphics)
    local target = peek_composition_target(render_state, graphics)
    local target_width, target_height = get_drawable_dimensions(target)

    if target_width > 0 and target_height > 0 then
        return max(1, ceil(target_width)), max(1, ceil(target_height))
    end

    local root = runtime.get_root(node)

    if rawget(root, '_ui_stage_instance') == true then
        return max(1, ceil(root.width or 0)),
            max(1, ceil(root.height or 0))
    end

    local bounds = resolve_node_world_paint_bounds(node)

    return max(1, ceil(max(bounds.width, bounds.x + bounds.width))),
        max(1, ceil(max(bounds.height, bounds.y + bounds.height)))
end

local function resolve_subtree_world_bounds(node, runtime)
    if not runtime.get_effective_value(node, 'visible') then
        return Rectangle(0, 0, 0, 0)
    end

    local bounds = resolve_node_world_paint_bounds(node)
    local clip_rect = nil

    if runtime.get_effective_value(node, 'clipChildren') then
        clip_rect = runtime.get_world_clip_rect(node)
        bounds = bounds:intersection(clip_rect)
    end

    local ordered_children = rawget(node, '_ordered_children') or rawget(node, '_children') or {}

    for index = 1, #ordered_children do
        local child_bounds = resolve_subtree_world_bounds(ordered_children[index], runtime)

        if clip_rect ~= nil then
            child_bounds = child_bounds:intersection(clip_rect)
        end

        bounds = bounds:union(child_bounds)
    end

    return bounds
end

local function transform_rect_point(x, y, pivot_x, pivot_y, translation_x, translation_y, rotation, scale_x, scale_y)
    local local_x = (x - pivot_x) * scale_x
    local local_y = (y - pivot_y) * scale_y

    if rotation ~= 0 then
        local rotated_x = (local_x * cos(rotation)) - (local_y * sin(rotation))
        local rotated_y = (local_x * sin(rotation)) + (local_y * cos(rotation))
        local_x = rotated_x
        local_y = rotated_y
    end

    return pivot_x + translation_x + local_x, pivot_y + translation_y + local_y
end

local function resolve_transformed_rect(rect, pivot_x, pivot_y, translation_x, translation_y, rotation, scale_x, scale_y)
    if rect == nil or rect:is_empty() then
        return Rectangle(0, 0, 0, 0)
    end

    if translation_x == 0 and translation_y == 0 and rotation == 0 and scale_x == 1 and scale_y == 1 then
        return rect:clone()
    end

    local left = rect.x
    local top = rect.y
    local right = rect.x + rect.width
    local bottom = rect.y + rect.height
    local x1, y1 = transform_rect_point(left, top, pivot_x, pivot_y, translation_x, translation_y, rotation, scale_x, scale_y)
    local x2, y2 = transform_rect_point(right, top, pivot_x, pivot_y, translation_x, translation_y, rotation, scale_x, scale_y)
    local x3, y3 = transform_rect_point(right, bottom, pivot_x, pivot_y, translation_x, translation_y, rotation, scale_x, scale_y)
    local x4, y4 = transform_rect_point(left, bottom, pivot_x, pivot_y, translation_x, translation_y, rotation, scale_x, scale_y)

    return Rectangle.bounding_box({
        { x = x1, y = y1 },
        { x = x2, y = y2 },
        { x = x3, y = y3 },
        { x = x4, y = y4 },
    })
end

local function draw_result_clip_outer(node, graphics, result_clip)
    if result_clip == nil then
        return
    end

    if result_clip.kind == 'stencil_mask' then
        if not Types.is_function(node._draw_root_compositing_result_clip) then
            Assert.fail('node result clip is missing its draw hook', 3)
        end

        node:_draw_root_compositing_result_clip(graphics)
        return
    end

    if result_clip.kind == 'stencil_region' then
        if not Types.is_function(node._draw_root_compositing_result_clip_outer) then
            Assert.fail('node result clip is missing its outer draw hook', 3)
        end

        node:_draw_root_compositing_result_clip_outer(graphics)
        return
    end

    Assert.fail('unsupported root compositing result clip kind: ' .. tostring(result_clip.kind), 3)
end

local function draw_result_clip_inner(node, graphics, result_clip)
    if result_clip == nil or result_clip.kind ~= 'stencil_region' or result_clip.exclude_inner ~= true then
        return
    end

    if not Types.is_function(node._draw_root_compositing_result_clip_inner) then
        Assert.fail('node result clip is missing its inner draw hook', 3)
    end

    node:_draw_root_compositing_result_clip_inner(graphics)
end

local function push_result_clip(node, graphics, result_clip, clip_state)
    if result_clip == nil then
        return nil
    end

    if not Types.is_function(graphics.stencil) then
        Assert.fail('graphics adapter must support stencil for root result clipping', 3)
    end

    local previous_compare = clip_state.stencil_compare
    local previous_value = clip_state.stencil_value
    local next_value = (previous_value or 0) + 1

    GraphicsState.set_stencil_test(graphics, previous_compare, previous_value)
    graphics.stencil(function()
        draw_result_clip_outer(node, graphics, result_clip)
    end, 'replace', next_value, true)

    if result_clip.kind == 'stencil_region' and result_clip.exclude_inner == true then
        GraphicsState.set_stencil_test(graphics, 'equal', next_value)
        graphics.stencil(function()
            draw_result_clip_inner(node, graphics, result_clip)
        end, 'replace', previous_value or 0, true)
    end

    GraphicsState.set_stencil_test(graphics, 'equal', next_value)

    return {
        previous_compare = previous_compare,
        previous_value = previous_value,
        restore_value = previous_value or 0,
        value = next_value,
    }
end

local function pop_result_clip(node, graphics, result_clip, result_clip_state)
    if result_clip == nil or result_clip_state == nil then
        return
    end

    GraphicsState.set_stencil_test(graphics, 'equal', result_clip_state.value)
    graphics.stencil(function()
        draw_result_clip_outer(node, graphics, result_clip)
    end, 'replace', result_clip_state.restore_value, true)
    GraphicsState.set_stencil_test(
        graphics,
        result_clip_state.previous_compare,
        result_clip_state.previous_value
    )
end

local function apply_canvas_composite_color(graphics, opacity)
    if not Types.is_function(graphics.setColor) then
        return
    end

    opacity = opacity ~= nil and opacity or GraphicsValidation.ROOT_OPACITY_DEFAULT
    graphics.setColor(opacity, opacity, opacity, opacity)
end

local function apply_canvas_composite_blend_mode(graphics, root_compositing_state, previous_blend_mode)
    if not Types.is_function(graphics.setBlendMode) then
        return
    end

    local blend_mode = root_compositing_state.blendMode

    if blend_mode == GraphicsValidation.ROOT_BLEND_MODE_DEFAULT then
        if previous_blend_mode == nil then
            return
        end

        blend_mode = previous_blend_mode[1]
    end

    GraphicsState.set_blend_mode(graphics, blend_mode, 'premultiplied')
end

local function composite_isolated_subtree(node, graphics, canvas, compositing_plan, clip_state, runtime)
    local root_compositing_state = compositing_plan.root_compositing_state
    local compositing_extras = compositing_plan.compositing_extras or EMPTY_COMPOSITING_EXTRAS
    local result_clip = compositing_plan.result_clip

    if compositing_extras.mask ~= nil then
        Assert.fail(
            'mask rendering is not implemented by the current retained render path',
            3
        )
    end

    if root_compositing_state.shader ~= nil and not Types.is_function(graphics.setShader) then
        Assert.fail('graphics adapter must support setShader for root shader compositing', 3)
    end

    if root_compositing_state.blendMode ~= GraphicsValidation.ROOT_BLEND_MODE_DEFAULT and (
        not Types.is_function(graphics.setBlendMode) or
        not Types.is_function(graphics.getBlendMode)
    ) then
        Assert.fail('graphics adapter must support blend-mode save/restore for root compositing', 3)
    end

    if not Types.is_function(graphics.draw) then
        Assert.fail('graphics adapter must support draw for isolated root compositing', 3)
    end

    local previous_color = GraphicsState.get_current_color(graphics)
    local previous_shader = GraphicsState.get_current_shader(graphics)
    local previous_blend_mode = GraphicsState.get_current_blend_mode(graphics)

    GraphicsState.set_scissor_rect(graphics, clip_state.scissor)
    GraphicsState.set_stencil_test(graphics, clip_state.stencil_compare, clip_state.stencil_value)

    local draw_x = compositing_extras.translationX
    local draw_y = compositing_extras.translationY
    local rotation = compositing_extras.rotation
    local scale_x = compositing_extras.scaleX
    local scale_y = compositing_extras.scaleY
    local source_bounds = resolve_subtree_world_bounds(node, runtime)
    local result_clip_state = nil

    if source_bounds:is_empty() then
        GraphicsState.restore_blend_mode(graphics, previous_blend_mode)
        GraphicsState.restore_shader(graphics, previous_shader)
        GraphicsState.restore_color(graphics, previous_color)
        return nil
    end

    if result_clip ~= nil and (
        draw_x ~= 0 or draw_y ~= 0 or rotation ~= 0 or scale_x ~= 1 or scale_y ~= 1
    ) then
        Assert.fail('root result clipping does not support compositing motion transforms', 3)
    end

    if result_clip ~= nil then
        if Types.is_function(graphics.setShader) then
            graphics.setShader()
        end

        if Types.is_function(graphics.setColor) then
            graphics.setColor(1, 1, 1, 1)
        end

        result_clip_state = push_result_clip(node, graphics, result_clip, clip_state)
    end

    apply_canvas_composite_color(graphics, root_compositing_state.opacity)

    if root_compositing_state.shader ~= nil then
        graphics.setShader(root_compositing_state.shader)
    end

    apply_canvas_composite_blend_mode(graphics, root_compositing_state, previous_blend_mode)

    if result_clip ~= nil then
        GraphicsState.set_scissor_rect(graphics, clip_state.scissor)
        graphics.draw(canvas, 0, 0)
        GraphicsState.restore_blend_mode(graphics, previous_blend_mode)
        GraphicsState.restore_shader(graphics, previous_shader)
        GraphicsState.restore_color(graphics, previous_color)
        pop_result_clip(node, graphics, result_clip, result_clip_state)
        return nil
    end

    local source_quad = create_source_quad(graphics, canvas, source_bounds)
    local destination_bounds = source_bounds

    if draw_x ~= 0 or draw_y ~= 0 or rotation ~= 0 or scale_x ~= 1 or scale_y ~= 1 then
        local bounds = rawget(node, '_local_bounds_cache') or node:getLocalBounds()
        local pivot_x = (runtime.get_effective_value(node, 'pivotX') or 0.5) * bounds.width
        local pivot_y = (runtime.get_effective_value(node, 'pivotY') or 0.5) * bounds.height
        local world_pivot_x, world_pivot_y = node:localToWorld(pivot_x, pivot_y)
        local pivot_offset_x = world_pivot_x - source_bounds.x
        local pivot_offset_y = world_pivot_y - source_bounds.y
        local composite_scissor = clip_state.scissor

        destination_bounds = resolve_transformed_rect(
            source_bounds,
            world_pivot_x,
            world_pivot_y,
            draw_x,
            draw_y,
            rotation,
            scale_x,
            scale_y
        )

        if composite_scissor ~= nil then
            composite_scissor = composite_scissor:intersection(destination_bounds)
        else
            composite_scissor = destination_bounds
        end
        GraphicsState.set_scissor_rect(graphics, composite_scissor)

        if source_quad ~= nil then
            graphics.draw(
                canvas,
                source_quad,
                world_pivot_x + draw_x,
                world_pivot_y + draw_y,
                rotation,
                scale_x,
                scale_y,
                pivot_offset_x,
                pivot_offset_y
            )
        else
            graphics.draw(
                canvas,
                world_pivot_x + draw_x,
                world_pivot_y + draw_y,
                rotation,
                scale_x,
                scale_y,
                world_pivot_x,
                world_pivot_y
            )
        end
    else
        local composite_scissor = clip_state.scissor

        if composite_scissor ~= nil then
            composite_scissor = composite_scissor:intersection(destination_bounds)
        else
            composite_scissor = destination_bounds
        end
        GraphicsState.set_scissor_rect(graphics, composite_scissor)

        if source_quad ~= nil then
            graphics.draw(canvas, source_quad, source_bounds.x, source_bounds.y)
        else
            graphics.draw(canvas, 0, 0)
        end
    end

    GraphicsState.restore_blend_mode(graphics, previous_blend_mode)
    GraphicsState.restore_shader(graphics, previous_shader)
    GraphicsState.restore_color(graphics, previous_color)
end

function RootCompositor.draw_isolated_subtree(node, graphics, draw_callback, clip_state, render_state, compositing_plan, runtime)
    if not Types.is_function(graphics.newCanvas) or
        not Types.is_function(graphics.setCanvas) or
        not Types.is_function(graphics.draw) then
        Assert.fail(
            'graphics adapter must support canvas isolation for retained root compositing',
            3
        )
    end

    render_state = RootCompositor.initialize_render_state(graphics, render_state)

    local pool = get_canvas_pool(graphics)
    local canvas_width, canvas_height = get_isolation_canvas_size(node, render_state, runtime, graphics)
    local canvas = pool:acquire(canvas_width, canvas_height)
    local previous_canvas = peek_composition_target(render_state, graphics)
    local previous_color = GraphicsState.get_current_color(graphics)
    local previous_shader = GraphicsState.get_current_shader(graphics)
    local previous_blend_mode = GraphicsState.get_current_blend_mode(graphics)
    local previous_scissor = GraphicsState.get_scissor_rect(graphics)
    local previous_stencil_compare, previous_stencil_value = GraphicsState.get_stencil_test(graphics)
    local composition_target_pushed = false
    local ok, err = xpcall(function()
        GraphicsState.set_current_canvas(graphics, canvas)
        push_composition_target(render_state, graphics, canvas)
        composition_target_pushed = true

        if Types.is_function(graphics.origin) then
            graphics.origin()
        end

        GraphicsState.clear_target(graphics)
        GraphicsState.set_scissor_rect(graphics, nil)
        GraphicsState.set_stencil_test(graphics, nil, nil)

        if Types.is_function(graphics.setColor) then
            graphics.setColor(1, 1, 1, 1)
        end

        if Types.is_function(graphics.setShader) then
            graphics.setShader()
        end

        if previous_blend_mode ~= nil then
            GraphicsState.set_blend_mode(graphics, previous_blend_mode[1], previous_blend_mode[2])
        end

        runtime.draw_subtree(node, graphics, draw_callback, {
            active_clips = {},
            scissor = nil,
            stencil_compare = nil,
            stencil_value = nil,
        }, {
            suppress_root_compositing_for = node,
            composition_target_stack = render_state.composition_target_stack,
        })

        if composition_target_pushed and peek_composition_target(render_state, graphics) == canvas then
            pop_composition_target(render_state, graphics)
            composition_target_pushed = false
        end

        GraphicsState.set_current_canvas(graphics, previous_canvas)
        GraphicsState.set_scissor_rect(graphics, previous_scissor)
        GraphicsState.set_stencil_test(graphics, previous_stencil_compare, previous_stencil_value)
        composite_isolated_subtree(node, graphics, canvas, compositing_plan, clip_state, runtime)
    end, debug.traceback)

    if composition_target_pushed and peek_composition_target(render_state, graphics) == canvas then
        pop_composition_target(render_state, graphics)
    end

    GraphicsState.set_current_canvas(graphics, previous_canvas)
    GraphicsState.set_scissor_rect(graphics, previous_scissor)
    GraphicsState.set_stencil_test(graphics, previous_stencil_compare, previous_stencil_value)
    GraphicsState.restore_blend_mode(graphics, previous_blend_mode)
    GraphicsState.restore_shader(graphics, previous_shader)
    GraphicsState.restore_color(graphics, previous_color)
    pool:release(canvas)

    if not ok then
        error(err, 0)
    end

    return nil
end

return RootCompositor
