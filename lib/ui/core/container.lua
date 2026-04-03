local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local MathUtils = require('lib.ui.utils.math')
local Matrix = require('lib.ui.utils.matrix')
local Rectangle = require('lib.ui.core.rectangle')
local Object = require('lib.cls')

local Schema = require('lib.ui.utils.schema')
local Utils = require('lib.ui.utils.common')
local Motion = require('lib.ui.motion')
local CanvasPool = require('lib.ui.render.canvas_pool')

local abs = math.abs

local CLIP_EPSILON = 1e-9

local EventDispatcher = require('lib.ui.event.event_dispatcher')

local Container = EventDispatcher:extends('Container')

Container._schema = require('lib.ui.core.container_schema')

local LOCAL_TRANSFORM_KEYS = {
    anchorX = true, anchorY = true, pivotX = true, pivotY = true,
    x = true, y = true, scaleX = true, scaleY = true,
    rotation = true, skewX = true, skewY = true
}

local MEASUREMENT_KEYS = {
    width = true, height = true, minWidth = true, minHeight = true, maxWidth = true, maxHeight = true
}

local canvas_pools = setmetatable({}, { __mode = 'k' })


local function is_layout_node(node)
    return (Object.is(node, "LayoutNode") or rawget(node, '_ui_layout_instance') == true) and not rawget(node, '_destroyed')
end

local default = MathUtils.default
local clamp_number = MathUtils.clamp_number
local resolve_axis_size = MathUtils.resolve_axis_size
local is_percentage_string = MathUtils.is_percentage_string

-- Removed validate_size_value, using Schema.validate_size directly

local function find_child_index(parent, child)
    local children = rawget(parent, '_children') or {}
    for index = 1, #children do
        if children[index] == child then
            return index
        end
    end

    return nil
end

-- Removed manual key checks; Schemas handles extension directly.

function Container:invalidate_world()
    rawset(self, '_world_transform_dirty', true)
    rawset(self, '_bounds_dirty', true)
    rawset(self, '_world_inverse_dirty', true)
end

function Container:invalidate_descendant_world()
    local children = rawget(self, '_children') or {}
    for index = 1, #children do
        local child = children[index]
        child:invalidate_world()
        child:invalidate_descendant_world()
    end
end

function Container:invalidate_descendant_geometry()
    local children = rawget(self, '_children') or {}
    for index = 1, #children do
        local child = children[index]
        rawset(child, '_responsive_dirty', true)
        rawset(child, '_measurement_dirty', true)
        rawset(child, '_local_transform_dirty', true)
        child:invalidate_world()
        child:invalidate_descendant_geometry()
    end
end

local function assert_live_container(node, name, level)
    local is_container = Object.is(node, "Container") or (type(node) == 'table' and rawget(node, '_ui_container_instance'))
    if not is_container then
        Assert.fail(name .. ' must be a Container', level or 1)
    end

    if rawget(node, '_destroyed') then
        Assert.fail(name .. ' must not be destroyed', level or 1)
    end
end


local function assert_not_destroyed(self, level)
    if rawget(self, '_destroyed') then
        Assert.fail('cannot use a destroyed Container', level or 1)
    end
end

local function assert_no_cycle(parent, child, level)
    local current = parent

    while current do
        if current == child then
            Assert.fail(
                'cyclic parenting is invalid for Container trees',
                level or 1
            )
        end

        current = rawget(current, 'parent')
    end
end

local function get_root(node)
    local attachment_root = rawget(node, '_attachment_root')
    if attachment_root ~= nil and not rawget(attachment_root, '_destroyed') then
        return attachment_root
    end

    local current = node
    local parent = rawget(current, 'parent')
    while parent ~= nil do
        current = parent
        parent = rawget(current, 'parent')
    end
    return current
end

local function get_public_value(self, key)
    local public_values = rawget(self, '_public_values')
    if public_values == nil then
        return nil
    end

    return public_values[key]
end

local function is_internal_node(node)
    return get_public_value(node, 'internal') == true
end

local function is_public_node(node)
    return not rawget(node, '_destroyed') and not is_internal_node(node)
end

local function is_strict_descendant_of(node, ancestor)
    local current = rawget(node, 'parent')
    while current ~= nil do
        if current == ancestor then
            return true
        end
        current = rawget(current, 'parent')
    end

    return false
end

local function is_in_same_or_descendant_subtree(node, root)
    return node == root or is_strict_descendant_of(node, root)
end

local function assign_attachment_root_recursive(node, attachment_root)
    rawset(node, '_attachment_root', attachment_root)

    if node == attachment_root then
        rawset(node, '_id_index', rawget(node, '_id_index') or {})
    else
        rawset(node, '_id_index', nil)
    end

    local children = rawget(node, '_children') or {}
    for index = 1, #children do
        assign_attachment_root_recursive(children[index], attachment_root)
    end
end

local function register_node_id_with_root(node, attachment_root)
    if not is_public_node(node) then
        return
    end

    local id = get_public_value(node, 'id')
    if id == nil then
        return
    end

    local index = rawget(attachment_root, '_id_index')
    if index == nil then
        index = {}
        rawset(attachment_root, '_id_index', index)
    end

    index[id] = node
end

local function register_subtree_ids(node, attachment_root)
    register_node_id_with_root(node, attachment_root)

    local children = rawget(node, '_children') or {}
    for index = 1, #children do
        register_subtree_ids(children[index], attachment_root)
    end
end

local function deregister_node_id_from_root(node, attachment_root)
    if attachment_root == nil or not is_public_node(node) then
        return
    end

    local id = get_public_value(node, 'id')
    if id == nil then
        return
    end

    local index = rawget(attachment_root, '_id_index')
    if index ~= nil and index[id] == node then
        index[id] = nil
    end
end

local function deregister_subtree_ids(node, attachment_root)
    deregister_node_id_from_root(node, attachment_root)

    local children = rawget(node, '_children') or {}
    for index = 1, #children do
        deregister_subtree_ids(children[index], attachment_root)
    end
end

local function rebuild_attachment_root_index(root)
    rawset(root, '_id_index', {})
    assign_attachment_root_recursive(root, root)
    register_subtree_ids(root, root)
end

local function find_sibling_name_collision(node, name, parent)
    if name == nil or parent == nil or not is_public_node(node) then
        return nil
    end

    local children = rawget(parent, '_children') or {}
    for index = 1, #children do
        local sibling = children[index]
        if sibling ~= node and is_public_node(sibling) and get_public_value(sibling, 'name') == name then
            return sibling
        end
    end

    return nil
end

local function validate_name_uniqueness(node, name, parent, level)
    local collision = find_sibling_name_collision(node, name, parent)
    if collision ~= nil then
        Assert.fail(
            'duplicate sibling name "' .. tostring(name) .. '" is invalid',
            level or 1
        )
    end
end

local function collect_public_subtree_identity(node, state)
    state = state or {
        ids = {},
        nodes = {},
    }

    state.nodes[node] = true

    if is_public_node(node) then
        local id = get_public_value(node, 'id')
        if id ~= nil then
            local existing = state.ids[id]
            if existing ~= nil and existing ~= node then
                Assert.fail('duplicate id "' .. tostring(id) .. '" is invalid', 3)
            end
            state.ids[id] = node
        end
    end

    local children = rawget(node, '_children') or {}
    for index = 1, #children do
        collect_public_subtree_identity(children[index], state)
    end

    return state
end

local function validate_id_uniqueness_against_root(node, id, attachment_root, ignored_nodes, level)
    if id == nil or not is_public_node(node) then
        return
    end

    local index = attachment_root and rawget(attachment_root, '_id_index')
    local existing = index and index[id] or nil
    if existing ~= nil and existing ~= node and not (ignored_nodes and ignored_nodes[existing]) then
        Assert.fail(
            'duplicate id "' .. tostring(id) .. '" is invalid within one attachment root',
            level or 1
        )
    end
end

local function validate_subtree_attach_identity(parent, child, level)
    local target_root = get_root(parent)
    local subtree_identity = collect_public_subtree_identity(child)

    for id, node in pairs(subtree_identity.ids) do
        validate_id_uniqueness_against_root(node, id, target_root, subtree_identity.nodes, level)
    end

    if is_public_node(child) then
        validate_name_uniqueness(child, get_public_value(child, 'name'), parent, level)
    end
end

local function validate_depth_argument(method_name, depth, default_depth)
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

local function validate_lookup_key(method_name, key_name, value)
    if value == nil then
        Assert.fail(method_name .. '.' .. key_name .. ' must not be nil', 3)
    end

    Assert.string(method_name .. '.' .. key_name, value, 3)
    if value == '' then
        Assert.fail(method_name .. '.' .. key_name .. ' must not be an empty string', 3)
    end

    return value
end

local function find_by_id_bounded(node, id, depth)
    if depth == 0 then
        return nil
    end

    local children = rawget(node, '_children') or {}
    for index = 1, #children do
        local child = children[index]
        if is_public_node(child) and get_public_value(child, 'id') == id then
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

local function find_by_tag_bounded(node, tag, depth, results)
    results = results or {}

    if depth == 0 then
        if is_public_node(node) and get_public_value(node, 'tag') == tag then
            results[#results + 1] = node
        end
        return results
    end

    local children = rawget(node, '_children') or {}
    for index = 1, #children do
        local child = children[index]
        if is_public_node(child) and get_public_value(child, 'tag') == tag then
            results[#results + 1] = child
        end

        if depth == math.huge or depth > 1 then
            local next_depth = (depth == math.huge) and math.huge or (depth - 1)
            find_by_tag_bounded(child, tag, next_depth, results)
        end
    end

    return results
end

function Container:notify_stage_subtree_change(stage, handler_name, child, parent)
    if not Object.is(stage, "Stage") or rawget(stage, '_destroyed') then
        return
    end

    local handler = rawget(stage, handler_name)

    if handler == nil then
        handler = stage[handler_name]
    end

    if Types.is_function(handler) then
        handler(stage, child, parent)
    end
end

function Container:invalidate_stage_update_token()
    local root = get_root(self)

    if Object.is(root, "Stage") and not rawget(root, '_destroyed') then
        rawset(root, '_update_ran', false)
    end
end

function Container:mark_layout_node_dirty()
    if not is_layout_node(self) then
        return false
    end

    if rawget(self, '_layout_dirty') then
        return false
    end

    rawset(self, '_layout_dirty', true)
    self:invalidate_stage_update_token()

    return true
end

function Container:invalidate_ancestor_layouts()
    local current = self

    while current ~= nil do
        current:mark_layout_node_dirty()
        current = current.parent
    end
end

local function walk_hierarchy(cls, key)
    local current = cls
    while current do
        local val = rawget(current, key)
        if val ~= nil then return val end
        current = rawget(current, "super")
    end
end

Container._walk_hierarchy = walk_hierarchy

local function ensure_current(node)
    local root = get_root(node)
    
    -- Fast path for Stage instances (which are usually the root)
    if rawget(root, '_ui_stage_instance') then
        local method = root._synchronize_for_read
        if Types.is_function(method) then
            method(root)
            return
        end
    end

    local method = walk_hierarchy(getmetatable(root), "_synchronize_for_read")

    if Types.is_function(method) then
        method(root)
        return
    end

    if Types.is_function(root.update) then
        root:update()
    end
end

local function validate_public_value(self, key, value, level)
    return Schema.validate(self._allowed_public_keys or self._schema, key, value, self, level)
end

local function get_effective_value(self, key)
    local effective_values = rawget(self, '_effective_values')
    return effective_values and effective_values[key]
end

local function set_initial_public_value(self, key, value)
    local public_values = rawget(self, '_public_values')
    if public_values then
        public_values[key] = validate_public_value(self, key, value, 3)
    end
end

local function refresh_effective_values(self)
    local previous_effective_z_index = nil
    local current_effective = rawget(self, '_effective_values')

    if current_effective ~= nil then
        previous_effective_z_index = current_effective.zIndex
    end

    local effective = {}
    local public_values = rawget(self, '_public_values') or {}

    for key, value in pairs(public_values) do
        effective[key] = value
    end

    local overrides = rawget(self, '_responsive_overrides')

    if overrides ~= nil then
        for key, value in pairs(overrides) do
            effective[key] = validate_public_value(self, key, value, 3)
        end
    end

    rawset(self, '_effective_values', effective)
    rawset(self, '_responsive_dirty', false)

    if previous_effective_z_index ~= (effective and effective.zIndex) then
        self:mark_parent_order_dirty()
    end
end

local function axis_fill_supported_by_parent(self, axis_key)
    local parent = rawget(self, 'parent')

    if parent ~= nil and rawget(parent, '_ui_stage_instance') == true then
        return true
    end

    if parent ~= nil and rawget(parent, '_ui_layout_instance') == true then
        return true
    end

    local parent_contract = parent and rawget(parent, '_child_fill_contract')
    if parent_contract ~= nil and parent_contract[axis_key] == true then
        return true
    end

    local node_contract = rawget(self, '_fill_parent_contract')
    if node_contract ~= nil and node_contract[axis_key] == true then
        return true
    end

    return false
end

local function resolve_fill_axis_size(self, axis_key, parent_size)
    if axis_fill_supported_by_parent(self, axis_key) then
        return parent_size or 0
    end

    local parent = rawget(self, 'parent')
    local parent_name = nil

    if parent ~= nil then
        parent_name = rawget(getmetatable(parent), '__name') or tostring(parent)
    elseif rawget(self, '_measurement_context_width') ~= nil or
        rawget(self, '_measurement_context_height') ~= nil then
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

local function resolve_measurement_axis_size(self, axis_key, configured, parent_size)
    if configured == 'fill' then
        return resolve_fill_axis_size(self, axis_key, parent_size)
    end

    return resolve_axis_size(configured, parent_size)
end

local function refresh_measurement(self)
    local parent_width
    local parent_height

    if self.parent then
        local parent_content_rect = self.parent:_get_effective_content_rect()
        parent_width = parent_content_rect.width
        parent_height = parent_content_rect.height
    else
        parent_width = rawget(self, '_measurement_context_width')
        parent_height = rawget(self, '_measurement_context_height')
    end

    local width = clamp_number(
        resolve_measurement_axis_size(self, 'width', get_effective_value(self, 'width'), parent_width),
        get_effective_value(self, 'minWidth'),
        get_effective_value(self, 'maxWidth')
    )
    local height = clamp_number(
        resolve_measurement_axis_size(self, 'height', get_effective_value(self, 'height'), parent_height),
        get_effective_value(self, 'minHeight'),
        get_effective_value(self, 'maxHeight')
    )

    rawset(self, '_resolved_width', width)
    rawset(self, '_resolved_height', height)
    rawset(self, '_local_bounds_cache', Rectangle(0, 0, width, height))
    rawset(self, '_measurement_dirty', false)
end

local function refresh_local_transform(self)
    local parent_width = 0
    local parent_height = 0

    if self.parent then
        local parent_content_rect = self.parent:_get_effective_content_rect()
        parent_width = parent_content_rect.width
        parent_height = parent_content_rect.height
    elseif rawget(self, '_measurement_context_width') ~= nil or
        rawget(self, '_measurement_context_height') ~= nil then
        parent_width = rawget(self, '_measurement_context_width') or 0
        parent_height = rawget(self, '_measurement_context_height') or 0
    end

    local width = rawget(self, '_resolved_width') or 0
    local height = rawget(self, '_resolved_height') or 0
    local pivot_x = (get_effective_value(self, 'pivotX') or 0) * width
    local pivot_y = (get_effective_value(self, 'pivotY') or 0) * height
    local anchor_x = (get_effective_value(self, 'anchorX') or 0) * parent_width
    local anchor_y = (get_effective_value(self, 'anchorY') or 0) * parent_height
    local layout_offset_x = rawget(self, '_layout_offset_x') or 0
    local layout_offset_y = rawget(self, '_layout_offset_y') or 0

    rawset(self, '_local_transform_cache', Matrix.from_transform(
        layout_offset_x + anchor_x + (get_effective_value(self, 'x') or 0),
        layout_offset_y + anchor_y + (get_effective_value(self, 'y') or 0),
        pivot_x,
        pivot_y,
        (get_effective_value(self, 'scaleX') or 1),
        (get_effective_value(self, 'scaleY') or 1),
        (get_effective_value(self, 'rotation') or 0),
        (get_effective_value(self, 'skewX') or 0),
        (get_effective_value(self, 'skewY') or 0)
    ))
    rawset(self, '_local_transform_dirty', false)
end

local function refresh_world_transform(self)
    local previous = rawget(self, '_world_transform_cache')
    local next_world = nil

    if self.parent then
        next_world = rawget(self.parent, '_world_transform_cache') * rawget(self, '_local_transform_cache')
    else
        next_world = rawget(self, '_local_transform_cache'):clone()
    end

    rawset(self, '_world_transform_cache', next_world)
    rawset(self, '_world_transform_dirty', false)
    rawset(self, '_world_inverse_dirty', true)

    if previous == nil or not previous:equals(next_world) then
        local children = rawget(self, '_children') or {}
        for index = 1, #children do
            local child = children[index]
            child:invalidate_world()
            child:invalidate_descendant_world()
        end
    end
end

local function refresh_bounds(self)
    local width = rawget(self, '_resolved_width') or 0
    local height = rawget(self, '_resolved_height') or 0
    local matrix = rawget(self, '_world_transform_cache')
    local x1, y1 = matrix:transform_point(0, 0)
    local x2, y2 = matrix:transform_point(width, 0)
    local x3, y3 = matrix:transform_point(width, height)
    local x4, y4 = matrix:transform_point(0, height)

    rawset(self, '_world_bounds_cache', Rectangle.bounding_box({
        { x = x1, y = y1 },
        { x = x2, y = y2 },
        { x = x3, y = y3 },
        { x = x4, y = y4 },
    }))
    rawset(self, '_bounds_dirty', false)
end

local function refresh_child_order_cache(self)
    if not rawget(self, '_child_order_dirty') and rawget(self, '_ordered_children') ~= nil then
        return
    end

    local children = rawget(self, '_children') or {}
    local decorated = {}

    for index = 1, #children do
        decorated[index] = {
            child = children[index],
            index = index,
        }
    end

    table.sort(decorated, function(left, right)
        local left_z_index = get_effective_value(left.child, 'zIndex') or 0
        local right_z_index = get_effective_value(right.child, 'zIndex') or 0

        if left_z_index == right_z_index then
            return left.index < right.index
        end

        return left_z_index < right_z_index
    end)

    local ordered = {}

    for index = 1, #decorated do
        ordered[index] = decorated[index].child
    end

    rawset(self, '_ordered_children', ordered)
    rawset(self, '_child_order_dirty', false)
end

function Container:mark_parent_order_dirty()
    if self.parent then
        rawset(self.parent, '_child_order_dirty', true)
    end
end

local function resolve_world_inverse(self)
    if rawget(self, '_world_inverse_dirty') then
        local matrix = rawget(self, '_world_transform_cache')
        local inv, err = matrix:inverse()
        rawset(self, '_world_inverse_cache', inv)
        rawset(self, '_world_inverse_error', err)
        rawset(self, '_world_inverse_dirty', false)
    end

    return rawget(self, '_world_inverse_cache'), rawget(self, '_world_inverse_error')
end

local function contains_world_point(self, x, y)
    local local_bounds = rawget(self, '_local_bounds_cache')
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

local function point_within_active_clips(active_clips, x, y)
    for index = 1, #active_clips do
        if not contains_world_point(active_clips[index], x, y) then
            return false
        end
    end

    return true
end

local function get_world_clip_points(self)
    local width = rawget(self, '_resolved_width') or 0
    local height = rawget(self, '_resolved_height') or 0
    local matrix = rawget(self, '_world_transform_cache')
    local x1, y1 = matrix:transform_point(0, 0)
    local x2, y2 = matrix:transform_point(width, 0)
    local x3, y3 = matrix:transform_point(width, height)
    local x4, y4 = matrix:transform_point(0, height)

    return {
        { x = x1, y = y1 },
        { x = x2, y = y2 },
        { x = x3, y = y3 },
        { x = x4, y = y4 },
    }
end

local function is_axis_aligned_edge(first, second)
    return abs(first.x - second.x) <= CLIP_EPSILON or
        abs(first.y - second.y) <= CLIP_EPSILON
end

local function is_axis_aligned_clip(self)
    local points = get_world_clip_points(self)

    return is_axis_aligned_edge(points[1], points[2]) and
        is_axis_aligned_edge(points[2], points[3]) and
        is_axis_aligned_edge(points[3], points[4]) and
        is_axis_aligned_edge(points[4], points[1])
end

local function get_world_clip_rect(self)
    return rawget(self, '_world_bounds_cache'):clone()
end

local function has_degenerate_clip(self)
    local local_bounds = rawget(self, '_local_bounds_cache')
    if local_bounds:is_empty() then
        return true
    end

    local matrix = rawget(self, '_world_transform_cache')
    return not matrix:is_invertible()
end

local function get_scissor_rect(graphics)
    if not Types.is_function(graphics.getScissor) then
        return nil
    end

    local x, y, width, height = graphics.getScissor()

    if x == nil or y == nil or width == nil or height == nil then
        return nil
    end

    return Rectangle(x, y, width, height)
end

local function set_scissor_rect(graphics, rect)
    if not Types.is_function(graphics.setScissor) then
        return
    end

    if rect == nil then
        graphics.setScissor()
        return
    end

    graphics.setScissor(rect.x, rect.y, rect.width, rect.height)
end

local function get_stencil_test(graphics)
    if not Types.is_function(graphics.getStencilTest) then
        return nil, nil
    end

    return graphics.getStencilTest()
end

local function set_stencil_test(graphics, compare, value)
    if not Types.is_function(graphics.setStencilTest) then
        return
    end

    if compare == nil then
        graphics.setStencilTest()
        return
    end

    graphics.setStencilTest(compare, value)
end

local function draw_clip_polygon(graphics, self)
    local points = get_world_clip_points(self)
    local flattened = {}

    for index = 1, #points do
        local point = points[index]
        flattened[#flattened + 1] = point.x
        flattened[#flattened + 1] = point.y
    end

    if Types.is_function(graphics.polygon) then
        graphics.polygon('fill', flattened)
    end
end

local draw_subtree

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

local function get_current_canvas(graphics)
    if not Types.is_function(graphics.getCanvas) then
        return nil
    end

    return graphics.getCanvas()
end

local function set_current_canvas(graphics, canvas)
    if not Types.is_function(graphics.setCanvas) then
        return
    end

    graphics.setCanvas(canvas)
end

local function get_current_color(graphics)
    if not Types.is_function(graphics.getColor) then
        return nil
    end

    return { graphics.getColor() }
end

local function restore_color(graphics, color)
    if color == nil or not Types.is_function(graphics.setColor) then
        return
    end

    graphics.setColor(color[1], color[2], color[3], color[4])
end

local function get_current_shader(graphics)
    if not Types.is_function(graphics.getShader) then
        return nil
    end

    return graphics.getShader()
end

local function restore_shader(graphics, shader)
    if not Types.is_function(graphics.setShader) then
        return
    end

    graphics.setShader(shader)
end

local function get_current_blend_mode(graphics)
    if not Types.is_function(graphics.getBlendMode) then
        return nil
    end

    return { graphics.getBlendMode() }
end

local function set_blend_mode(graphics, mode, alpha_mode)
    if not Types.is_function(graphics.setBlendMode) then
        return
    end

    if alpha_mode == nil and mode == 'multiply' then
        alpha_mode = 'premultiplied'
    end

    if alpha_mode ~= nil then
        graphics.setBlendMode(mode, alpha_mode)
        return
    end

    graphics.setBlendMode(mode)
end

local function restore_blend_mode(graphics, blend_mode)
    if blend_mode == nil or not Types.is_function(graphics.setBlendMode) then
        return
    end

    set_blend_mode(graphics, blend_mode[1], blend_mode[2])
end

local function clear_isolation_target(graphics)
    if Types.is_function(graphics.clear) then
        graphics.clear(0, 0, 0, 0)
    end
end

local function get_motion_surface_value(surface, key)
    if not Types.is_table(surface) then
        return nil
    end

    local state = rawget(surface, '_motion_visual_state')
    if state == nil then
        return nil
    end

    return state[key]
end

local function resolve_drawable_effects(self)
    if rawget(self, '_ui_drawable_instance') ~= true then
        return nil
    end

    local opacity = get_motion_surface_value(self, 'opacity')
    if opacity == nil then
        opacity = get_effective_value(self, 'opacity')
    end
    if opacity == nil then
        opacity = 1
    end

    local translation_x = get_motion_surface_value(self, 'translationX') or 0
    local translation_y = get_motion_surface_value(self, 'translationY') or 0
    local scale_x = get_motion_surface_value(self, 'scaleX')
    local scale_y = get_motion_surface_value(self, 'scaleY')
    local rotation = get_motion_surface_value(self, 'rotation') or 0

    if scale_x == nil then
        scale_x = 1
    end

    if scale_y == nil then
        scale_y = 1
    end

    return {
        shader = get_effective_value(self, 'shader'),
        opacity = opacity,
        blendMode = get_effective_value(self, 'blendMode'),
        mask = get_effective_value(self, 'mask'),
        translationX = translation_x,
        translationY = translation_y,
        scaleX = scale_x,
        scaleY = scale_y,
        rotation = rotation,
    }
end

local function drawable_requires_isolation(effects)
    if effects == nil then
        return false
    end

    return effects.shader ~= nil or
        effects.mask ~= nil or
        effects.blendMode ~= nil or
        effects.opacity ~= 1 or
        effects.translationX ~= 0 or
        effects.translationY ~= 0 or
        effects.scaleX ~= 1 or
        effects.scaleY ~= 1 or
        effects.rotation ~= 0
end

local function get_isolation_canvas_size(self)
    local root = get_root(self)

    if rawget(root, '_ui_stage_instance') == true then
        return math.max(1, math.ceil(root.width or 0)),
            math.max(1, math.ceil(root.height or 0))
    end

    local bounds = self:getWorldBounds()

    return math.max(1, math.ceil(math.max(bounds.width, bounds.x + bounds.width))),
        math.max(1, math.ceil(math.max(bounds.height, bounds.y + bounds.height)))
end

local function composite_isolated_subtree(self, graphics, canvas, effects, clip_state)
    if effects.mask ~= nil then
        Assert.fail(
            'Drawable mask rendering is not implemented by the current retained render path',
            3
        )
    end

    if effects.shader ~= nil and not Types.is_function(graphics.setShader) then
        Assert.fail('graphics adapter must support setShader for Drawable shader rendering', 3)
    end

    if effects.blendMode ~= nil and (
        not Types.is_function(graphics.setBlendMode) or
        not Types.is_function(graphics.getBlendMode)
    ) then
        Assert.fail('graphics adapter must support blend-mode save/restore for Drawable compositing', 3)
    end

    if not Types.is_function(graphics.draw) then
        Assert.fail('graphics adapter must support draw for isolated Drawable compositing', 3)
    end

    local previous_color = get_current_color(graphics)
    local previous_shader = get_current_shader(graphics)
    local previous_blend_mode = get_current_blend_mode(graphics)

    set_scissor_rect(graphics, clip_state.scissor)
    set_stencil_test(graphics, clip_state.stencil_compare, clip_state.stencil_value)

    if Types.is_function(graphics.setColor) then
        graphics.setColor(1, 1, 1, effects.opacity)
    end

    if effects.shader ~= nil then
        graphics.setShader(effects.shader)
    end

    if effects.blendMode ~= nil then
        set_blend_mode(graphics, effects.blendMode)
    end

    local draw_x = effects.translationX
    local draw_y = effects.translationY
    local rotation = effects.rotation
    local scale_x = effects.scaleX
    local scale_y = effects.scaleY

    if draw_x ~= 0 or draw_y ~= 0 or rotation ~= 0 or scale_x ~= 1 or scale_y ~= 1 then
        local bounds = rawget(self, '_local_bounds_cache') or self:getLocalBounds()
        local pivot_x = (get_effective_value(self, 'pivotX') or 0) * bounds.width
        local pivot_y = (get_effective_value(self, 'pivotY') or 0) * bounds.height
        local world_pivot_x, world_pivot_y = self:localToWorld(pivot_x, pivot_y)

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
    else
        graphics.draw(canvas, 0, 0)
    end

    restore_blend_mode(graphics, previous_blend_mode)
    restore_shader(graphics, previous_shader)
    restore_color(graphics, previous_color)
end

local function draw_isolated_subtree(self, graphics, draw_callback, clip_state, render_state, effects)
    if not Types.is_function(graphics.newCanvas) or
        not Types.is_function(graphics.setCanvas) or
        not Types.is_function(graphics.draw) then
        Assert.fail(
            'graphics adapter must support canvas isolation for Drawable render effects',
            3
        )
    end

    local pool = get_canvas_pool(graphics)
    local canvas_width, canvas_height = get_isolation_canvas_size(self)
    local canvas = pool:acquire(canvas_width, canvas_height)
    local previous_canvas = get_current_canvas(graphics)
    local previous_color = get_current_color(graphics)
    local previous_shader = get_current_shader(graphics)
    local previous_blend_mode = get_current_blend_mode(graphics)
    local previous_scissor = get_scissor_rect(graphics)
    local previous_stencil_compare, previous_stencil_value = get_stencil_test(graphics)

    set_current_canvas(graphics, canvas)

    if Types.is_function(graphics.origin) then
        graphics.origin()
    end

    clear_isolation_target(graphics)
    set_scissor_rect(graphics, nil)
    set_stencil_test(graphics, nil, nil)

    if Types.is_function(graphics.setColor) then
        graphics.setColor(1, 1, 1, 1)
    end

    if Types.is_function(graphics.setShader) then
        graphics.setShader()
    end

    if previous_blend_mode ~= nil then
        set_blend_mode(graphics, previous_blend_mode[1], previous_blend_mode[2])
    end

    draw_subtree(self, graphics, draw_callback, {
        active_clips = {},
        scissor = nil,
        stencil_compare = nil,
        stencil_value = nil,
    }, {
        suppress_effects_for = self,
    })

    set_current_canvas(graphics, previous_canvas)
    set_scissor_rect(graphics, previous_scissor)
    set_stencil_test(graphics, previous_stencil_compare, previous_stencil_value)
    composite_isolated_subtree(self, graphics, canvas, effects, clip_state)
    restore_blend_mode(graphics, previous_blend_mode)
    restore_shader(graphics, previous_shader)
    restore_color(graphics, previous_color)
    pool:release(canvas)

    return nil
end

draw_subtree = function(self, graphics, draw_callback, clip_state, render_state)
    if not get_effective_value(self, 'visible') then
        return nil
    end

    render_state = render_state or {}

    if render_state.suppress_effects_for ~= self then
        local effects = resolve_drawable_effects(self)

        if drawable_requires_isolation(effects) then
            return draw_isolated_subtree(
                self,
                graphics,
                draw_callback,
                clip_state,
                render_state,
                effects
            )
        end
    end

    local active_clips = clip_state.active_clips

    if get_effective_value(self, 'clipChildren') then
        if has_degenerate_clip(self) then
            local previous_scissor = clip_state.scissor

            clip_state.active_clips[#active_clips + 1] = self
            clip_state.scissor = Rectangle(0, 0, 0, 0)
            set_scissor_rect(graphics, clip_state.scissor)
            clip_state.active_clips[#clip_state.active_clips] = nil
            clip_state.scissor = previous_scissor
            set_scissor_rect(graphics, previous_scissor)
            return nil
        end

        local previous_scissor = clip_state.scissor
        local previous_stencil_compare = clip_state.stencil_compare
        local previous_stencil_value = clip_state.stencil_value

        clip_state.active_clips[#active_clips + 1] = self

        if is_axis_aligned_clip(self) then
            local combined = get_world_clip_rect(self)

            if previous_scissor ~= nil then
                combined = previous_scissor:intersection(combined)
            end

            clip_state.scissor = combined
            set_scissor_rect(graphics, combined)

            draw_callback(self)

            local ordered_children = rawget(self, '_ordered_children') or {}

            for index = 1, #ordered_children do
                draw_subtree(ordered_children[index], graphics, draw_callback, clip_state, render_state)
            end

            clip_state.active_clips[#clip_state.active_clips] = nil
            clip_state.scissor = previous_scissor
            set_scissor_rect(graphics, previous_scissor)
            return nil
        end

        local next_stencil_value = (clip_state.stencil_value or 0) + 1

        set_stencil_test(graphics, previous_stencil_compare, previous_stencil_value)

        if Types.is_function(graphics.stencil) then
            graphics.stencil(function()
                draw_clip_polygon(graphics, self)
            end, 'increment', 1, true)
        end

        clip_state.stencil_compare = 'equal'
        clip_state.stencil_value = next_stencil_value
        set_stencil_test(graphics, clip_state.stencil_compare, clip_state.stencil_value)

        draw_callback(self)

        local ordered_children = rawget(self, '_ordered_children') or {}

        for index = 1, #ordered_children do
            draw_subtree(ordered_children[index], graphics, draw_callback, clip_state, render_state)
        end

        set_stencil_test(graphics, 'equal', next_stencil_value)

        if Types.is_function(graphics.stencil) then
            graphics.stencil(function()
                draw_clip_polygon(graphics, self)
            end, 'decrement', 1, true)
        end

        clip_state.active_clips[#clip_state.active_clips] = nil
        clip_state.scissor = previous_scissor
        clip_state.stencil_compare = previous_stencil_compare
        clip_state.stencil_value = previous_stencil_value
        set_scissor_rect(graphics, previous_scissor)
        set_stencil_test(graphics, previous_stencil_compare, previous_stencil_value)
        return nil
    end

    draw_callback(self)

    local ordered_children = rawget(self, '_ordered_children') or {}

    for index = 1, #ordered_children do
        draw_subtree(ordered_children[index], graphics, draw_callback, clip_state, render_state)
    end

    return nil
end

local function find_hit_target(self, x, y, state)
    local effective_visible = state.effective_visible and
        get_effective_value(self, 'visible')

    if not effective_visible then
        return nil
    end

    if not point_within_active_clips(state.active_clips, x, y) then
        return nil
    end

    local effective_enabled = state.effective_enabled and
        get_effective_value(self, 'enabled')

    if not effective_enabled then
        return nil
    end

    local active_clips = state.active_clips
    local added_clip = false

    if get_effective_value(self, 'clipChildren') then
        if not contains_world_point(self, x, y) then
            return nil
        end

        active_clips[#active_clips + 1] = self
        added_clip = true
    end

    local ordered_children = rawget(self, '_ordered_children') or {}

    for index = #ordered_children, 1, -1 do
        local child = ordered_children[index]
        local target = find_hit_target(child, x, y, {
            active_clips = active_clips,
            effective_enabled = effective_enabled,
            effective_visible = effective_visible,
            layer_eligible = state.layer_eligible,
        })

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
        layer_eligible = state.layer_eligible,
    }) then
        target = self
    end

    if added_clip then
        active_clips[#active_clips] = nil
    end

    return target
end

local function set_public_value(self, key, value, level)
    value = validate_public_value(self, key, value, level or 1)

    local public_values = rawget(self, '_public_values')
    if public_values and public_values[key] == value then
        return value
    end

    if key == 'id' then
        local attachment_root = get_root(self)
        local previous_id = public_values and public_values[key] or nil
        if previous_id ~= nil then
            deregister_node_id_from_root(self, attachment_root)
        end

        validate_id_uniqueness_against_root(self, value, attachment_root, nil, (level or 1) + 1)

        if public_values then
            public_values[key] = value
        end
        local effective_values = rawget(self, '_effective_values')
        if effective_values then
            effective_values[key] = value
        end

        register_node_id_with_root(self, attachment_root)
        return value
    end

    if key == 'name' then
        validate_name_uniqueness(self, value, rawget(self, 'parent'), (level or 1) + 1)
    end

    if key == 'internal' then
        local attachment_root = get_root(self)
        local previous_internal = public_values and public_values[key] == true or false
        local next_internal = value == true

        if previous_internal == next_internal then
            return value
        end

        if not next_internal then
            local id = get_public_value(self, 'id')
            if id ~= nil then
                local index = attachment_root and rawget(attachment_root, '_id_index') or nil
                local existing = index and index[id] or nil
                if existing ~= nil and existing ~= self then
                    Assert.fail(
                        'duplicate id "' .. tostring(id) .. '" is invalid within one attachment root',
                        (level or 1) + 1
                    )
                end
            end

            local name = get_public_value(self, 'name')
            local parent = rawget(self, 'parent')
            if name ~= nil and parent ~= nil then
                local children = rawget(parent, '_children') or {}
                for index = 1, #children do
                    local sibling = children[index]
                    if sibling ~= self and is_public_node(sibling) and get_public_value(sibling, 'name') == name then
                        Assert.fail(
                            'duplicate sibling name "' .. tostring(name) .. '" is invalid',
                            (level or 1) + 1
                        )
                    end
                end
            end
        else
            deregister_node_id_from_root(self, attachment_root)
        end

        if public_values then
            public_values[key] = value
        end
        local effective_values = rawget(self, '_effective_values')
        if effective_values then
            effective_values[key] = value
        end

        if not next_internal then
            register_node_id_with_root(self, attachment_root)
        end

        self:invalidate_stage_update_token()
        return value
    end

    if public_values then
        public_values[key] = value
    end
    rawset(self, '_responsive_dirty', true)
    self:invalidate_stage_update_token()

    if key == 'breakpoints' then
        self:invalidate_ancestor_layouts()
        rawset(self, '_measurement_dirty', true)
        rawset(self, '_local_transform_dirty', true)
        self:invalidate_world()
        self:invalidate_descendant_geometry()
        return value
    end

    if MEASUREMENT_KEYS[key] then
        self:invalidate_ancestor_layouts()
        rawset(self, '_measurement_dirty', true)
        rawset(self, '_local_transform_dirty', true)
        self:invalidate_world()
        self:invalidate_descendant_geometry()
        return value
    end

    if key == 'visible' then
        self:invalidate_ancestor_layouts()
        return value
    end

    if LOCAL_TRANSFORM_KEYS[key] then
        rawset(self, '_local_transform_dirty', true)
        self:invalidate_world()
        self:invalidate_descendant_world()
        return value
    end

    if key == 'zIndex' then
        self:mark_parent_order_dirty()
    end

    return value
end
Container._set_public_value = set_public_value

local function detach_child(parent, child)
    local index = find_child_index(parent, child)

    if not index then
        return nil
    end

    local stage = get_root(parent)
    local old_attachment_root = get_root(child)
    deregister_subtree_ids(child, old_attachment_root)

    local children = rawget(parent, '_children')
    table.remove(children, index)
    rawset(parent, '_child_order_dirty', true)
    parent:invalidate_stage_update_token()
    parent:invalidate_ancestor_layouts()
    child.parent = nil
    rawset(child, '_layout_offset_x', 0)
    rawset(child, '_layout_offset_y', 0)
    rawset(child, '_responsive_dirty', true)
    rawset(child, '_measurement_dirty', true)
    rawset(child, '_local_transform_dirty', true)
    assign_attachment_root_recursive(child, child)
    rebuild_attachment_root_index(child)
    child:invalidate_world()
    child:invalidate_descendant_geometry()
    parent:notify_stage_subtree_change(stage, '_handle_detached_subtree', child, parent)
    return child
end

local function destroy_subtree(node)
    if rawget(node, '_destroyed') then
        return
    end

    if node.parent then
        detach_child(node.parent, node)
    end

    local children = rawget(node, '_children') or {}
    for index = #children, 1, -1 do
        local child = children[index]
        destroy_subtree(child)
    end

    rawset(node, '_ordered_children', nil)
    rawset(node, '_id_index', nil)
    rawset(node, '_attachment_root', nil)
    rawset(node, '_destroyed', true)
end

function Container:__index(key)
    -- Walk the class hierarchy for methods
    local val = walk_hierarchy(getmetatable(self), key)
    if val ~= nil then return val end

    local allowed_public_keys = rawget(self, '_allowed_public_keys')

    if allowed_public_keys and allowed_public_keys[key] then
        local public_values = rawget(self, '_public_values')
        return public_values and public_values[key]
    end

    return nil
end
Container.__index = Container.__index

function Container:__newindex(key, value)
    local allowed_public_keys = rawget(self, '_allowed_public_keys')

    if allowed_public_keys and allowed_public_keys[key] then
        set_public_value(self, key, value, 2)
        
        local rule = allowed_public_keys[key]
        if Types.is_table(rule) and Types.is_function(rule.set) then
            rule.set(self, value)
        end
        return
    end

    rawset(self, key, value)
end
Container.__newindex = Container.__newindex

function Container:_initialize(opts, extra_public_keys, config)
    opts = opts or {}
    config = config or {}

    rawset(self, '_config', config)
    local allowed_public_keys = Schema.merge(self._schema, extra_public_keys)
    local validated_opts = Schema.validate_all(allowed_public_keys, opts, self, 3, tostring(self))

    rawset(self, '_allowed_public_keys', allowed_public_keys)
    
    local initial_values = Schema.extract_defaults(allowed_public_keys, self, tostring(self))
    for key, value in pairs(validated_opts) do
        initial_values[key] = value
    end

    rawset(self, '_public_values', initial_values)
    rawset(self, '_effective_values', Utils.copy_table(initial_values))

    if initial_values.responsive ~= nil and initial_values.breakpoints ~= nil then
        Assert.fail('Supplying responsive and breakpoints together at construction should fail')
    end

    -- Core state required for all Container-based objects
    rawset(self, '_children', {})
    rawset(self, '_ordered_children', {})
    EventDispatcher.constructor(self)
    
    rawset(self, '_measurement_context_width', nil)
    rawset(self, '_measurement_context_height', nil)
    rawset(self, '_layout_offset_x', 0)
    rawset(self, '_layout_offset_y', 0)

    rawset(self, '_resolved_width', 0)
    rawset(self, '_resolved_height', 0)
    rawset(self, '_local_transform_cache', Matrix.identity())
    rawset(self, '_world_transform_cache', Matrix.identity())
    rawset(self, '_world_inverse_cache', nil)
    rawset(self, '_world_inverse_error', 'world transform is not invertible')
    rawset(self, '_local_bounds_cache', Rectangle(0, 0, 0, 0))
    rawset(self, '_world_bounds_cache', Rectangle(0, 0, 0, 0))
    rawset(self, '_ui_container_instance', true)
    rawset(self, '_attachment_root', self)
    rawset(self, '_id_index', {})

    rawset(self, '_destroyed', false)
    rawset(self, '_responsive_dirty', true)
    rawset(self, '_measurement_dirty', true)
    rawset(self, '_local_transform_dirty', true)
    rawset(self, '_world_transform_dirty', true)
    rawset(self, '_bounds_dirty', true)
    rawset(self, '_world_inverse_dirty', true)
    rawset(self, '_child_order_dirty', true)
    rawset(self, '_motion_visual_state', {})
    rawset(self, '_motion_last_request', nil)

    register_node_id_with_root(self, self)
end

function Container:constructor(opts, extra_public_keys, config)
    self:_initialize(opts, extra_public_keys, config)
end

function Container.new(opts)
    return Container(opts)
end

function Container._allow_fill_from_parent(node, axes)
    assert_live_container(node, 'node', 2)
    Assert.table('axes', axes, 2)

    rawset(node, '_fill_parent_contract', {
        width = axes.width == true,
        height = axes.height == true,
    })

    return node
end

function Container._allow_child_fill(node, axes)
    assert_live_container(node, 'node', 2)
    Assert.table('axes', axes, 2)

    rawset(node, '_child_fill_contract', {
        width = axes.width == true,
        height = axes.height == true,
    })

    return node
end

function Container:_refresh_if_dirty()
    assert_not_destroyed(self, 2)

    if rawget(self, '_responsive_dirty') then
        refresh_effective_values(self)
    end

    if rawget(self, '_measurement_dirty') then
        refresh_measurement(self)
    end

    if rawget(self, '_local_transform_dirty') then
        refresh_local_transform(self)
    end

    if rawget(self, '_world_transform_dirty') then
        refresh_world_transform(self)
    end

    if rawget(self, '_bounds_dirty') then
        refresh_bounds(self)
    end

    refresh_child_order_cache(self)
end

function Container:_prepare_for_layout_pass()
    assert_not_destroyed(self, 2)

    if rawget(self, '_responsive_dirty') then
        refresh_effective_values(self)
    end

    if rawget(self, '_measurement_dirty') then
        refresh_measurement(self)
    end

    refresh_child_order_cache(self)

    return self
end

function Container:update(_)
    assert_not_destroyed(self, 2)

    local root = get_root(self)
    local resolve_responsive_for_node = rawget(root, '_resolve_responsive_for_node')

    if Types.is_function(resolve_responsive_for_node) then
        resolve_responsive_for_node(root, self)
    end

    self:_refresh_if_dirty()

    local children = rawget(self, '_children') or {}
    local snapshot = {}

    for index = 1, #children do
        snapshot[index] = children[index]
    end

    for index = 1, #snapshot do
        local child = snapshot[index]

        if child ~= nil and child.parent == self and not rawget(child, '_destroyed') then
            child:update()
        end
    end

    if rawget(self, '_child_order_dirty') then
        refresh_child_order_cache(self)
    end

    return self
end

function Container:addChild(child)
    assert_not_destroyed(self, 2)
    assert_live_container(child, 'child', 2)
    assert_no_cycle(self, child, 2)

    if child.parent == self then
        return child
    end

    validate_subtree_attach_identity(self, child, 2)

    if child.parent then
        detach_child(child.parent, child)
    end

    child.parent = self
    local children = rawget(self, '_children')
    children[#children + 1] = child
    local attachment_root = get_root(self)
    assign_attachment_root_recursive(child, attachment_root)
    register_subtree_ids(child, attachment_root)
    rawset(self, '_child_order_dirty', true)
    self:invalidate_stage_update_token()
    self:invalidate_ancestor_layouts()

    rawset(child, '_responsive_dirty', true)
    rawset(child, '_measurement_dirty', true)
    rawset(child, '_bounds_dirty', true)
    rawset(child, '_local_transform_dirty', true)
    child:invalidate_world()
    child:invalidate_descendant_geometry()
    self:notify_stage_subtree_change(
        get_root(self),
        '_handle_attached_subtree',
        child,
        self
    )

    return child
end

function Container:removeChild(child)
    assert_not_destroyed(self, 2)
    assert_live_container(child, 'child', 2)

    return detach_child(self, child)
end

function Container:getChildren()
    return Utils.copy_array(rawget(self, '_children') or {})
end

function Container:findById(id, depth)
    assert_not_destroyed(self, 2)
    ensure_current(self)

    validate_lookup_key('Container.findById', 'id', id)
    depth = validate_depth_argument('Container.findById', depth, -1)

    if depth == 0 then
        if is_public_node(self) and get_public_value(self, 'id') == id then
            return self
        end
        return nil
    end

    if depth == -1 or depth == math.huge then
        local attachment_root = get_root(self)
        local index = attachment_root and rawget(attachment_root, '_id_index') or nil
        local candidate = index and index[id] or nil
        if candidate ~= nil and candidate ~= self and is_public_node(candidate) and is_strict_descendant_of(candidate, self) then
            return candidate
        end
        return nil
    end

    return find_by_id_bounded(self, id, depth)
end

function Container:findByTag(tag, depth)
    assert_not_destroyed(self, 2)
    ensure_current(self)

    validate_lookup_key('Container.findByTag', 'tag', tag)
    depth = validate_depth_argument('Container.findByTag', depth, 1)

    if depth == -1 then
        depth = math.huge
    end

    return find_by_tag_bounded(self, tag, depth, {})
end

function Container:_get_ordered_children()
    ensure_current(self)
    return Utils.copy_array(rawget(self, '_ordered_children') or {})
end

function Container:getWorldTransform()
    ensure_current(self)
    return rawget(self, '_world_transform_cache'):clone()
end

function Container:getLocalBounds()
    ensure_current(self)
    return rawget(self, '_local_bounds_cache'):clone()
end

function Container:getWorldBounds()
    ensure_current(self)
    return rawget(self, '_world_bounds_cache'):clone()
end

function Container:getBounds()
    return self:getWorldBounds()
end

function Container:localToWorld(x, y)
    ensure_current(self)
    local matrix = rawget(self, '_world_transform_cache')
    return matrix:transform_point(x, y)
end

function Container:worldToLocal(x, y)
    ensure_current(self)

    local inverse, inverse_error = resolve_world_inverse(self)

    if not inverse then
        Assert.fail(inverse_error or 'world transform is not invertible', 2)
    end

    return inverse:transform_point(x, y)
end

function Container:containsPoint(x, y)
    ensure_current(self)
    return contains_world_point(self, x, y)
end

function Container:_is_effectively_targetable(x, y, state)
    assert_not_destroyed(self, 2)

    state = state or {}

    local layer_eligible = state.layer_eligible
    local effective_visible = state.effective_visible
    local effective_enabled = state.effective_enabled
    local active_clips = state.active_clips or {}

    if layer_eligible == nil then
        layer_eligible = true
    end

    if effective_visible == nil then
        effective_visible = get_effective_value(self, 'visible')
    end

    if effective_enabled == nil then
        effective_enabled = get_effective_value(self, 'enabled')
    end

    if not layer_eligible or not effective_visible or not effective_enabled then
        return false
    end

    if not get_effective_value(self, 'interactive') then
        return false
    end

    if not point_within_active_clips(active_clips, x, y) then
        return false
    end

    return contains_world_point(self, x, y)
end

function Container:_hit_test(x, y, state)
    assert_not_destroyed(self, 2)
    ensure_current(self)

    return self:_hit_test_resolved(x, y, state)
end

function Container:_hit_test_resolved(x, y, state)
    assert_not_destroyed(self, 2)

    state = state or {}

    return find_hit_target(self, x, y, {
        active_clips = state.active_clips or {},
        effective_enabled = state.effective_enabled ~= false,
        effective_visible = state.effective_visible ~= false,
        layer_eligible = state.layer_eligible ~= false,
    })
end

function Container:_draw_subtree(graphics, draw_callback)
    assert_not_destroyed(self, 2)

    if draw_callback == nil and Types.is_function(graphics) then
        draw_callback = graphics
        graphics = nil
    end

    if graphics == nil then
        if love ~= nil and love.graphics ~= nil then
            graphics = love.graphics
        else
            Assert.fail(
                'graphics must be provided when love.graphics is unavailable',
                2
            )
        end
    end

    if not Types.is_table(graphics) then
        Assert.fail('graphics must be a graphics adapter table', 2)
    end

    if not Types.is_function(draw_callback) then
        Assert.fail('draw_callback must be a function', 2)
    end

    ensure_current(self)

    return self:_draw_subtree_resolved(graphics, draw_callback)
end

function Container:_draw_subtree_resolved(graphics, draw_callback)
    assert_not_destroyed(self, 2)

    if not Types.is_table(graphics) then
        Assert.fail('graphics must be a graphics adapter table', 2)
    end

    if not Types.is_function(draw_callback) then
        Assert.fail('draw_callback must be a function', 2)
    end

    local stencil_compare, stencil_value = get_stencil_test(graphics)

    draw_subtree(self, graphics, draw_callback, {
        active_clips = {},
        scissor = get_scissor_rect(graphics),
        stencil_compare = stencil_compare,
        stencil_value = stencil_value,
    })

    return self
end

function Container:markDirty()
    assert_not_destroyed(self, 2)
    self:invalidate_stage_update_token()
    rawset(self, '_responsive_dirty', true)
    rawset(self, '_measurement_dirty', true)
    rawset(self, '_local_transform_dirty', true)
    self:invalidate_world()
    self:invalidate_descendant_geometry()
    return self
end

function Container:_set_layout_offset(x, y)
    assert_not_destroyed(self, 2)
    Assert.number('x', x, 2)
    Assert.number('y', y, 2)

    if rawget(self, '_layout_offset_x') == x and rawget(self, '_layout_offset_y') == y then
        return self
    end

    rawset(self, '_layout_offset_x', x)
    rawset(self, '_layout_offset_y', y)
    rawset(self, '_local_transform_dirty', true)
    self:invalidate_world()
    self:invalidate_descendant_world()
    return self
end

function Container:_mark_parent_layout_dependency_dirty()
    assert_not_destroyed(self, 2)
    self:mark_layout_node_dirty()
    rawset(self, '_measurement_dirty', true)
    rawset(self, '_local_transform_dirty', true)
    self:invalidate_world()
    self:invalidate_descendant_geometry()
    return self
end

function Container:_get_effective_content_rect()
    assert_not_destroyed(self, 2)
    return Rectangle(
        0,
        0,
        rawget(self, '_resolved_width') or 0,
        rawget(self, '_resolved_height') or 0
    )
end

function Container:_set_measurement_context(width, height)
    assert_not_destroyed(self, 2)

    if width ~= nil then
        Assert.number('width', width, 2)
    end

    if height ~= nil then
        Assert.number('height', height, 2)
    end

    if rawget(self, '_measurement_context_width') == width and
        rawget(self, '_measurement_context_height') == height then
        return self
    end

    self:invalidate_stage_update_token()
    rawset(self, '_measurement_context_width', width)
    rawset(self, '_measurement_context_height', height)
    self:invalidate_ancestor_layouts()
    rawset(self, '_measurement_dirty', true)
    rawset(self, '_local_transform_dirty', true)
    self:invalidate_world()
    self:invalidate_descendant_geometry()
    return self
end

function Container:_set_resolved_responsive_overrides(token, overrides)
    assert_not_destroyed(self, 2)

    if overrides ~= nil then
        Assert.table('overrides', overrides, 2)

        local allowed_public_keys = rawget(self, '_allowed_public_keys')
        for key in pairs(overrides) do
            if not allowed_public_keys[key] then
                Assert.fail(
                    'responsive override "' .. tostring(key) ..
                        '" is not supported',
                    2
                )
            end
        end
    end

    if rawget(self, '_responsive_token') == token and rawget(self, '_responsive_overrides') == overrides then
        return self
    end

    self:invalidate_stage_update_token()
    rawset(self, '_responsive_token', token)
    rawset(self, '_responsive_overrides', overrides)
    self:invalidate_ancestor_layouts()
    rawset(self, '_responsive_dirty', true)
    rawset(self, '_measurement_dirty', true)
    rawset(self, '_local_transform_dirty', true)
    self:invalidate_world()
    self:invalidate_descendant_geometry()
    return self
end

function Container:destroy()
    destroy_subtree(self)
end

function Container:_get_motion_surface(target_name)
    if target_name == nil or target_name == 'root' then
        return self
    end

    local value = rawget(self, target_name)
    if Types.is_table(value) then
        return value
    end

    return nil
end

function Container:_apply_motion_value(target_name, property_name, value)
    local surface = self:_get_motion_surface(target_name)
    if surface == nil then
        Assert.fail('unknown motion surface "' .. tostring(target_name) .. '"', 2)
    end

    local state = rawget(surface, '_motion_visual_state')
    if state == nil then
        state = {}
        rawset(surface, '_motion_visual_state', state)
    end

    state[property_name] = value
    return surface
end

function Container:_get_motion_value(target_name, property_name)
    local surface = self:_get_motion_surface(target_name)
    if surface == nil then
        return nil
    end

    local state = rawget(surface, '_motion_visual_state') or {}
    return state[property_name]
end

function Container:_raise_motion(phase, payload)
    return Motion.request(self, phase, payload or {})
end

return Container
