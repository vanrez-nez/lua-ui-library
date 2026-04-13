local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local MathUtils = require('lib.ui.utils.math')
local Matrix = require('lib.ui.utils.matrix')
local Rectangle = require('lib.ui.core.rectangle')
local Object = require('lib.cls')
local Insets = require('lib.ui.core.insets')
local SideQuad = require('lib.ui.core.side_quad')
local CornerQuad = require('lib.ui.core.corner_quad')

local Schema = require('lib.ui.utils.schema')
local Proxy = require('lib.ui.utils.proxy')
local Reactive = require('lib.ui.utils.reactive')
local DirtyState = require('lib.ui.utils.dirty_state')
local Rule = require('lib.ui.utils.rule')
local Utils = require('lib.ui.utils.common')
local Motion = require('lib.ui.motion')
local GraphicsState = require('lib.ui.render.graphics_state')
local RootCompositor = require('lib.ui.render.root_compositor')
local RuntimeProfiler = require('profiler.runtime_profiler')
local CallCounterProfiler = require('profiler.call_counter_profiler')
local ContainerPropertyViews = require('lib.ui.core.container_property_views')

local abs = math.abs
local max = math.max
local min = math.min

local CLIP_EPSILON = 1e-9

local EventDispatcher = require('lib.ui.event.event_dispatcher')

local Container = EventDispatcher:extends('Container')

Container._schema = require('lib.ui.core.container_schema')

CallCounterProfiler.start_from_env({
    name = 'container',
    target = 'lib/ui/core/container.lua',
    enabled_env = 'UI_CALL_PROFILE_CONTAINER',
    output_env = 'UI_CALL_PROFILE_CONTAINER_OUTPUT',
    prefix = 'container-call-count-profile',
})

local LOCAL_TRANSFORM_KEYS = {
    anchorX = true, anchorY = true, pivotX = true, pivotY = true,
    x = true, y = true, scaleX = true, scaleY = true,
    rotation = true, skewX = true, skewY = true
}

local MEASUREMENT_KEYS = {
    width = true, height = true, minWidth = true, minHeight = true, maxWidth = true, maxHeight = true
}

local EFFECTIVE_QUAD_KEYS = {
    padding = true,
    paddingTop = true, paddingRight = true, paddingBottom = true, paddingLeft = true,
    margin = true,
    marginTop = true, marginRight = true, marginBottom = true, marginLeft = true,
    safeAreaInsets = true,
    borderWidth = true,
    borderWidthTop = true, borderWidthRight = true, borderWidthBottom = true, borderWidthLeft = true,
    cornerRadius = true,
    cornerRadiusTopLeft = true, cornerRadiusTopRight = true,
    cornerRadiusBottomRight = true, cornerRadiusBottomLeft = true,
}

local QUAD_FAMILIES = {
    padding = {
        kind = 'side',
        aggregate = 'padding',
        members = {
            top = 'paddingTop',
            right = 'paddingRight',
            bottom = 'paddingBottom',
            left = 'paddingLeft',
        },
        factory = function(top, right, bottom, left)
            return Insets.new(top, right, bottom, left)
        end,
    },
    margin = {
        kind = 'side',
        aggregate = 'margin',
        members = {
            top = 'marginTop',
            right = 'marginRight',
            bottom = 'marginBottom',
            left = 'marginLeft',
        },
        factory = function(top, right, bottom, left)
            return Insets.new(top, right, bottom, left)
        end,
    },
    safeAreaInsets = {
        kind = 'side',
        aggregate = 'safeAreaInsets',
        members = {},
        factory = function(top, right, bottom, left)
            return Insets.new(top, right, bottom, left)
        end,
    },
    borderWidth = {
        kind = 'side',
        aggregate = 'borderWidth',
        members = {
            top = 'borderWidthTop',
            right = 'borderWidthRight',
            bottom = 'borderWidthBottom',
            left = 'borderWidthLeft',
        },
    },
    cornerRadius = {
        kind = 'corner',
        aggregate = 'cornerRadius',
        members = {
            topLeft = 'cornerRadiusTopLeft',
            topRight = 'cornerRadiusTopRight',
            bottomRight = 'cornerRadiusBottomRight',
            bottomLeft = 'cornerRadiusBottomLeft',
        },
    },
}

local QUAD_KEY_TO_FAMILY = {
    padding = 'padding',
    paddingTop = 'padding',
    paddingRight = 'padding',
    paddingBottom = 'padding',
    paddingLeft = 'padding',
    margin = 'margin',
    marginTop = 'margin',
    marginRight = 'margin',
    marginBottom = 'margin',
    marginLeft = 'margin',
    safeAreaInsets = 'safeAreaInsets',
    borderWidth = 'borderWidth',
    borderWidthTop = 'borderWidth',
    borderWidthRight = 'borderWidth',
    borderWidthBottom = 'borderWidth',
    borderWidthLeft = 'borderWidth',
    cornerRadius = 'cornerRadius',
    cornerRadiusTopLeft = 'cornerRadius',
    cornerRadiusTopRight = 'cornerRadius',
    cornerRadiusBottomRight = 'cornerRadius',
    cornerRadiusBottomLeft = 'cornerRadius',
}

local get_scissor_rect = GraphicsState.get_scissor_rect
local set_scissor_rect = GraphicsState.set_scissor_rect
local get_stencil_test = GraphicsState.get_stencil_test
local set_stencil_test = GraphicsState.set_stencil_test

local function is_layout_node(node)
    return Object.is(node, "LayoutNode") or rawget(node, '_ui_layout_instance') == true
end

local default = MathUtils.default
local clamp_number = MathUtils.clamp_number
local resolve_axis_size = MathUtils.resolve_axis_size
local is_percentage_string = MathUtils.is_percentage_string

local function merge_schema(base, overrides)
    return Utils.merge_tables(Utils.copy_table(base or {}), overrides)
end

local function resolve_side_quad_layer(source, family)
    return {
        aggregate = source and source[family.aggregate] or nil,
        top = source and source[family.members.top] or nil,
        right = source and source[family.members.right] or nil,
        bottom = source and source[family.members.bottom] or nil,
        left = source and source[family.members.left] or nil,
    }
end

local function resolve_corner_quad_layer(source, family)
    return {
        aggregate = source and source[family.aggregate] or nil,
        topLeft = source and source[family.members.topLeft] or nil,
        topRight = source and source[family.members.topRight] or nil,
        bottomRight = source and source[family.members.bottomRight] or nil,
        bottomLeft = source and source[family.members.bottomLeft] or nil,
    }
end

local function find_child_index(parent, child)
    local children = parent._children
    for index = 1, #children do
        if children[index] == child then
            return index
        end
    end

    return nil
end

-- Removed manual key checks; Schemas handles extension directly.

function Container:invalidate_world()
    RootCompositor.invalidate_node_plan(self)
    self.dirty:mark('world_transform', 'bounds', 'world_inverse')
end

function Container:invalidate_descendant_world()
    local children = self._children
    for index = 1, #children do
        local child = children[index]
        child:invalidate_world()
        child:invalidate_descendant_world()
    end
end

function Container:invalidate_descendant_geometry()
    local children = self._children
    for index = 1, #children do
        local child = children[index]
        child.dirty:mark('responsive', 'measurement', 'local_transform')
        child:mark_layout_node_dirty()
        child:invalidate_world()
        child:invalidate_descendant_geometry()
    end
end

local function assert_live_container(node, name, level)
    local is_container = Object.is(node, "Container") or (type(node) == 'table' and node._ui_container_instance)
    if not is_container then
        Assert.fail(name .. ' must be a Container', level or 1)
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
    local attachment_root = node._attachment_root
    if attachment_root ~= nil then
        return attachment_root
    end

    local current = node
    while current.parent do current = current.parent end
    return current
end

local function responsive_overrides_affect_root_compositing_plan(self, previous_overrides, next_overrides)
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

local function is_internal_node(node)
    return Proxy.raw_get(node, 'internal') == true
end

local function is_public_node(node)
    return not is_internal_node(node)
end

local function is_strict_descendant_of(node, ancestor)
    local current = node.parent
    while current ~= nil do
        if current == ancestor then
            return true
        end
        current = current.parent
    end

    return false
end

local function is_in_same_or_descendant_subtree(node, root)
    return node == root or is_strict_descendant_of(node, root)
end

local function assign_attachment_root_recursive(node, attachment_root)
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

local function register_node_id_with_root(node, attachment_root)
    if not is_public_node(node) then
        return
    end

    local id = Proxy.raw_get(node, 'id')
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

local function register_subtree_ids(node, attachment_root)
    register_node_id_with_root(node, attachment_root)

    local children = node._children
    for index = 1, #children do
        register_subtree_ids(children[index], attachment_root)
    end
end

local function deregister_node_id_from_root_value(node, attachment_root, id)
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

local function deregister_node_id_from_root(node, attachment_root)
    deregister_node_id_from_root_value(node, attachment_root, Proxy.raw_get(node, 'id'))
end

local function deregister_subtree_ids(node, attachment_root)
    deregister_node_id_from_root(node, attachment_root)

    local children = node._children
    for index = 1, #children do
        deregister_subtree_ids(children[index], attachment_root)
    end
end

local function rebuild_attachment_root_index(root)
    root._id_index = {}
    assign_attachment_root_recursive(root, root)
    register_subtree_ids(root, root)
end

local function find_sibling_name_collision(node, name, parent)
    if name == nil or parent == nil or not is_public_node(node) then
        return nil
    end

    local children = parent._children
    for index = 1, #children do
        local sibling = children[index]
        if sibling ~= node and is_public_node(sibling) and Proxy.raw_get(sibling, 'name') == name then
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
        local id = Proxy.raw_get(node, 'id')
        if id ~= nil then
            local existing = state.ids[id]
            if existing ~= nil and existing ~= node then
                Assert.fail('duplicate id "' .. tostring(id) .. '" is invalid', 3)
            end
            state.ids[id] = node
        end
    end

    local children = node._children
    for index = 1, #children do
        collect_public_subtree_identity(children[index], state)
    end

    return state
end

local function validate_id_uniqueness_against_root(node, id, attachment_root, ignored_nodes, level)
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

local function validate_subtree_attach_identity(parent, child, level)
    local target_root = get_root(parent)
    local subtree_identity = collect_public_subtree_identity(child)

    for id, node in pairs(subtree_identity.ids) do
        validate_id_uniqueness_against_root(node, id, target_root, subtree_identity.nodes, level)
    end

    if is_public_node(child) then
        validate_name_uniqueness(child, Proxy.raw_get(child, 'name'), parent, level)
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

    local children = node._children
    for index = 1, #children do
        local child = children[index]
        if is_public_node(child) and Proxy.raw_get(child, 'id') == id then
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
        if is_public_node(node) and Proxy.raw_get(node, 'tag') == tag then
            results[#results + 1] = node
        end
        return results
    end

    local children = node._children
    for index = 1, #children do
        local child = children[index]
        if is_public_node(child) and Proxy.raw_get(child, 'tag') == tag then
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
    if not Object.is(stage, "Stage") then
        return
    end

    if child._destroying_subtree == true or
        parent._destroying_subtree == true or
        stage._destroying_subtree == true then
        return
    end

    local handler = stage[handler_name]
    if Types.is_function(handler) then
        handler(stage, child, parent)
    end
end

function Container:invalidate_stage_update_token()
    local root = get_root(self)

    if rawget(root, '_ui_stage_instance') == true then
        rawset(root, '_update_ran', false)
    end
end

function Container:mark_layout_node_dirty()
    if not is_layout_node(self) then
        return false
    end

    if self.dirty:is_dirty('layout') then
        return false
    end

    self.dirty:mark('layout')
    self:invalidate_stage_update_token()

    return true
end

function Container:invalidate_ancestor_layouts()
    local current = self

    while current ~= nil do
        Container.mark_layout_node_dirty(current)
        current = rawget(current, 'parent')
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

local function get_declared_rule(self, key)
    local declared_props = self._declared_props
    return declared_props[key]
end

local function validate_public_value(self, key, value, level, opts)
    local rule = get_declared_rule(self, key)
    if rule == true then
        return value
    end
    local full_key = tostring(self) .. '.' .. tostring(key)
    return Rule.validate(rule, full_key, value, self, (level or 1) + 1, opts)
end

local function resolve_quad_value(self, family_name, requested_key)
    local family = QUAD_FAMILIES[family_name]
    local overrides = self._resolved_responsive_overrides

    if family.kind == 'corner' then
        local resolved = CornerQuad.resolve_layers({
            resolve_corner_quad_layer(overrides, family),
            resolve_corner_quad_layer(self._pdata, family),
        }, {
            label = family.aggregate,
        }, 3)

        if resolved == nil then
            return nil
        end

        if requested_key == family.aggregate then
            return resolved
        end

        if requested_key == family.members.topLeft then
            return resolved.topLeft
        end

        if requested_key == family.members.topRight then
            return resolved.topRight
        end

        if requested_key == family.members.bottomRight then
            return resolved.bottomRight
        end

        if requested_key == family.members.bottomLeft then
            return resolved.bottomLeft
        end

        return nil
    end

    local resolved = SideQuad.resolve_layers({
        resolve_side_quad_layer(overrides, family),
        resolve_side_quad_layer(self._pdata, family),
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

    if requested_key == family.members.top then
        return resolved.top
    end

    if requested_key == family.members.right then
        return resolved.right
    end

    if requested_key == family.members.bottom then
        return resolved.bottom
    end

    if requested_key == family.members.left then
        return resolved.left
    end

    return nil
end

local function get_effective_value(self, key)
    local family_name = QUAD_KEY_TO_FAMILY[key]
    if family_name ~= nil then
        return resolve_quad_value(self, family_name, key)
    end

    local overrides = self._resolved_responsive_overrides
    if overrides ~= nil and overrides[key] ~= nil then
        return overrides[key]
    end

    return Proxy.raw_get(self, key)
end
Container._get_public_read_value = get_effective_value

local function axis_fill_supported_by_parent(self, axis_key)
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

local function resolve_fill_axis_size(self, axis_key, parent_size)
    if axis_fill_supported_by_parent(self, axis_key) then
        return parent_size or 0
    end

    local parent = self.parent
    local parent_name = nil

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
        parent_width = self._measurement_context_width
        parent_height = self._measurement_context_height
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

    self._resolved_width = width
    self._resolved_height = height
    self._local_bounds_cache = Rectangle(0, 0, width, height)
    self.dirty:clear('measurement')
end

local function refresh_local_transform(self)
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

    local width = self._resolved_width or 0
    local height = self._resolved_height or 0
    local pivot_x = (get_effective_value(self, 'pivotX') or 0.5) * width
    local pivot_y = (get_effective_value(self, 'pivotY') or 0.5) * height
    local anchor_x = (get_effective_value(self, 'anchorX') or 0) * parent_width
    local anchor_y = (get_effective_value(self, 'anchorY') or 0) * parent_height
    local layout_offset_x = self._layout_offset_x or 0
    local layout_offset_y = self._layout_offset_y or 0

    local position_x = layout_offset_x + anchor_x + (get_effective_value(self, 'x') or 0)
    local position_y = layout_offset_y + anchor_y + (get_effective_value(self, 'y') or 0)

    local local_transform = self._local_transform_cache
    local_transform:set_from_transform(
        position_x + pivot_x,
        position_y + pivot_y,
        pivot_x,
        pivot_y,
        (get_effective_value(self, 'scaleX') or 1),
        (get_effective_value(self, 'scaleY') or 1),
        (get_effective_value(self, 'rotation') or 0),
        (get_effective_value(self, 'skewX') or 0),
        (get_effective_value(self, 'skewY') or 0)
    )
    self.dirty:clear('local_transform')
end

local function refresh_world_transform(self)
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

    local changed =
        previous.a ~= next_a or
        previous.b ~= next_b or
        previous.c ~= next_c or
        previous.d ~= next_d or
        previous.tx ~= next_tx or
        previous.ty ~= next_ty

    previous:set(next_a, next_b, next_c, next_d, next_tx, next_ty)
    self.dirty:clear('world_transform')
    self.dirty:mark('world_inverse')

    if changed then
        local children = self._children
        for index = 1, #children do
            local child = children[index]
            child:invalidate_world()
            child:invalidate_descendant_world()
        end
    end
end

local function refresh_bounds(self)
    local resolve_world_bounds_points = walk_hierarchy(self._pclass or getmetatable(self), '_get_world_bounds_points')
    if Types.is_function(resolve_world_bounds_points) then
        local points = resolve_world_bounds_points(self)
        if Types.is_table(points) and #points > 0 then
            self._world_bounds_cache = Rectangle.bounding_box(points)
            self.dirty:clear('bounds')
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
    self.dirty:clear('bounds')
end

local function refresh_child_order_cache(self)
    if not self.dirty:is_dirty('child_order') and self._ordered_children ~= nil then
        return
    end

    local children = self._children
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

    self._ordered_children = ordered
    self.dirty:clear('child_order')
end

function Container:mark_parent_order_dirty()
    if self.parent then
        self.parent.dirty:mark('child_order')
    end
end

local function resolve_world_inverse(self)
    if self.dirty:is_dirty('world_inverse') then
        local matrix = self._world_transform_cache
        local inv, err = matrix:inverse()
        self._world_inverse_cache = inv
        self._world_inverse_error = err
        self.dirty:clear('world_inverse')
    end

    return self._world_inverse_cache, self._world_inverse_error
end

local function contains_world_point(self, x, y)
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

local function point_within_active_clips(active_clips, x, y)
    for index = 1, #active_clips do
        if not contains_world_point(active_clips[index], x, y) then
            return false
        end
    end

    return true
end

local function get_world_clip_points(self, points)
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

local function is_axis_aligned_edge(first, second)
    return abs(first.x - second.x) <= CLIP_EPSILON or
        abs(first.y - second.y) <= CLIP_EPSILON
end

local function is_axis_aligned_clip(self, clip_state)
    local points = get_world_clip_points(self, clip_state and clip_state.axis_clip_points_scratch or nil)

    if clip_state ~= nil then
        clip_state.axis_clip_points_scratch = points
    end

    return is_axis_aligned_edge(points[1], points[2]) and
        is_axis_aligned_edge(points[2], points[3]) and
        is_axis_aligned_edge(points[3], points[4]) and
        is_axis_aligned_edge(points[4], points[1])
end

local function get_world_clip_rect(self)
    return self._world_bounds_cache
end

local function has_degenerate_clip(self)
    local local_bounds = self._local_bounds_cache
    if local_bounds:is_empty() then
        return true
    end

    local matrix = self._world_transform_cache
    return not matrix:is_invertible()
end

local function clear_array_tail(values, last_index)
    for index = #values, last_index + 1, -1 do
        values[index] = nil
    end
end

local function get_empty_scissor_rect(clip_state)
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

local function get_scissor_scratch_rect(clip_state, depth)
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

local function copy_rect_into(target, source)
    target.x = source.x or 0
    target.y = source.y or 0
    target.width = source.width or 0
    target.height = source.height or 0
    return target
end

local function intersect_rect_into(target, first, second)
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

local function resolve_axis_aligned_scissor(clip_state, clip_rect)
    local depth = #clip_state.active_clips
    -- Each clip depth gets its own rect scratch so nested branches can restore parent scissor state.
    local combined = get_scissor_scratch_rect(clip_state, depth)
    local previous_scissor = clip_state.scissor

    if previous_scissor ~= nil then
        return intersect_rect_into(combined, previous_scissor, clip_rect)
    end

    return copy_rect_into(combined, clip_rect)
end

local function draw_clip_polygon(graphics, self, clip_state)
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

local draw_subtree

function Container:_resolve_root_compositing_extras()
    return nil
end

function Container:_resolve_root_compositing_world_paint_bounds()
    return nil
end

function Container:_resolve_root_compositing_result_clip()
    return nil
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
        return draw_subtree(node, graphics, draw_callback, clip_state, render_state)
    end,
}

draw_subtree = function(self, graphics, draw_callback, clip_state, render_state)
    if not get_effective_value(self, 'visible') then
        return nil
    end

    render_state = RootCompositor.initialize_render_state(graphics, render_state)

    if render_state.suppress_root_compositing_for ~= self then
        local effects = RootCompositor.resolve_node_plan(self, ROOT_COMPOSITOR_RUNTIME)

        if RootCompositor.plan_requires_isolation(effects) then
            return RootCompositor.draw_isolated_subtree(
                self,
                graphics,
                draw_callback,
                clip_state,
                render_state,
                effects,
                ROOT_COMPOSITOR_RUNTIME
            )
        end
    end

    local active_clips = clip_state.active_clips

    if get_effective_value(self, 'clipChildren') then
        local clip_profile_token = RuntimeProfiler.push_zone('Container.draw_subtree.clip_children')
        if has_degenerate_clip(self) then
            local previous_scissor = clip_state.scissor

            clip_state.active_clips[#active_clips + 1] = self
            clip_state.scissor = get_empty_scissor_rect(clip_state)
            set_scissor_rect(graphics, clip_state.scissor)
            clip_state.active_clips[#clip_state.active_clips] = nil
            clip_state.scissor = previous_scissor
            set_scissor_rect(graphics, previous_scissor)
            RuntimeProfiler.pop_zone(clip_profile_token)
            return nil
        end

        local previous_scissor = clip_state.scissor
        local previous_stencil_compare = clip_state.stencil_compare
        local previous_stencil_value = clip_state.stencil_value

        clip_state.active_clips[#active_clips + 1] = self

        if is_axis_aligned_clip(self, clip_state) then
            local combined = resolve_axis_aligned_scissor(clip_state, get_world_clip_rect(self))

            clip_state.scissor = combined
            set_scissor_rect(graphics, combined)

            draw_callback(self)

            local ordered_children = self._ordered_children

            for index = 1, #ordered_children do
                draw_subtree(ordered_children[index], graphics, draw_callback, clip_state, render_state)
            end

            clip_state.active_clips[#clip_state.active_clips] = nil
            clip_state.scissor = previous_scissor
            set_scissor_rect(graphics, previous_scissor)
            RuntimeProfiler.pop_zone(clip_profile_token)
            return nil
        end

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

        local ordered_children = self._ordered_children

        for index = 1, #ordered_children do
            draw_subtree(ordered_children[index], graphics, draw_callback, clip_state, render_state)
        end

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
        RuntimeProfiler.pop_zone(clip_profile_token)
        return nil
    end

    draw_callback(self)

    local ordered_children = self._ordered_children

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

    local ordered_children = self._ordered_children

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

local function validate_id_write(_, value, target)
    validate_id_uniqueness_against_root(
        target,
        value,
        get_root(target),
        { [target] = true },
        4
    )
    return value
end

local function handle_id_change(new, old, _, target)
    local attachment_root = get_root(target)
    if old ~= nil then
        deregister_node_id_from_root_value(target, attachment_root, old)
    end
    if new ~= nil then
        register_node_id_with_root(target, attachment_root)
    end
end

local function validate_name_write(_, value, target)
    validate_name_uniqueness(target, value, target.parent, 4)
    return value
end

local function validate_internal_write(_, value, target)
    local next_internal = value == true
    if next_internal then
        return value
    end

    local attachment_root = get_root(target)
    validate_id_uniqueness_against_root(
        target,
        Proxy.raw_get(target, 'id'),
        attachment_root,
        { [target] = true },
        4
    )
    validate_name_uniqueness(
        target,
        Proxy.raw_get(target, 'name'),
        target.parent,
        4
    )
    return value
end

local function handle_internal_change(new, old, _, target)
    local attachment_root = get_root(target)
    local was_internal = old == true
    local is_internal = new == true

    if was_internal == is_internal then
        return
    end

    local id = Proxy.raw_get(target, 'id')
    if was_internal and not is_internal then
        if id ~= nil then
            register_node_id_with_root(target, attachment_root)
        end
    else
        if id ~= nil then
            deregister_node_id_from_root_value(target, attachment_root, id)
        end
    end

    Container.invalidate_stage_update_token(target)
end

local function install_identity_hooks(self)
    Proxy.on_pre_write(self, 'id', validate_id_write)
    Proxy.on_change(self, 'id', handle_id_change)
    Proxy.on_pre_write(self, 'name', validate_name_write)
    Proxy.on_pre_write(self, 'internal', validate_internal_write)
    Proxy.on_change(self, 'internal', handle_internal_change)
end

local function handle_public_prop_change(self, key)
    Container.invalidate_stage_update_token(self)
    local has_responsive_surface =
        self.responsive ~= nil or
        self.breakpoints ~= nil

    if key == 'responsive' or key == 'breakpoints' or has_responsive_surface then
        self.dirty:mark('responsive')
    end

    if RootCompositor.property_affects_node_plan(self, key) or
        key == 'breakpoints' or
        key == 'responsive' then
        RootCompositor.invalidate_node_plan(self)
    end

    if key == 'breakpoints' or MEASUREMENT_KEYS[key] then
        Container.invalidate_ancestor_layouts(self)
        self.dirty:mark('measurement', 'local_transform')
        Container.invalidate_world(self)
        Container.invalidate_descendant_geometry(self)
        return
    end

    if key == 'visible' then
        Container.invalidate_ancestor_layouts(self)
        return
    end

    if LOCAL_TRANSFORM_KEYS[key] then
        self.dirty:mark('local_transform')
        Container.invalidate_world(self)
        Container.invalidate_descendant_world(self)
        return
    end

    if key == 'zIndex' then
        Container.mark_parent_order_dirty(self)
    end
end

local function handle_public_prop_watch(_, _, watched_key, target)
    handle_public_prop_change(target, watched_key)
end

local function read_responsive_effective_value(_, read_key, target)
    return get_effective_value(target, read_key)
end

local function install_responsive_read_hooks(self, declared_props)
    for key, rule in pairs(declared_props) do
        if type(rule) == 'table' then
            Proxy.on_read(self, key, read_responsive_effective_value)
        end
    end
end

local function install_public_prop_watchers(self, declared_props)
    local props = self.props

    for key, rule in pairs(declared_props) do
        if type(rule) == 'table' and key ~= 'id' and key ~= 'name' and key ~= 'internal' then
            props:watch(key, handle_public_prop_watch)
        end
    end
end

local function detach_child(parent, child)
    local index = find_child_index(parent, child)

    if not index then
        return nil
    end

    local stage = get_root(parent)
    local old_attachment_root = get_root(child)
    deregister_subtree_ids(child, old_attachment_root)

    local children = parent._children
    table.remove(children, index)
    parent.dirty:mark('child_order')
    parent:invalidate_stage_update_token()
    parent:invalidate_ancestor_layouts()
    child.parent = nil
    child._layout_offset_x = 0
    child._layout_offset_y = 0
    child.dirty:mark('responsive', 'measurement', 'local_transform')
    assign_attachment_root_recursive(child, child)
    rebuild_attachment_root_index(child)
    child:invalidate_world()
    child:invalidate_descendant_geometry()
    parent:notify_stage_subtree_change(stage, '_handle_detached_subtree', child, parent)
    return child
end

local function destroy_subtree(node)
    rawset(node, '_destroying_subtree', true)

    if node.parent then
        detach_child(node.parent, node)
    end

    local children = node._children
    for index = #children, 1, -1 do
        local child = children[index]
        child:destroy()
    end
    node._children = nil
    node._ordered_children = nil
    node._id_index = nil
    node._attachment_root = nil
end

function Container:_initialize(opts, extra_public_keys, config)
    opts = opts or {}
    config = config or {}

    rawset(self, '_config', config)
    local declared_props = merge_schema(self._schema, extra_public_keys)
    local proxied_props = {}

    for key, rule in pairs(declared_props) do
        if type(rule) == 'table' then
            proxied_props[key] = rule
        end
    end

    if opts.responsive ~= nil and opts.breakpoints ~= nil then
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
    rawset(self, '_declared_props', declared_props)
    rawset(self, '_resolved_responsive_overrides', {})

    rawset(self, '_motion_visual_state', {})
    rawset(self, '_motion_last_request', nil)

    rawset(self, 'dirty', DirtyState({
        'responsive',
        'measurement',
        'local_transform',
        'world_transform',
        'bounds',
        'child_order',
        'layout',
        'world_inverse',
    }))
    rawset(self, 'props', Reactive(self))
    rawset(self, 'schema', Schema(self))

    ContainerPropertyViews.install(self, {
        public = function(instance, key)
            if instance._declared_props[key] ~= nil then
                return Proxy.raw_get(instance, key)
            end
            return rawget(instance, key)
        end,
        effective = function(instance, key)
            if instance._declared_props[key] ~= nil then
                return get_effective_value(instance, key)
            end
            return rawget(instance, key)
        end,
    })

    self.schema:define(proxied_props)
    install_identity_hooks(self)
    install_responsive_read_hooks(self, proxied_props)
    install_public_prop_watchers(self, proxied_props)

    for key, value in pairs(opts) do
        if declared_props[key] == nil then
            Assert.fail('Unsupported prop "' .. tostring(key) .. '"', 3)
        end

        if proxied_props[key] ~= nil then
            self[key] = value
        else
            ContainerPropertyViews.write_extra(self, key, value)
        end
    end

    self.dirty:mark(
        'responsive',
        'measurement',
        'local_transform',
        'world_transform',
        'bounds',
        'child_order',
        'world_inverse'
    )

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

    node._fill_parent_contract = {
        width = axes.width == true,
        height = axes.height == true,
    }

    return node
end

function Container._allow_child_fill(node, axes)
    assert_live_container(node, 'node', 2)
    Assert.table('axes', axes, 2)

    node._child_fill_contract = {
        width = axes.width == true,
        height = axes.height == true,
    }

    return node
end

local function refresh_responsive(self)
    self.dirty:clear('responsive')
end

function Container:_apply_resolved_size(width, height)
    local resolved_width = default(width, self._resolved_width or 0)
    local resolved_height = default(height, self._resolved_height or 0)

    if self._resolved_width == resolved_width and
        self._resolved_height == resolved_height then
        self.dirty:clear('measurement')
        return false
    end

    self._resolved_width = resolved_width
    self._resolved_height = resolved_height
    self._local_bounds_cache = Rectangle(0, 0, resolved_width, resolved_height)
    self.dirty:clear('measurement')
    self.dirty:mark('local_transform')
    self:invalidate_world()

    if self._ui_layout_instance == true and
        Types.is_function(self._refresh_layout_content_rect) then
        self:_refresh_layout_content_rect()
        self:mark_layout_node_dirty()
    end

    local children = self._children
    for index = 1, #children do
        children[index]:_mark_parent_layout_dependency_dirty()
    end

    return true
end

function Container:_apply_content_measurement(width, height)
    local effective_width = self._resolved_width or 0
    local effective_height = self._resolved_height or 0

    if get_effective_value(self, 'width') == 'content' then
        effective_width = clamp_number(
            width or 0,
            get_effective_value(self, 'minWidth'),
            get_effective_value(self, 'maxWidth')
        )
    end

    if get_effective_value(self, 'height') == 'content' then
        effective_height = clamp_number(
            height or 0,
            get_effective_value(self, 'minHeight'),
            get_effective_value(self, 'maxHeight')
        )
    end

    return self:_apply_resolved_size(effective_width, effective_height)
end

function Container:_refresh_if_dirty()

    if self.dirty:is_dirty('responsive') then
        refresh_responsive(self)
    end

    if self.dirty:is_dirty('measurement') then
        refresh_measurement(self)
    end

    if self.dirty:is_dirty('local_transform') then
        refresh_local_transform(self)
    end

    if self.dirty:is_dirty('world_transform') then
        refresh_world_transform(self)
    end

    if self.dirty:is_dirty('bounds') then
        refresh_bounds(self)
    end

    if self.dirty:is_dirty('child_order') then
        refresh_child_order_cache(self)
    end
end

function Container:_prepare_for_layout_pass()

    if self.dirty:is_dirty('responsive') then
        refresh_responsive(self)
    end

    if self.dirty:is_dirty('measurement') then
        refresh_measurement(self)
    end

    if self.dirty:is_dirty('child_order') then
        refresh_child_order_cache(self)
    end

    return self
end

function Container:update(_)

    local root = get_root(self)
    local resolve_responsive_for_node = root._resolve_responsive_for_node
    local stage_managed_update = root._ui_stage_instance == true and root._updating == true

    if not stage_managed_update and Types.is_function(resolve_responsive_for_node) then
        resolve_responsive_for_node(root, self)
    end

    self:_refresh_if_dirty()

    local children = self._children
    local snapshot = {}

    for index = 1, #children do
        snapshot[index] = children[index]
    end

    for index = 1, #snapshot do
        local child = snapshot[index]

        if child.parent == self then
            child:update()
        end
    end

    if self.dirty:is_dirty('child_order') then
        refresh_child_order_cache(self)
    end

    return self
end

function Container:addChild(child)
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
    local children = self._children
    children[#children + 1] = child
    local attachment_root = get_root(self)
    assign_attachment_root_recursive(child, attachment_root)
    register_subtree_ids(child, attachment_root)
    self.dirty:mark('child_order')
    self:invalidate_stage_update_token()
    self:invalidate_ancestor_layouts()

    child.dirty:mark('responsive', 'measurement', 'bounds', 'local_transform')
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
    assert_live_container(child, 'child', 2)

    return detach_child(self, child)
end

function Container:getChildren()
    return Utils.copy_array(self._children)
end

function Container:findById(id, depth)
    ensure_current(self)

    validate_lookup_key('Container.findById', 'id', id)
    depth = validate_depth_argument('Container.findById', depth, -1)

    if depth == 0 then
        if is_public_node(self) and Proxy.raw_get(self, 'id') == id then
            return self
        end
        return nil
    end

    if depth == -1 or depth == math.huge then
        local attachment_root = get_root(self)
        local index = attachment_root and attachment_root._id_index or nil
        local candidate = index and index[id] or nil
        if candidate ~= nil and candidate ~= self and is_public_node(candidate) and is_strict_descendant_of(candidate, self) then
            return candidate
        end
        return nil
    end

    return find_by_id_bounded(self, id, depth)
end

function Container:findByTag(tag, depth)
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
    return Utils.copy_array(self._ordered_children)
end

function Container:getWorldTransform()
    ensure_current(self)
    return self._world_transform_cache:clone()
end

function Container:getLocalBounds()
    ensure_current(self)
    return self._local_bounds_cache:clone()
end

function Container:getWorldBounds()
    ensure_current(self)
    return self._world_bounds_cache:clone()
end

function Container:getBounds()
    return self:getWorldBounds()
end

function Container:localToWorld(x, y)
    ensure_current(self)
    local matrix = self._world_transform_cache
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
    ensure_current(self)

    return self:_hit_test_resolved(x, y, state)
end

function Container:_hit_test_resolved(x, y, state)

    state = state or {}

    return find_hit_target(self, x, y, {
        active_clips = state.active_clips or {},
        effective_enabled = state.effective_enabled ~= false,
        effective_visible = state.effective_visible ~= false,
        layer_eligible = state.layer_eligible ~= false,
    })
end

function Container:_draw_subtree(graphics, draw_callback)

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

    if not Types.is_table(graphics) then
        Assert.fail('graphics must be a graphics adapter table', 2)
    end

    if not Types.is_function(draw_callback) then
        Assert.fail('draw_callback must be a function', 2)
    end

    local stencil_compare, stencil_value = get_stencil_test(graphics)
    local render_state = RootCompositor.initialize_render_state(graphics, {})

    draw_subtree(self, graphics, draw_callback, {
        active_clips = {},
        scissor = get_scissor_rect(graphics),
        scissor_scratch_stack = {},
        stencil_compare = stencil_compare,
        stencil_value = stencil_value,
    }, render_state)

    return self
end

function Container:markDirty()
    self:invalidate_stage_update_token()
    self.dirty:mark('responsive', 'measurement', 'local_transform')
    self:invalidate_world()
    self:invalidate_descendant_geometry()
    return self
end

function Container:_set_layout_offset(x, y)
    Assert.number('x', x, 2)
    Assert.number('y', y, 2)

    if self._layout_offset_x == x and self._layout_offset_y == y then
        return self
    end

    self._layout_offset_x = x
    self._layout_offset_y = y
    self.dirty:mark('local_transform')
    self:invalidate_world()
    self:invalidate_descendant_world()
    return self
end

function Container:_mark_parent_layout_dependency_dirty()
    self:mark_layout_node_dirty()
    self.dirty:mark('measurement', 'local_transform')
    self:invalidate_world()
    self:invalidate_descendant_geometry()
    return self
end

function Container:_get_effective_content_rect()
    return Rectangle(
        0,
        0,
        self._resolved_width or 0,
        self._resolved_height or 0
    )
end

function Container:_set_measurement_context(width, height)

    if width ~= nil then
        Assert.number('width', width, 2)
    end

    if height ~= nil then
        Assert.number('height', height, 2)
    end

    if self._measurement_context_width == width and
        self._measurement_context_height == height then
        return self
    end

    self:invalidate_stage_update_token()
    self._measurement_context_width = width
    self._measurement_context_height = height
    self:invalidate_ancestor_layouts()
    self.dirty:mark('measurement', 'local_transform')
    self:invalidate_world()
    self:invalidate_descendant_geometry()
    return self
end

function Container:_set_resolved_responsive_overrides(token, overrides)

    if self._responsive_token == token and
        self._resolved_responsive_overrides_source == overrides then
        return self
    end

    local normalized = nil
    if overrides ~= nil then
        Assert.table('overrides', overrides, 2)

        normalized = {}

        for key, value in pairs(overrides) do
            if get_declared_rule(self, key) == nil then
                Assert.fail(
                    'responsive override "' .. tostring(key) ..
                        '" is not supported',
                    2
                )
            end

            normalized[key] = validate_public_value(self, key, value, 2, overrides)
        end
    end

    local previous_overrides = self._resolved_responsive_overrides
    local previous_effective_z_index = get_effective_value(self, 'zIndex')

    if responsive_overrides_affect_root_compositing_plan(self, previous_overrides, normalized) then
        RootCompositor.invalidate_node_plan(self)
    end

    self:invalidate_stage_update_token()
    self._responsive_token = token
    self._resolved_responsive_overrides_source = overrides
    self._resolved_responsive_overrides = normalized
    self:invalidate_ancestor_layouts()
    self.dirty:mark('responsive', 'measurement', 'local_transform')
    self:invalidate_world()
    self:invalidate_descendant_geometry()

    if previous_effective_z_index ~= get_effective_value(self, 'zIndex') then
        self:mark_parent_order_dirty()
    end

    return self
end

function Container:on_destroy()
    destroy_subtree(self)
end

function Container:_get_motion_surface(target_name)
    if target_name == nil or target_name == 'root' then
        return self
    end

    local value = self[target_name]
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

    local state = surface._motion_visual_state
    if state == nil then
        state = {}
        surface._motion_visual_state = state
    end

    state[property_name] = value

    local plan_target = surface
    if plan_target._ui_container_instance ~= true then
        plan_target = self
    end

    if RootCompositor.motion_property_affects_node_plan(plan_target, property_name) then
        RootCompositor.invalidate_node_plan(plan_target)
    end

    return surface
end

function Container:_get_motion_value(target_name, property_name)
    local surface = self:_get_motion_surface(target_name)
    if surface == nil then
        return nil
    end

    local state = surface._motion_visual_state
    return state[property_name]
end

function Container:_raise_motion(phase, payload)
    return Motion.request(self, phase, payload or {})
end

return Container
