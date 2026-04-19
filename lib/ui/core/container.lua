local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local MathUtils = require('lib.ui.utils.math')
local Rectangle = require('lib.ui.core.rectangle')
local Object = require('lib.cls')
local Constants = require('lib.ui.core.constants')
local EventDispatcher = require('lib.ui.event.event_dispatcher')

local DirtyProps = require('lib.ui.utils.dirty_props')
local Rule = require('lib.ui.utils.rule')
local Utils = require('lib.ui.utils.common')
local Motion = require('lib.ui.motion')
local ContainerUtils = require('lib.ui.core.container_utils')
local RootCompositor = require('lib.ui.render.root_compositor')

local Container = EventDispatcher:extends('Container')

Container:implements(DirtyProps)

Container._schema = require('lib.ui.core.container_schema')

local get_scissor_rect = ContainerUtils.get_scissor_rect
local get_stencil_test = ContainerUtils.get_stencil_test
local ensure_current = ContainerUtils.ensure_current
local get_declared_rule = ContainerUtils.get_declared_rule
local get_effective_value = ContainerUtils.get_effective_value
local sync_resolved_cache = ContainerUtils.sync_resolved_cache
local refresh_measurement = ContainerUtils.refresh_measurement
local refresh_local_transform = ContainerUtils.refresh_local_transform
local refresh_world_transform = ContainerUtils.refresh_world_transform
local refresh_bounds = ContainerUtils.refresh_bounds
local refresh_child_order_cache = ContainerUtils.refresh_child_order_cache
local resolve_world_inverse = ContainerUtils.resolve_world_inverse
local contains_world_point = ContainerUtils.contains_world_point
local point_within_active_clips = ContainerUtils.point_within_active_clips
local draw_subtree = ContainerUtils.draw_subtree
local find_hit_target = ContainerUtils.find_hit_target
local detach_child = ContainerUtils.detach_child
local destroy_subtree = ContainerUtils.destroy_subtree
local _init_state_fields = ContainerUtils._init_state_fields
local _init_schema = ContainerUtils._init_schema
local _init_hooks = ContainerUtils._init_hooks
local _apply_opts = ContainerUtils._apply_opts
local refresh_responsive = ContainerUtils.refresh_responsive
local is_layout_node = ContainerUtils.is_layout_node
local assert_live_container = ContainerUtils.assert_live_container
local assert_no_cycle = ContainerUtils.assert_no_cycle
local get_root = ContainerUtils.get_root
local responsive_overrides_affect_root_compositing_plan =
    ContainerUtils.responsive_overrides_affect_root_compositing_plan
local is_public_node = ContainerUtils.is_public_node
local is_strict_descendant_of = ContainerUtils.is_strict_descendant_of
local assign_attachment_root_recursive = ContainerUtils.assign_attachment_root_recursive
local register_node_id_with_root = ContainerUtils.register_node_id_with_root
local register_subtree_ids = ContainerUtils.register_subtree_ids
local validate_subtree_attach_identity = ContainerUtils.validate_subtree_attach_identity
local validate_depth_argument = ContainerUtils.validate_depth_argument
local validate_lookup_key = ContainerUtils.validate_lookup_key
local find_by_id_bounded = ContainerUtils.find_by_id_bounded
local find_by_tag_bounded = ContainerUtils.find_by_tag_bounded

Container._walk_hierarchy = ContainerUtils.walk_hierarchy
Container._get_public_read_value = ContainerUtils.get_effective_value


local default = MathUtils.default
local clamp_number = MathUtils.clamp_number

-- Removed manual key checks; Schemas handles extension directly.

function Container:invalidate_world()
    RootCompositor.invalidate_node_plan(self)
    self:mark_dirty('world_transform', 'bounds', 'world_inverse')
end

--- Pull-based parent invalidation check.
-- Called during _refresh_if_dirty / _prepare_for_layout_pass.
-- Each child checks its parent's cached state against stored references.
-- O(1) per child — no tree walking.
function Container:_check_parent_invalidation()
    local parent = self.parent
    if not parent then return end

    -- World transform dependency
    if parent._world_transform_cache ~= self._parent_world_ref then
        self:mark_dirty('world_transform', 'bounds', 'world_inverse')
        self._parent_world_ref = parent._world_transform_cache
    end

    -- Resolved size dependency (affects measurement for content-sized children)
    if parent._resolved_width ~= self._parent_resolved_w or
       parent._resolved_height ~= self._parent_resolved_h then
        self:mark_dirty('responsive', 'measurement')
        self:mark_layout_node_dirty()
        self._parent_resolved_w = parent._resolved_width
        self._parent_resolved_h = parent._resolved_height
    end
end

function Container:notify_stage_subtree_change(stage, handler_name, child, parent)  -- luacheck: ignore self
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

    if root._ui_stage_instance == true then
        root._update_ran = false
    end
end

function Container:mark_layout_node_dirty()
    if not is_layout_node(self) then
        return false
    end

    if self:group_dirty('layout') then
        return false
    end

    self:mark_dirty('layout')
    self:invalidate_stage_update_token()

    return true
end



function Container:mark_parent_order_dirty()
    if self.parent then
        self.parent:mark_dirty('child_order')
    end
end

function Container._resolve_root_compositing_extras()
    return nil
end

function Container._resolve_root_compositing_world_paint_bounds()
    return nil
end

function Container._resolve_root_compositing_result_clip()
    return nil
end



function Container:_initialize(opts, extra_public_keys, config)
    opts = opts or {}
    config = config or {}

    if opts.responsive ~= nil and opts.breakpoints ~= nil then
        Assert.fail('Supplying responsive and breakpoints together at construction should fail', 3)
    end

    _init_state_fields(self, config)
    local declared_props, schema_props = _init_schema(self, extra_public_keys)
    _init_hooks()
    _apply_opts(self, opts, declared_props, schema_props)

    self:mark_dirty(
        'responsive', 'measurement', 'local_transform',
        'world_transform', 'bounds', 'child_order', 'world_inverse'
    )

    register_node_id_with_root(self, self)
    -- Initial cache population
    sync_resolved_cache(self)
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


function Container:_apply_resolved_size(width, height)
    local resolved_width = default(width, self._resolved_width or 0)
    local resolved_height = default(height, self._resolved_height or 0)

    if self._resolved_width == resolved_width and
        self._resolved_height == resolved_height then
        self:clear_dirty('measurement')
        return false
    end

    self._resolved_width = resolved_width
    self._resolved_height = resolved_height
    self._local_bounds_cache = Rectangle(0, 0, resolved_width, resolved_height)
    self:clear_dirty('measurement')
    self:mark_dirty('local_transform')
    self:invalidate_world()

    if self._ui_layout_instance == true and
        Types.is_function(self._refresh_layout_content_rect) then
        self:_refresh_layout_content_rect()
        self:mark_layout_node_dirty()
    end

    return true
end

function Container:_apply_content_measurement(width, height)
    local effective_width = self._resolved_width or 0
    local effective_height = self._resolved_height or 0

    if get_effective_value(self, 'width') == Constants.SIZE_MODE_CONTENT then
        effective_width = clamp_number(
            width or 0,
            get_effective_value(self, 'minWidth'),
            get_effective_value(self, 'maxWidth')
        )
    end

    if get_effective_value(self, 'height') == Constants.SIZE_MODE_CONTENT then
        effective_height = clamp_number(
            height or 0,
            get_effective_value(self, 'minHeight'),
            get_effective_value(self, 'maxHeight')
        )
    end

    return self:_apply_resolved_size(effective_width, effective_height)
end

function Container:_refresh_if_dirty()
    self:sync_dirty_props()
    self:_check_parent_invalidation()

    if self:group_dirty('responsive') then
        refresh_responsive(self)
    end

    if self:group_dirty('measurement') then
        refresh_measurement(self)
    end

    if self:group_dirty('local_transform') then
        refresh_local_transform(self)
    end

    if self:group_dirty('world_transform') then
        refresh_world_transform(self)
    end

    if self:group_dirty('bounds') then
        refresh_bounds(self)
    end

    if self:group_dirty('child_order') then
        refresh_child_order_cache(self)
    end

    self:reset_dirty_props()
end

function Container:_prepare_for_layout_pass()
    self:sync_dirty_props()
    self:_check_parent_invalidation()

    if self:group_dirty('responsive') then
        refresh_responsive(self)
    end

    if self:group_dirty('measurement') then
        refresh_measurement(self)
    end

    if self:group_dirty('child_order') then
        refresh_child_order_cache(self)
    end

    self:reset_dirty_props()
    return self
end

local UPDATE_SNAPSHOT_SCRATCH = {}
local UPDATE_SNAPSHOT_OFFSET = 0

function Container:update(_)
    -- The stage calls update() on the root and flags _updating = true to indicate a stage-managed tick.
    -- If update() is called directly outside of the stage, we must resolve responsive behavior manually.
    local root = get_root(self)
    local resolve_responsive_for_node = root._resolve_responsive_for_node
    local stage_managed_update = root._ui_stage_instance == true and root._updating == true

    if not stage_managed_update and Types.is_function(resolve_responsive_for_node) then
        resolve_responsive_for_node(root, self)
    end

    self:_refresh_if_dirty()

    local children = self._children
    local snapshot_len = #children
    local start_offset = UPDATE_SNAPSHOT_OFFSET

    for index = 1, snapshot_len do
        UPDATE_SNAPSHOT_SCRATCH[start_offset + index] = children[index]
    end

    UPDATE_SNAPSHOT_OFFSET = start_offset + snapshot_len

    for index = 1, snapshot_len do
        local child = UPDATE_SNAPSHOT_SCRATCH[start_offset + index]
        if child.parent == self then
            child:update()
        end
        UPDATE_SNAPSHOT_SCRATCH[start_offset + index] = nil
    end

    UPDATE_SNAPSHOT_OFFSET = start_offset

    if self:group_dirty('child_order') then
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
    self:mark_dirty('child_order')
    self:invalidate_stage_update_token()

    child:mark_dirty('responsive', 'measurement', 'bounds', 'local_transform')
    child:invalidate_world()
    self:notify_stage_subtree_change(
        attachment_root,
        '_handle_attached_subtree',
        child,
        self
    )

    return child
end

function Container:removeChild(child)
    assert_live_container(child, 'child', 2)

    detach_child(self, child)
    return child
end

function Container:getChildren()
    return Utils.copy_array(self._children)
end

function Container:findById(id, depth)
    ensure_current(self)

    validate_lookup_key('Container.findById', 'id', id)
    depth = validate_depth_argument('Container.findById', depth, -1)

    if is_public_node(self) and self.id == id then
        return self
    end

    if depth == 0 then
        return nil
    end

    if depth == -1 or depth == math.huge then
        local attachment_root = get_root(self)
        local index = attachment_root and attachment_root._id_index or nil
        local candidate = index and index[id] or nil
        if candidate ~= nil and candidate ~= self
            and is_public_node(candidate)
            and is_strict_descendant_of(candidate, self) then
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

    return find_hit_target(self, x, y,
        state.layer_eligible ~= false,
        state.effective_visible ~= false,
        state.effective_enabled ~= false,
        state.active_clips or {}
    )
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
    -- Note: This is an unoptimized coarse fallback that over-invalidates measurement and bounds.
    -- Prefer utilizing more targeted dirty:mark(...) statements where context is available.
    self:invalidate_stage_update_token()
    self:mark_dirty('responsive', 'measurement', 'local_transform')
    self:invalidate_world()
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
    self:mark_dirty('local_transform')
    self:invalidate_world()
    return self
end

function Container:_mark_parent_layout_dependency_dirty()
    self:mark_layout_node_dirty()
    self:mark_dirty('measurement', 'local_transform')
    self:invalidate_world()
    return self
end

function Container:_get_effective_content_rect()
    local cached = self._content_rect_cache
    if cached == nil then
        cached = Rectangle(0, 0, 0, 0)
        self._content_rect_cache = cached
    end
    cached.width = self._resolved_width or 0
    cached.height = self._resolved_height or 0
    return cached
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
    self:mark_dirty('measurement', 'local_transform')
    self:invalidate_world()
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
            local rule = get_declared_rule(self, key)
            if rule == nil then
                Assert.fail(
                    'responsive override "' .. tostring(key) ..
                        '" is not supported',
                    2
                )
            end

            if rule == true then
                normalized[key] = value
            else
                local full_key = tostring(self) .. '.' .. tostring(key)
                normalized[key] = Rule.validate(rule, full_key, value, self, 3, overrides)
            end
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

    -- When overrides change, we must sync the entire resolved cache
    sync_resolved_cache(self)

    self:mark_dirty('responsive', 'measurement', 'local_transform')
    self:invalidate_world()

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

-- Low-level helpers


return Container
