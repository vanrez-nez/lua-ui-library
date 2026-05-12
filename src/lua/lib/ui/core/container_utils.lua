local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local MathUtils = require('lib.ui.utils.math')
local Matrix = require('lib.ui.utils.matrix')
local Rectangle = require('lib.ui.core.rectangle')
local Object = require('lib.cls')
local SideQuad = require('lib.ui.core.side_quad')
local CornerQuad = require('lib.ui.core.corner_quad')
local Constants = require('lib.ui.core.constants')
local EventDispatcher = require('lib.ui.event.event_dispatcher')
local Schema = require('lib.ui.utils.schema')
local DirtyProps = require('lib.ui.utils.dirty_props')
local Utils = require('lib.ui.utils.common')
local GraphicsState = require('lib.ui.render.graphics_state')
local RootCompositor = require('lib.ui.render.root_compositor')
local RuntimeProfiler = require('profiler.runtime_profiler')
local ContainerPropertyViews = require('lib.ui.core.container_property_views')
local Styling = require('lib.ui.utils.styling')
local ContainerQuads = require('lib.ui.core.container_quads')

local abs = math.abs
local max = math.max
local min = math.min

local CLIP_EPSILON = 1e-9

local get_scissor_rect = GraphicsState.get_scissor_rect
local set_scissor_rect = GraphicsState.set_scissor_rect
local get_stencil_test = GraphicsState.get_stencil_test
local set_stencil_test = GraphicsState.set_stencil_test

local clamp_number = MathUtils.clamp_number
local resolve_axis_size = MathUtils.resolve_axis_size

local side_scratch_layer_1 = {}
local side_scratch_layer_2 = {}
local corner_scratch_layer_1 = {}
local corner_scratch_layer_2 = {}

local ContainerUtils = {}

local walk_hierarchy
local ensure_current
local get_declared_rule
local resolve_quad_value
local get_effective_value
local sync_resolved_cache
local axis_fill_supported_by_parent
local resolve_fill_axis_size
local resolve_measurement_axis_size
local refresh_measurement
local refresh_local_transform
local refresh_world_transform
local refresh_bounds
local refresh_child_order_cache
local resolve_world_inverse
local contains_world_point
local point_within_active_clips
local get_world_clip_points
local is_axis_aligned_edge
local is_axis_aligned_clip
local get_world_clip_rect
local has_degenerate_clip
local clear_array_tail
local get_empty_scissor_rect
local get_scissor_scratch_rect
local copy_rect_into
local intersect_rect_into
local resolve_axis_aligned_scissor
local draw_clip_polygon
local _draw_children
local find_hit_target
local detach_child
local destroy_subtree
local _init_state_fields
local _init_schema
local _init_hooks
local _apply_opts
local refresh_responsive
local is_layout_node
local find_child_index
local assert_live_container
local assert_no_cycle
local get_root
local responsive_overrides_affect_root_compositing_plan
local is_internal_node
local is_public_node
local is_strict_descendant_of
local assign_attachment_root_recursive
local register_node_id_with_root
local register_subtree_ids
local deregister_node_id_from_root_value
local deregister_node_id_from_root
local deregister_subtree_ids
local rebuild_attachment_root_index
local find_sibling_name_collision
local validate_name_uniqueness
local validate_id_uniqueness_against_root
local validate_subtree_attach_identity
local validate_depth_argument
local validate_lookup_key
local find_by_id_bounded
local find_by_tag_bounded
local draw_subtree_scissor
local draw_subtree_stencil
local draw_subtree_plain
local draw_subtree

function walk_hierarchy(cls, key)
    local current = cls
    while current do
        local val = rawget(current, key)
        if val ~= nil then return val end
        current = rawget(current, "super")
    end
end


function ensure_current(node)
    local root = get_root(node)

    -- Fast path for Stage instances (which are usually the root)
    if root._ui_stage_instance then
        local method = root._synchronize_for_read
        if Types.is_function(method) then
            method(root)
            return
        end
    end

    local method = walk_hierarchy(root._pclass or getmetatable(root), "_synchronize_for_read")

    if Types.is_function(method) then
        method(root)
        return
    end

    if Types.is_function(root.update) then
        root:update()
    end
end

function get_declared_rule(self, key)
    local declared_props = self._declared_props
    return declared_props[key]
end

function resolve_quad_value(self, family_name, requested_key)
    local family = ContainerQuads.FAMILIES[family_name]

    if not Styling.requires_resolution(self, requested_key, family) then
        return nil
    end

    local overrides = self._resolved_responsive_overrides

    if family.kind == 'corner' then
        local resolved = CornerQuad.resolve_layers({
            ContainerQuads._fill_corner_quad_layer(corner_scratch_layer_1, overrides, family),
            ContainerQuads._fill_corner_quad_layer(corner_scratch_layer_2, self._pdata, family),
        }, {
            label = family.aggregate,
        }, 3)

        if resolved == nil then
            return nil
        end

        if requested_key == family.aggregate then
            return resolved
        end

        local accessor = ContainerQuads.MEMBER_ACCESSOR[requested_key]
        if accessor then
            return resolved[accessor]
        end

        return nil
    end

    local resolved = SideQuad.resolve_layers({
        ContainerQuads._fill_side_quad_layer(side_scratch_layer_1, overrides, family),
        ContainerQuads._fill_side_quad_layer(side_scratch_layer_2, self._pdata, family),
    }, {
        label = family.aggregate,
        factory = family.factory,
    }, 3)

    if resolved == nil then
        return nil
    end

    if requested_key == family.aggregate then
        return resolved
    end

    local accessor = ContainerQuads.MEMBER_ACCESSOR[requested_key]
    if accessor then
        return resolved[accessor]
    end

    return nil
end

function get_effective_value(self, key)
    local family_name = ContainerQuads.KEY_TO_FAMILY[key]
    if family_name ~= nil then
        local family = ContainerQuads.FAMILIES[family_name]
        if Styling.requires_resolution(self, key, family) then
            return resolve_quad_value(self, family_name, key)
        end
        return rawget(self, key)
    end

    local overrides = self._resolved_responsive_overrides
    if not Styling.requires_resolution(self, key) then
        return rawget(self, key)
    end

    if overrides ~= nil and overrides[key] ~= nil then
        return overrides[key]
    end

    return rawget(self, key)
end

function sync_resolved_cache(self)
    local declared_props = self._declared_props
    local resolved_pdata = self._resolved_pdata
    for key in pairs(declared_props) do
        if type(declared_props[key]) == 'table' then
            resolved_pdata[key] = get_effective_value(self, key)
        end
    end
end


function axis_fill_supported_by_parent(self, axis_key)
    local parent = self.parent

    if parent ~= nil and parent._ui_stage_instance == true then
        return true
    end

    if parent ~= nil and parent._ui_layout_instance == true then
        return true
    end

    local parent_contract = parent and parent._child_fill_contract
    if parent_contract ~= nil and parent_contract[axis_key] == true then
        return true
    end

    local node_contract = self._fill_parent_contract
    if node_contract ~= nil and node_contract[axis_key] == true then
        return true
    end

    return false
end

function resolve_fill_axis_size(self, axis_key, parent_size)
    if axis_fill_supported_by_parent(self, axis_key) then
        return parent_size or 0
    end

    local parent = self.parent
    local parent_name

    if parent ~= nil then
        parent_name = getmetatable(parent).__name or tostring(parent)
    elseif self._measurement_context_width ~= nil or
        self._measurement_context_height ~= nil then
        parent_name = 'measurement context'
    else
        parent_name = 'no parent'
    end

    Assert.fail(
        'fill on ' .. axis_key .. ' is invalid for this parent-child pairing (' ..
            tostring(parent_name) .. ' does not define fill resolution for ' .. axis_key .. ')',
        3
    )
end

function resolve_measurement_axis_size(self, axis_key, configured, parent_size)
    if configured == Constants.SIZE_MODE_FILL then
        return resolve_fill_axis_size(self, axis_key, parent_size)
    end

    return resolve_axis_size(configured, parent_size)
end

function refresh_measurement(self)
    local parent_width
    local parent_height

    if self.parent then
        local parent_content_rect = self.parent:_get_effective_content_rect()
        parent_width = parent_content_rect.width
        parent_height = parent_content_rect.height
    else
        parent_width = self._measurement_context_width
        parent_height = self._measurement_context_height
    end

    local has_responsive = self.responsive ~= nil or self.breakpoints ~= nil
    local get_val
    if has_responsive then
        get_val = get_effective_value
    else
        get_val = rawget
    end

    local width = clamp_number(
        resolve_measurement_axis_size(self, 'width', get_val(self, 'width'), parent_width),
        get_val(self, 'minWidth'),
        get_val(self, 'maxWidth')
    )
    local height = clamp_number(
        resolve_measurement_axis_size(self, 'height', get_val(self, 'height'), parent_height),
        get_val(self, 'minHeight'),
        get_val(self, 'maxHeight')
    )

    self._resolved_width = width
    self._resolved_height = height
    self._local_bounds_cache = Rectangle(0, 0, width, height)
    self:clear_dirty('measurement')
end

function refresh_local_transform(self)
    local parent_width = 0
    local parent_height = 0

    if self.parent then
        local parent_content_rect = self.parent:_get_effective_content_rect()
        parent_width = parent_content_rect.width
        parent_height = parent_content_rect.height
    elseif self._measurement_context_width ~= nil or
        self._measurement_context_height ~= nil then
        parent_width = self._measurement_context_width or 0
        parent_height = self._measurement_context_height or 0
    end

    local has_responsive = self.responsive ~= nil or self.breakpoints ~= nil
    local get_val
    if has_responsive then
        get_val = get_effective_value
    else
        get_val = rawget
    end

    local width = self._resolved_width or 0
    local height = self._resolved_height or 0
    local pivot_x = (get_val(self, 'pivotX') or 0.5) * width
    local pivot_y = (get_val(self, 'pivotY') or 0.5) * height
    local anchor_x = (get_val(self, 'anchorX') or 0) * parent_width
    local anchor_y = (get_val(self, 'anchorY') or 0) * parent_height
    local layout_offset_x = self._layout_offset_x or 0
    local layout_offset_y = self._layout_offset_y or 0

    local position_x = layout_offset_x + anchor_x + (get_val(self, 'x') or 0)
    local position_y = layout_offset_y + anchor_y + (get_val(self, 'y') or 0)

    local local_transform = self._local_transform_cache
    local_transform:set_from_transform(
        position_x + pivot_x,
        position_y + pivot_y,
        pivot_x,
        pivot_y,
        (get_val(self, 'scaleX') or 1),
        (get_val(self, 'scaleY') or 1),
        (get_val(self, 'rotation') or 0),
        (get_val(self, 'skewX') or 0),
        (get_val(self, 'skewY') or 0)
    )
    self:clear_dirty('local_transform')
end

function refresh_world_transform(self)
    local previous = self._world_transform_cache
    local next_a, next_b, next_c, next_d, next_tx, next_ty

    if self.parent then
        local parent_world = self.parent._world_transform_cache
        local local_transform = self._local_transform_cache
        next_a = parent_world.a * local_transform.a + parent_world.c * local_transform.b
        next_b = parent_world.b * local_transform.a + parent_world.d * local_transform.b
        next_c = parent_world.a * local_transform.c + parent_world.c * local_transform.d
        next_d = parent_world.b * local_transform.c + parent_world.d * local_transform.d
        next_tx = parent_world.a * local_transform.tx + parent_world.c * local_transform.ty + parent_world.tx
        next_ty = parent_world.b * local_transform.tx + parent_world.d * local_transform.ty + parent_world.ty
    else
        local local_transform = self._local_transform_cache
        next_a = local_transform.a
        next_b = local_transform.b
        next_c = local_transform.c
        next_d = local_transform.d
        next_tx = local_transform.tx
        next_ty = local_transform.ty
    end

    previous:set(next_a, next_b, next_c, next_d, next_tx, next_ty)
    self:clear_dirty('world_transform')
    self:mark_dirty('world_inverse')
end

function refresh_bounds(self)
    local cls = self._pclass or getmetatable(self)
    local resolve_world_bounds_points = cls._resolved_bounds_method
    if resolve_world_bounds_points == nil then
        resolve_world_bounds_points = walk_hierarchy(cls, '_get_world_bounds_points') or false
        cls._resolved_bounds_method = resolve_world_bounds_points
    end

    if resolve_world_bounds_points ~= false then
        local points = resolve_world_bounds_points(self)
        if Types.is_table(points) and #points > 0 then
            self._world_bounds_cache = Rectangle.bounding_box(points)
            self:clear_dirty('bounds')
            return
        end
    end

    local width = self._resolved_width or 0
    local height = self._resolved_height or 0
    local matrix = self._world_transform_cache
    local x1, y1 = matrix:transform_point(0, 0)
    local x2, y2 = matrix:transform_point(width, 0)
    local x3, y3 = matrix:transform_point(width, height)
    local x4, y4 = matrix:transform_point(0, height)
    local min_x = min(min(x1, x2), min(x3, x4))
    local min_y = min(min(y1, y2), min(y3, y4))
    local max_x = max(max(x1, x2), max(x3, x4))
    local max_y = max(max(y1, y2), max(y3, y4))
    local world_bounds = self._world_bounds_cache
    world_bounds:set(min_x, min_y, max_x - min_x, max_y - min_y)
    self:clear_dirty('bounds')
end

function refresh_child_order_cache(self)
    local children = self._children
    local decorated = {}

    for index = 1, #children do
        local child = children[index]
        decorated[index] = {
            zIndex = get_effective_value(child, 'zIndex') or 0,
            index = index,
            child = child,
        }
    end

    table.sort(decorated, function(left, right)
        if left.zIndex == right.zIndex then
            return left.index < right.index
        end

        return left.zIndex < right.zIndex
    end)

    local ordered = {}

    for index = 1, #decorated do
        ordered[index] = decorated[index].child
    end

    self._ordered_children = ordered
    self:clear_dirty('child_order')
end

function resolve_world_inverse(self)
    if self:group_dirty('world_inverse') then
        local matrix = self._world_transform_cache
        local inv, err = matrix:inverse()
        self._world_inverse_cache = inv
        self._world_inverse_error = err
        self:clear_dirty('world_inverse')
    end

    return self._world_inverse_cache, self._world_inverse_error
end

function contains_world_point(self, x, y)
    local local_bounds = self._local_bounds_cache
    if local_bounds:is_empty() then
        return false
    end

    local inverse = resolve_world_inverse(self)

    if not inverse then
        return false
    end

    local local_x, local_y = inverse:transform_point(x, y)

    return local_bounds:contains_point(local_x, local_y)
end

function point_within_active_clips(active_clips, x, y)
    for index = 1, #active_clips do
        if not contains_world_point(active_clips[index], x, y) then
            return false
        end
    end

    return true
end

function get_world_clip_points(self, points)
    local width = self._resolved_width or 0
    local height = self._resolved_height or 0
    local matrix = self._world_transform_cache
    local x1, y1 = matrix:transform_point(0, 0)
    local x2, y2 = matrix:transform_point(width, 0)
    local x3, y3 = matrix:transform_point(width, height)
    local x4, y4 = matrix:transform_point(0, height)

    points = points or {}

    for index = 1, 4 do
        if points[index] == nil then
            points[index] = {
                x = 0,
                y = 0,
            }
        end
    end

    points[1].x = x1
    points[1].y = y1
    points[2].x = x2
    points[2].y = y2
    points[3].x = x3
    points[3].y = y3
    points[4].x = x4
    points[4].y = y4

    return points
end

function is_axis_aligned_edge(first, second)
    return abs(first.x - second.x) <= CLIP_EPSILON or
        abs(first.y - second.y) <= CLIP_EPSILON
end

function is_axis_aligned_clip(self, clip_state)
    local points = get_world_clip_points(self, clip_state and clip_state.axis_clip_points_scratch or nil)

    if clip_state ~= nil then
        clip_state.axis_clip_points_scratch = points
    end

    return is_axis_aligned_edge(points[1], points[2]) and
        is_axis_aligned_edge(points[2], points[3]) and
        is_axis_aligned_edge(points[3], points[4]) and
        is_axis_aligned_edge(points[4], points[1])
end

function get_world_clip_rect(self)
    return self._world_bounds_cache
end

function has_degenerate_clip(self)
    local local_bounds = self._local_bounds_cache
    if local_bounds:is_empty() then
        return true
    end

    local matrix = self._world_transform_cache
    return not matrix:is_invertible()
end

function clear_array_tail(values, last_index)
    for index = #values, last_index + 1, -1 do
        values[index] = nil
    end
end

function get_empty_scissor_rect(clip_state)
    local rect = clip_state.empty_scissor_rect

    if rect == nil then
        rect = {
            x = 0,
            y = 0,
            width = 0,
            height = 0,
        }
        clip_state.empty_scissor_rect = rect
    else
        rect.x = 0
        rect.y = 0
        rect.width = 0
        rect.height = 0
    end

    return rect
end

function get_scissor_scratch_rect(clip_state, depth)
    local stack = clip_state.scissor_scratch_stack

    if stack == nil then
        stack = {}
        clip_state.scissor_scratch_stack = stack
    end

    local rect = stack[depth]

    if rect == nil then
        rect = {
            x = 0,
            y = 0,
            width = 0,
            height = 0,
        }
        stack[depth] = rect
    end

    return rect
end

function copy_rect_into(target, source)
    target.x = source.x or 0
    target.y = source.y or 0
    target.width = source.width or 0
    target.height = source.height or 0
    return target
end

function intersect_rect_into(target, first, second)
    local left = max(first.x or 0, second.x or 0)
    local top = max(first.y or 0, second.y or 0)
    local right = min(
        (first.x or 0) + (first.width or 0),
        (second.x or 0) + (second.width or 0)
    )
    local bottom = min(
        (first.y or 0) + (first.height or 0),
        (second.y or 0) + (second.height or 0)
    )

    target.x = left
    target.y = top
    target.width = max(0, right - left)
    target.height = max(0, bottom - top)

    return target
end

function resolve_axis_aligned_scissor(clip_state, clip_rect)
    local depth = #clip_state.active_clips
    -- Each clip depth gets its own rect scratch so nested branches can restore parent scissor state.
    local combined = get_scissor_scratch_rect(clip_state, depth)
    local previous_scissor = clip_state.scissor

    if previous_scissor ~= nil then
        return intersect_rect_into(combined, previous_scissor, clip_rect)
    end

    return copy_rect_into(combined, clip_rect)
end

function draw_clip_polygon(graphics, self, clip_state)
    local points = get_world_clip_points(self, clip_state.axis_clip_points_scratch)
    clip_state.axis_clip_points_scratch = points
    local flattened = clip_state.clip_polygon_scratch

    if flattened == nil then
        flattened = {}
        clip_state.clip_polygon_scratch = flattened
    end

    local flattened_index = 1

    for index = 1, #points do
        local point = points[index]
        flattened[flattened_index] = point.x
        flattened[flattened_index + 1] = point.y
        flattened_index = flattened_index + 2
    end

    clear_array_tail(flattened, flattened_index - 1)

    if Types.is_function(graphics.polygon) then
        graphics.polygon('fill', flattened)
    end
end


function _draw_children(node, graphics, draw_callback, clip_state, render_state)
    local ordered_children = node._ordered_children
    for index = 1, #ordered_children do
        draw_subtree(ordered_children[index], graphics, draw_callback, clip_state, render_state)
    end
end

draw_subtree_scissor = function(self, graphics, draw_callback, clip_state, render_state)
    local active_clips = clip_state.active_clips
    local previous_scissor = clip_state.scissor

    clip_state.active_clips[#active_clips + 1] = self
    local combined = resolve_axis_aligned_scissor(clip_state, get_world_clip_rect(self))

    clip_state.scissor = combined
    set_scissor_rect(graphics, combined)

    draw_callback(self)
    _draw_children(self, graphics, draw_callback, clip_state, render_state)

    clip_state.active_clips[#clip_state.active_clips] = nil
    clip_state.scissor = previous_scissor
    set_scissor_rect(graphics, previous_scissor)
end

draw_subtree_stencil = function(self, graphics, draw_callback, clip_state, render_state)
    local active_clips = clip_state.active_clips
    local previous_scissor = clip_state.scissor
    local previous_stencil_compare = clip_state.stencil_compare
    local previous_stencil_value = clip_state.stencil_value

    clip_state.active_clips[#active_clips + 1] = self

    local next_stencil_value = (clip_state.stencil_value or 0) + 1
    set_stencil_test(graphics, previous_stencil_compare, previous_stencil_value)

    if Types.is_function(graphics.stencil) then
        graphics.stencil(function()
            draw_clip_polygon(graphics, self, clip_state)
        end, 'increment', 1, true)
    end

    clip_state.stencil_compare = 'equal'
    clip_state.stencil_value = next_stencil_value
    set_stencil_test(graphics, clip_state.stencil_compare, clip_state.stencil_value)

    draw_callback(self)
    _draw_children(self, graphics, draw_callback, clip_state, render_state)

    set_stencil_test(graphics, 'equal', next_stencil_value)

    if Types.is_function(graphics.stencil) then
        graphics.stencil(function()
            draw_clip_polygon(graphics, self, clip_state)
        end, 'decrement', 1, true)
    end

    clip_state.active_clips[#clip_state.active_clips] = nil
    clip_state.scissor = previous_scissor
    clip_state.stencil_compare = previous_stencil_compare
    clip_state.stencil_value = previous_stencil_value
    set_scissor_rect(graphics, previous_scissor)
    set_stencil_test(graphics, previous_stencil_compare, previous_stencil_value)
end

draw_subtree_plain = function(self, graphics, draw_callback, clip_state, render_state)
    draw_callback(self)
    _draw_children(self, graphics, draw_callback, clip_state, render_state)
end


local ROOT_COMPOSITOR_RUNTIME = {
    get_effective_value = function(node, key)
        return get_effective_value(node, key)
    end,
    get_root = function(node)
        return get_root(node)
    end,
    get_world_clip_rect = function(node)
        return get_world_clip_rect(node)
    end,
    draw_subtree = function(node, graphics, draw_callback, clip_state, render_state)
        draw_subtree(node, graphics, draw_callback, clip_state, render_state)
    end,
}

draw_subtree = function(self, graphics, draw_callback, clip_state, render_state)
    if not get_effective_value(self, 'visible') then
        return
    end

    render_state = RootCompositor.initialize_render_state(graphics, render_state)

    if render_state.suppress_root_compositing_for ~= self then
        local effects = RootCompositor.resolve_node_plan(self, ROOT_COMPOSITOR_RUNTIME)

        if RootCompositor.plan_requires_isolation(effects) then
            RootCompositor.draw_isolated_subtree(
                self,
                graphics,
                draw_callback,
                clip_state,
                render_state,
                effects,
                ROOT_COMPOSITOR_RUNTIME
            )
            return
        end
    end

    local clip_children = get_effective_value(self, 'clipChildren')

    if clip_children then
        local clip_profile_token = RuntimeProfiler.push_zone('Container.draw_subtree.clip_children')
        if has_degenerate_clip(self) then
            local active_clips = clip_state.active_clips
            local previous_scissor = clip_state.scissor

            clip_state.active_clips[#active_clips + 1] = self
            clip_state.scissor = get_empty_scissor_rect(clip_state)
            set_scissor_rect(graphics, clip_state.scissor)

            clip_state.active_clips[#clip_state.active_clips] = nil
            clip_state.scissor = previous_scissor
            set_scissor_rect(graphics, previous_scissor)
            RuntimeProfiler.pop_zone(clip_profile_token)
            return
        end

        if is_axis_aligned_clip(self, clip_state) then
            draw_subtree_scissor(self, graphics, draw_callback, clip_state, render_state)
        else
            draw_subtree_stencil(self, graphics, draw_callback, clip_state, render_state)
        end
        RuntimeProfiler.pop_zone(clip_profile_token)
    else
        draw_subtree_plain(self, graphics, draw_callback, clip_state, render_state)
    end
end

function find_hit_target(self, x, y, layer_eligible, effective_visible, effective_enabled, active_clips)
    effective_visible = effective_visible and get_effective_value(self, 'visible')

    if not effective_visible then
        return nil
    end

    if not point_within_active_clips(active_clips, x, y) then
        return nil
    end

    effective_enabled = effective_enabled and get_effective_value(self, 'enabled')

    if not effective_enabled then
        return nil
    end

    local added_clip = false

    if get_effective_value(self, 'clipChildren') then
        if not contains_world_point(self, x, y) then
            return nil
        end

        active_clips[#active_clips + 1] = self
        added_clip = true
    end

    local ordered_children = self._ordered_children

    for index = #ordered_children, 1, -1 do
        local child = ordered_children[index]
        local target = find_hit_target(child, x, y, layer_eligible, effective_visible, effective_enabled, active_clips)

        if target ~= nil then
            if added_clip then
                active_clips[#active_clips] = nil
            end

            return target
        end
    end

    local target = nil

    if self:_is_effectively_targetable(x, y, {
        active_clips = active_clips,
        effective_enabled = effective_enabled,
        effective_visible = effective_visible,
        layer_eligible = layer_eligible,
    }) then
        target = self
    end

    if added_clip then
        active_clips[#active_clips] = nil
    end

    return target
end

function detach_child(parent, child)
    local index = find_child_index(parent, child)

    if index == nil then
        return
    end

    local stage = get_root(parent)
    local old_attachment_root = get_root(child)
    deregister_subtree_ids(child, old_attachment_root)

    local children = parent._children
    table.remove(children, index)
    parent:mark_dirty('child_order')
    parent:invalidate_stage_update_token()
    child.parent = nil
    child._layout_offset_x = 0
    child._layout_offset_y = 0
    child:mark_dirty('responsive', 'measurement', 'local_transform')
    assign_attachment_root_recursive(child, child)
    rebuild_attachment_root_index(child)
    child:invalidate_world()
    parent:notify_stage_subtree_change(stage, '_handle_detached_subtree', child, parent)
end

function destroy_subtree(node)
    -- _destroying_subtree guards recursive destroy notifications
    node._destroying_subtree = true

    if node.parent then
        detach_child(node.parent, node)
    end

    local children = node._children
    for index = #children, 1, -1 do
        local child = children[index]
        child:destroy()
    end
    -- Explicitly discard array references to GC dead branches and stop dead proxy queries
    node._children = nil
    node._ordered_children = nil
    node._id_index = nil
    node._attachment_root = nil
end

function _init_state_fields(self, config)
    self._config = config

    self._children = {}
    self._ordered_children = {}
    EventDispatcher.constructor(self)

    self._measurement_context_width = nil
    self._measurement_context_height = nil
    self._layout_offset_x = 0
    self._layout_offset_y = 0

    self._resolved_width = 0
    self._resolved_height = 0
    self._local_transform_cache = Matrix.identity()
    self._world_transform_cache = Matrix.identity()
    self._world_inverse_cache = nil
    self._world_inverse_error = 'world transform is not invertible'
    self._local_bounds_cache = Rectangle(0, 0, 0, 0)
    self._world_bounds_cache = Rectangle(0, 0, 0, 0)
    self._ui_container_instance = true
    self._attachment_root = self
    self._id_index = {}
    self._resolved_responsive_overrides = {}
    self._resolved_pdata = {}

    self._motion_visual_state = {}
    self._motion_last_request = nil

    DirtyProps.init(self, {
        anchorX = {
            val = 0,
            groups = { 'local_transform' }
        },
        anchorY = {
            val = 0,
            groups = { 'local_transform' }
        },
        pivotX = {
            val = 0.5,
            groups = { 'local_transform' }
        },
        pivotY = {
            val = 0.5,
            groups = { 'local_transform' }
        },
        x = {
            val = 0,
            groups = { 'local_transform' }
        },
        y = {
            val = 0,
            groups = { 'local_transform' }
        },
        scaleX = {
            val = 1,
            groups = { 'local_transform' }
        },
        scaleY = {
            val = 1,
            groups = { 'local_transform' }
        },
        rotation = {
            val = 0,
            groups = { 'local_transform' }
        },
        skewX = {
            val = 0,
            groups = { 'local_transform' }
        },
        skewY = {
            val = 0,
            groups = { 'local_transform' }
        },
        width = {
            val = 0,
            groups = { 'measurement', 'local_transform' }
        },
        height = {
            val = 0,
            groups = { 'measurement', 'local_transform' }
        },
        minWidth = {
            val = nil,
            groups = { 'measurement' }
        },
        minHeight = {
            val = nil,
            groups = { 'measurement' }
        },
        maxWidth = {
            val = nil,
            groups = { 'measurement' }
        },
        maxHeight = {
            val = nil,
            groups = { 'measurement' }
        },
        responsive = {
            val = nil,
            groups = { 'responsive' }
        },
        breakpoints = {
            val = nil,
            groups = { 'responsive' }
        },
        zIndex = {
            val = 0,
            groups = { 'child_order' }
        },
        _world_transform_flag = {
            val = false,
            groups = { 'world_transform' }
        },
        _bounds_flag = {
            val = false,
            groups = { 'bounds' }
        },
        _world_inverse_flag = {
            val = false,
            groups = { 'world_inverse' }
        },
        _layout_flag = {
            val = false,
            groups = { 'layout' }
        },
    })
    self:reset_dirty_props()

    self._parent_world_ref = nil
    self._parent_resolved_w = nil
    self._parent_resolved_h = nil
end

function _init_schema(self, extra_public_keys)
    local class = rawget(self, '_pclass') or getmetatable(self)
    local schema = class.schema
    if schema == nil then
        schema = Schema.create({})
    end

    local declared_extras = nil
    if extra_public_keys ~= nil then
        local rule_overrides = {}
        declared_extras = {}

        for key, rule in pairs(extra_public_keys) do
            declared_extras[key] = rule
            if type(rule) == 'table' and rule.kind ~= nil then
                rule_overrides[key] = rule
            end
        end

        schema = Schema.extend(schema, rule_overrides)
    end

    local declared_props = schema:get_rules()
    if declared_extras ~= nil then
        declared_props = Utils.merge_tables(declared_props, declared_extras)
    end

    rawset(self, '_declared_props', declared_props)

    ContainerPropertyViews.install(self, {
        public = function(instance, key)
            return rawget(instance, key)
        end,
        effective = function(instance, key)
            if instance._declared_props[key] ~= nil then
                return instance._resolved_pdata[key]
            end
            return rawget(instance, key)
        end,
    })

    return declared_props, schema
end

function _init_hooks()
    -- No more Proxy/Reactive hooks — DirtyProps sync handles change detection.
end

function _apply_opts(self, opts, declared_props)
    for key, value in pairs(opts) do
        local rule = declared_props[key]
        if rule == nil then
            Assert.fail('Unsupported prop "' .. tostring(key) .. '"', 4)
        end

        if type(rule) == 'table' and rule.kind ~= nil then
            self[key] = value
        else
            ContainerPropertyViews.write_extra(self, key, value)
        end
    end
end

function refresh_responsive(self)
    self:clear_dirty('responsive')
end

function is_layout_node(node)
    return node._ui_layout_instance == true or Object.is(node, "LayoutNode")
end

function find_child_index(parent, child)
    local children = parent._children
    for index = 1, #children do
        if children[index] == child then
            return index
        end
    end
    return nil
end

function assert_live_container(node, name, level)
    local is_container = Object.is(node, "Container") or (type(node) == 'table' and node._ui_container_instance)
    if not is_container then
        Assert.fail(name .. ' must be a Container', level or 1)
    end
end

function assert_no_cycle(parent, child, level)
    local current = parent
    while current do
        if current == child then
            Assert.fail(
                'cyclic parenting is invalid for Container trees',
                level or 1
            )
        end
        current = current.parent
    end
end

function get_root(node)
    local attachment_root = node._attachment_root
    if attachment_root ~= nil then
        return attachment_root
    end
    local current = node
    while current.parent do current = current.parent end
    return current
end

function responsive_overrides_affect_root_compositing_plan(self, previous_overrides, next_overrides)
    if previous_overrides ~= nil then
        for key in pairs(previous_overrides) do
            if RootCompositor.property_affects_node_plan(self, key) then
                return true
            end
        end
    end
    if next_overrides ~= nil then
        for key in pairs(next_overrides) do
            if RootCompositor.property_affects_node_plan(self, key) then
                return true
            end
        end
    end
    return false
end

function is_internal_node(node)
    return node.internal == true
end

function is_public_node(node)
    return not is_internal_node(node)
end

function is_strict_descendant_of(node, ancestor)
    local current = node.parent
    while current ~= nil do
        if current == ancestor then
            return true
        end
        current = current.parent
    end
    return false
end

function assign_attachment_root_recursive(node, attachment_root)
    node._attachment_root = attachment_root
    if node == attachment_root then
        node._id_index = node._id_index or {}
    else
        node._id_index = nil
    end
    local children = node._children
    for index = 1, #children do
        assign_attachment_root_recursive(children[index], attachment_root)
    end
end

function register_node_id_with_root(node, attachment_root)
    if not is_public_node(node) then
        return
    end
    local id = node.id
    if id == nil then
        return
    end
    local index = attachment_root._id_index
    if index == nil then
        index = {}
        attachment_root._id_index = index
    end
    index[id] = node
end

function register_subtree_ids(node, attachment_root)
    register_node_id_with_root(node, attachment_root)
    local children = node._children
    for index = 1, #children do
        register_subtree_ids(children[index], attachment_root)
    end
end

function deregister_node_id_from_root_value(node, attachment_root, id)
    if attachment_root == nil or not is_public_node(node) then
        return
    end
    if id == nil then
        return
    end
    local index = attachment_root._id_index
    if index ~= nil and index[id] == node then
        index[id] = nil
    end
end

function deregister_node_id_from_root(node, attachment_root)
    deregister_node_id_from_root_value(node, attachment_root, node.id)
end

function deregister_subtree_ids(node, attachment_root)
    deregister_node_id_from_root(node, attachment_root)
    local children = node._children
    for index = 1, #children do
        deregister_subtree_ids(children[index], attachment_root)
    end
end

function rebuild_attachment_root_index(root)
    root._id_index = {}
    assign_attachment_root_recursive(root, root)
    register_subtree_ids(root, root)
end

function find_sibling_name_collision(node, name, parent)
    if name == nil or parent == nil or not is_public_node(node) then
        return nil
    end
    local children = parent._children
    for index = 1, #children do
        local sibling = children[index]
        if sibling ~= node and is_public_node(sibling) and sibling.name == name then
            return sibling
        end
    end
    return nil
end

function validate_name_uniqueness(node, name, parent, level)
    local collision = find_sibling_name_collision(node, name, parent)
    if collision ~= nil then
        Assert.fail(
            'duplicate sibling name "' .. tostring(name) .. '" is invalid',
            level or 1
        )
    end
end

function validate_id_uniqueness_against_root(node, id, attachment_root, ignored_nodes, level)
    if id == nil or not is_public_node(node) then
        return
    end
    local index = attachment_root and attachment_root._id_index
    local existing = index and index[id] or nil
    if existing ~= nil and existing ~= node and not (ignored_nodes and ignored_nodes[existing]) then
        Assert.fail(
            'duplicate id "' .. tostring(id) .. '" is invalid within one attachment root',
            level or 1
        )
    end
end

function validate_subtree_attach_identity(parent, child, level)
    if is_public_node(child) then
        local id = child.id
        if id ~= nil then
            validate_id_uniqueness_against_root(child, id, get_root(parent), nil, level)
        end
        validate_name_uniqueness(child, child.name, parent, level)
    end
end

function validate_depth_argument(method_name, depth, default_depth)
    if depth == nil then
        return default_depth
    end
    if depth == math.huge then
        return math.huge
    end
    Assert.number(method_name .. '.depth', depth, 3)
    if depth ~= math.floor(depth) then
        Assert.fail(method_name .. '.depth must be an integer, -1, or math.huge', 3)
    end
    if depth < -1 then
        Assert.fail(method_name .. '.depth must not be less than -1', 3)
    end
    return depth
end

function validate_lookup_key(method_name, key_name, value)
    if value == nil then
        Assert.fail(method_name .. '.' .. key_name .. ' must not be nil', 3)
    end
    Assert.string(method_name .. '.' .. key_name, value, 3)
    if value == '' then
        Assert.fail(method_name .. '.' .. key_name .. ' must not be an empty string', 3)
    end
    return value
end

function find_by_id_bounded(node, id, depth)
    if depth == 0 then
        return nil
    end
    local children = node._children
    for index = 1, #children do
        local child = children[index]
        if is_public_node(child) and child.id == id then
            return child
        end
        if depth == math.huge or depth > 1 then
            local next_depth = (depth == math.huge) and math.huge or (depth - 1)
            local found = find_by_id_bounded(child, id, next_depth)
            if found ~= nil then
                return found
            end
        end
    end
    return nil
end

function find_by_tag_bounded(node, tag, depth, results)
    results = results or {}
    if depth == 0 then
        if is_public_node(node) and node.tag == tag then
            results[#results + 1] = node
        end
        return results
    end
    local children = node._children
    for index = 1, #children do
        local child = children[index]
        if is_public_node(child) and child.tag == tag then
            results[#results + 1] = child
        end
        if depth == math.huge or depth > 1 then
            local next_depth = (depth == math.huge) and math.huge or (depth - 1)
            find_by_tag_bounded(child, tag, next_depth, results)
        end
    end
    return results
end

ContainerUtils.walk_hierarchy = walk_hierarchy
ContainerUtils.ensure_current = ensure_current
ContainerUtils.get_declared_rule = get_declared_rule
ContainerUtils.resolve_quad_value = resolve_quad_value
ContainerUtils.get_effective_value = get_effective_value
ContainerUtils.sync_resolved_cache = sync_resolved_cache
ContainerUtils.axis_fill_supported_by_parent = axis_fill_supported_by_parent
ContainerUtils.resolve_fill_axis_size = resolve_fill_axis_size
ContainerUtils.resolve_measurement_axis_size = resolve_measurement_axis_size
ContainerUtils.refresh_measurement = refresh_measurement
ContainerUtils.refresh_local_transform = refresh_local_transform
ContainerUtils.refresh_world_transform = refresh_world_transform
ContainerUtils.refresh_bounds = refresh_bounds
ContainerUtils.refresh_child_order_cache = refresh_child_order_cache
ContainerUtils.resolve_world_inverse = resolve_world_inverse
ContainerUtils.contains_world_point = contains_world_point
ContainerUtils.point_within_active_clips = point_within_active_clips
ContainerUtils.get_world_clip_points = get_world_clip_points
ContainerUtils.is_axis_aligned_edge = is_axis_aligned_edge
ContainerUtils.is_axis_aligned_clip = is_axis_aligned_clip
ContainerUtils.get_world_clip_rect = get_world_clip_rect
ContainerUtils.has_degenerate_clip = has_degenerate_clip
ContainerUtils.clear_array_tail = clear_array_tail
ContainerUtils.get_empty_scissor_rect = get_empty_scissor_rect
ContainerUtils.get_scissor_scratch_rect = get_scissor_scratch_rect
ContainerUtils.copy_rect_into = copy_rect_into
ContainerUtils.intersect_rect_into = intersect_rect_into
ContainerUtils.resolve_axis_aligned_scissor = resolve_axis_aligned_scissor
ContainerUtils.draw_clip_polygon = draw_clip_polygon
ContainerUtils._draw_children = _draw_children
ContainerUtils.find_hit_target = find_hit_target
ContainerUtils.detach_child = detach_child
ContainerUtils.destroy_subtree = destroy_subtree
ContainerUtils._init_state_fields = _init_state_fields
ContainerUtils._init_schema = _init_schema
ContainerUtils._init_hooks = _init_hooks
ContainerUtils._apply_opts = _apply_opts
ContainerUtils.refresh_responsive = refresh_responsive
ContainerUtils.is_layout_node = is_layout_node
ContainerUtils.find_child_index = find_child_index
ContainerUtils.assert_live_container = assert_live_container
ContainerUtils.assert_no_cycle = assert_no_cycle
ContainerUtils.get_root = get_root
ContainerUtils.responsive_overrides_affect_root_compositing_plan = responsive_overrides_affect_root_compositing_plan
ContainerUtils.is_internal_node = is_internal_node
ContainerUtils.is_public_node = is_public_node
ContainerUtils.is_strict_descendant_of = is_strict_descendant_of
ContainerUtils.assign_attachment_root_recursive = assign_attachment_root_recursive
ContainerUtils.register_node_id_with_root = register_node_id_with_root
ContainerUtils.register_subtree_ids = register_subtree_ids
ContainerUtils.deregister_node_id_from_root_value = deregister_node_id_from_root_value
ContainerUtils.deregister_node_id_from_root = deregister_node_id_from_root
ContainerUtils.deregister_subtree_ids = deregister_subtree_ids
ContainerUtils.rebuild_attachment_root_index = rebuild_attachment_root_index
ContainerUtils.find_sibling_name_collision = find_sibling_name_collision
ContainerUtils.validate_name_uniqueness = validate_name_uniqueness
ContainerUtils.validate_id_uniqueness_against_root = validate_id_uniqueness_against_root
ContainerUtils.validate_subtree_attach_identity = validate_subtree_attach_identity
ContainerUtils.validate_depth_argument = validate_depth_argument
ContainerUtils.validate_lookup_key = validate_lookup_key
ContainerUtils.find_by_id_bounded = find_by_id_bounded
ContainerUtils.find_by_tag_bounded = find_by_tag_bounded
ContainerUtils.draw_subtree_scissor = draw_subtree_scissor
ContainerUtils.draw_subtree_stencil = draw_subtree_stencil
ContainerUtils.draw_subtree_plain = draw_subtree_plain
ContainerUtils.draw_subtree = draw_subtree
ContainerUtils.get_scissor_rect = get_scissor_rect
ContainerUtils.get_stencil_test = get_stencil_test

return ContainerUtils
