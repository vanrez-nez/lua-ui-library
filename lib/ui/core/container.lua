local Assert = require('lib.ui.core.assert')
local MathUtils = require('lib.ui.core.math_utils')
local Matrix = require('lib.ui.core.matrix')
local Rectangle = require('lib.ui.core.rectangle')

local abs = math.abs

local CLIP_EPSILON = 1e-9
local mark_parent_order_dirty

local Container = {}

local BASE_PUBLIC_KEYS = {
    tag = true,
    visible = true,
    interactive = true,
    enabled = true,
    focusable = true,
    clipChildren = true,
    zIndex = true,
    anchorX = true,
    anchorY = true,
    pivotX = true,
    pivotY = true,
    x = true,
    y = true,
    width = true,
    height = true,
    minWidth = true,
    minHeight = true,
    maxWidth = true,
    maxHeight = true,
    scaleX = true,
    scaleY = true,
    rotation = true,
    skewX = true,
    skewY = true,
    breakpoints = true,
}

local DEFAULT_PUBLIC_VALUES = {
    visible = true,
    interactive = false,
    enabled = true,
    focusable = false,
    clipChildren = false,
    zIndex = 0,
    anchorX = 0,
    anchorY = 0,
    pivotX = 0,
    pivotY = 0,
    x = 0,
    y = 0,
    width = 0,
    height = 0,
    scaleX = 1,
    scaleY = 1,
    rotation = 0,
    skewX = 0,
    skewY = 0,
}

local MEASUREMENT_KEYS = {
    width = true,
    height = true,
    minWidth = true,
    minHeight = true,
    maxWidth = true,
    maxHeight = true,
}

local LOCAL_TRANSFORM_KEYS = {
    anchorX = true,
    anchorY = true,
    pivotX = true,
    pivotY = true,
    x = true,
    y = true,
    scaleX = true,
    scaleY = true,
    rotation = true,
    skewX = true,
    skewY = true,
}

local function copy_array(values)
    local copy = {}

    for index = 1, #values do
        copy[index] = values[index]
    end

    return copy
end

local default = MathUtils.default
local clamp_number = MathUtils.clamp_number
local resolve_axis_size = MathUtils.resolve_axis_size
local is_percentage_string = MathUtils.is_percentage_string

local function validate_size_value(prop_name, value, allow_content, level)
    local value_type = type(value)

    if value_type == 'number' then
        return value
    end

    if value == 'fill' then
        return value
    end

    if value == 'content' then
        if allow_content then
            return value
        end

        Assert.fail(
            'Container.' .. prop_name ..
                ' = "content" is invalid without an intrinsic measurement rule',
            level or 1
        )
    end

    if is_percentage_string(value) then
        return value
    end

    Assert.fail(
        'Container.' .. prop_name ..
            ' must be a number, "content", "fill", or a percentage string',
        level or 1
    )
end

local function find_child_index(parent, child)
    for index = 1, #parent._children do
        if parent._children[index] == child then
            return index
        end
    end

    return nil
end

local function merge_public_keys(extra_public_keys)
    if extra_public_keys == nil then
        return BASE_PUBLIC_KEYS
    end

    Assert.table('extra_public_keys', extra_public_keys, 3)

    local merged = {}

    for key in pairs(BASE_PUBLIC_KEYS) do
        merged[key] = true
    end

    for key in pairs(extra_public_keys) do
        merged[key] = true
    end

    return merged
end

local function validate_public_keys(opts, allowed_public_keys)
    for key in pairs(opts) do
        if not allowed_public_keys[key] then
            Assert.fail(
                'Container does not support prop "' .. tostring(key) .. '"',
                4
            )
        end
    end
end

local function is_base_public_key(key)
    return BASE_PUBLIC_KEYS[key] == true
end

local function mark_world_dirty(node)
    node._world_transform_dirty = true
    node._bounds_dirty = true
    node._world_inverse_dirty = true
end

local function mark_descendant_world_dirty(node)
    for index = 1, #node._children do
        local child = node._children[index]
        mark_world_dirty(child)
        mark_descendant_world_dirty(child)
    end
end

local function mark_descendant_geometry_dirty(node)
    for index = 1, #node._children do
        local child = node._children[index]
        child._responsive_dirty = true
        child._measurement_dirty = true
        child._local_transform_dirty = true
        mark_world_dirty(child)
        mark_descendant_geometry_dirty(child)
    end
end

local function assert_live_container(node, name, level)
    if type(node) ~= 'table' or node._ui_container_instance ~= true then
        Assert.fail(name .. ' must be a Container', level or 1)
    end

    if node._destroyed then
        Assert.fail(name .. ' must not be destroyed', level or 1)
    end
end

local function assert_not_destroyed(self, level)
    if self._destroyed then
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

        current = current.parent
    end
end

local function get_root(node)
    local current = node

    while current.parent do
        current = current.parent
    end

    return current
end

local function ensure_current(node)
    local root = get_root(node)
    root:update()
end

local function validate_public_value(self, key, value, level)
    if key == 'tag' then
        if value ~= nil then
            Assert.string('Container.tag', value, level)
        end

        return value
    end

    if key == 'visible' then
        Assert.boolean('Container.visible', value, level)
        return value
    end

    if key == 'interactive' then
        Assert.boolean('Container.interactive', value, level)
        return value
    end

    if key == 'enabled' then
        Assert.boolean('Container.enabled', value, level)
        return value
    end

    if key == 'focusable' then
        Assert.boolean('Container.focusable', value, level)
        return value
    end

    if key == 'clipChildren' then
        Assert.boolean('Container.clipChildren', value, level)
        return value
    end

    if key == 'zIndex' then
        Assert.number('Container.zIndex', value, level)
        return value
    end

    if key == 'anchorX' then
        Assert.number('Container.anchorX', value, level)
        return value
    end

    if key == 'anchorY' then
        Assert.number('Container.anchorY', value, level)
        return value
    end

    if key == 'pivotX' then
        Assert.number('Container.pivotX', value, level)
        return value
    end

    if key == 'pivotY' then
        Assert.number('Container.pivotY', value, level)
        return value
    end

    if key == 'x' then
        Assert.number('Container.x', value, level)
        return value
    end

    if key == 'y' then
        Assert.number('Container.y', value, level)
        return value
    end

    if key == 'width' then
        return validate_size_value(
            'width',
            value,
            self._config.allow_content_width == true,
            level
        )
    end

    if key == 'height' then
        return validate_size_value(
            'height',
            value,
            self._config.allow_content_height == true,
            level
        )
    end

    if key == 'minWidth' then
        if value ~= nil then
            Assert.number('Container.minWidth', value, level)
        end

        return value
    end

    if key == 'minHeight' then
        if value ~= nil then
            Assert.number('Container.minHeight', value, level)
        end

        return value
    end

    if key == 'maxWidth' then
        if value ~= nil then
            Assert.number('Container.maxWidth', value, level)
        end

        return value
    end

    if key == 'maxHeight' then
        if value ~= nil then
            Assert.number('Container.maxHeight', value, level)
        end

        return value
    end

    if key == 'scaleX' then
        Assert.number('Container.scaleX', value, level)
        return value
    end

    if key == 'scaleY' then
        Assert.number('Container.scaleY', value, level)
        return value
    end

    if key == 'rotation' then
        Assert.number('Container.rotation', value, level)
        return value
    end

    if key == 'skewX' then
        Assert.number('Container.skewX', value, level)
        return value
    end

    if key == 'skewY' then
        Assert.number('Container.skewY', value, level)
        return value
    end

    if key == 'breakpoints' then
        if value ~= nil then
            Assert.table('Container.breakpoints', value, level)
        end

        return value
    end

    return value
end

local function get_effective_value(self, key)
    return self._effective_values[key]
end

local function set_initial_public_value(self, key, value)
    self._public_values[key] = validate_public_value(self, key, value, 3)
end

local function refresh_effective_values(self)
    local previous_effective_z_index = nil

    if self._effective_values ~= nil then
        previous_effective_z_index = self._effective_values.zIndex
    end

    local effective = {}

    for key, value in pairs(self._public_values) do
        effective[key] = value
    end

    local overrides = self._responsive_overrides

    if overrides ~= nil then
        for key, value in pairs(overrides) do
            effective[key] = validate_public_value(self, key, value, 3)
        end
    end

    self._effective_values = effective
    self._responsive_dirty = false

    if previous_effective_z_index ~= effective.zIndex then
        mark_parent_order_dirty(self)
    end
end

local function refresh_measurement(self)
    local parent_width
    local parent_height

    if self.parent then
        parent_width = self.parent._resolved_width
        parent_height = self.parent._resolved_height
    else
        parent_width = self._measurement_context_width
        parent_height = self._measurement_context_height
    end

    local width = clamp_number(
        resolve_axis_size(get_effective_value(self, 'width'), parent_width),
        get_effective_value(self, 'minWidth'),
        get_effective_value(self, 'maxWidth')
    )
    local height = clamp_number(
        resolve_axis_size(get_effective_value(self, 'height'), parent_height),
        get_effective_value(self, 'minHeight'),
        get_effective_value(self, 'maxHeight')
    )

    self._resolved_width = width
    self._resolved_height = height
    self._local_bounds_cache = Rectangle.new(0, 0, width, height)
    self._measurement_dirty = false
end

local function refresh_local_transform(self)
    local parent_width = 0
    local parent_height = 0

    if self.parent then
        parent_width = self.parent._resolved_width or 0
        parent_height = self.parent._resolved_height or 0
    elseif self._measurement_context_width ~= nil or
        self._measurement_context_height ~= nil then
        parent_width = self._measurement_context_width or 0
        parent_height = self._measurement_context_height or 0
    end

    local width = self._resolved_width or 0
    local height = self._resolved_height or 0
    local pivot_x = get_effective_value(self, 'pivotX') * width
    local pivot_y = get_effective_value(self, 'pivotY') * height
    local anchor_x = get_effective_value(self, 'anchorX') * parent_width
    local anchor_y = get_effective_value(self, 'anchorY') * parent_height

    self._local_transform_cache = Matrix.from_transform(
        anchor_x + get_effective_value(self, 'x'),
        anchor_y + get_effective_value(self, 'y'),
        pivot_x,
        pivot_y,
        get_effective_value(self, 'scaleX'),
        get_effective_value(self, 'scaleY'),
        get_effective_value(self, 'rotation'),
        get_effective_value(self, 'skewX'),
        get_effective_value(self, 'skewY')
    )
    self._local_transform_dirty = false
end

local function refresh_world_transform(self)
    if self.parent then
        self._world_transform_cache =
            self.parent._world_transform_cache * self._local_transform_cache
    else
        self._world_transform_cache = self._local_transform_cache:clone()
    end

    self._world_transform_dirty = false
    self._world_inverse_dirty = true
end

local function refresh_bounds(self)
    local width = self._resolved_width or 0
    local height = self._resolved_height or 0
    local matrix = self._world_transform_cache
    local x1, y1 = matrix:transform_point(0, 0)
    local x2, y2 = matrix:transform_point(width, 0)
    local x3, y3 = matrix:transform_point(width, height)
    local x4, y4 = matrix:transform_point(0, height)

    self._world_bounds_cache = Rectangle.bounding_box({
        { x = x1, y = y1 },
        { x = x2, y = y2 },
        { x = x3, y = y3 },
        { x = x4, y = y4 },
    })
    self._bounds_dirty = false
end

local function refresh_child_order_cache(self)
    if not self._child_order_dirty and self._ordered_children ~= nil then
        return
    end

    local decorated = {}

    for index = 1, #self._children do
        decorated[index] = {
            child = self._children[index],
            index = index,
        }
    end

    table.sort(decorated, function(left, right)
        local left_z_index = get_effective_value(left.child, 'zIndex')
        local right_z_index = get_effective_value(right.child, 'zIndex')

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
    self._child_order_dirty = false
end

mark_parent_order_dirty = function(self)
    if self.parent then
        self.parent._child_order_dirty = true
    end
end

local function resolve_world_inverse(self)
    if self._world_inverse_dirty then
        self._world_inverse_cache, self._world_inverse_error =
            self._world_transform_cache:inverse()
        self._world_inverse_dirty = false
    end

    return self._world_inverse_cache, self._world_inverse_error
end

local function contains_world_point(self, x, y)
    if self._local_bounds_cache:is_empty() then
        return false
    end

    local inverse = resolve_world_inverse(self)

    if not inverse then
        return false
    end

    local local_x, local_y = inverse:transform_point(x, y)

    return self._local_bounds_cache:contains_point(local_x, local_y)
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
    local width = self._resolved_width or 0
    local height = self._resolved_height or 0
    local matrix = self._world_transform_cache
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
    return self._world_bounds_cache:clone()
end

local function has_degenerate_clip(self)
    if self._local_bounds_cache:is_empty() then
        return true
    end

    return not self._world_transform_cache:is_invertible()
end

local function get_scissor_rect(graphics)
    if type(graphics.getScissor) ~= 'function' then
        return nil
    end

    local x, y, width, height = graphics.getScissor()

    if x == nil or y == nil or width == nil or height == nil then
        return nil
    end

    return Rectangle.new(x, y, width, height)
end

local function set_scissor_rect(graphics, rect)
    if type(graphics.setScissor) ~= 'function' then
        return
    end

    if rect == nil then
        graphics.setScissor()
        return
    end

    graphics.setScissor(rect.x, rect.y, rect.width, rect.height)
end

local function get_stencil_test(graphics)
    if type(graphics.getStencilTest) ~= 'function' then
        return nil, nil
    end

    return graphics.getStencilTest()
end

local function set_stencil_test(graphics, compare, value)
    if type(graphics.setStencilTest) ~= 'function' then
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

    if type(graphics.polygon) == 'function' then
        graphics.polygon('fill', flattened)
    end
end

local function draw_subtree(self, graphics, draw_callback, clip_state)
    if not get_effective_value(self, 'visible') then
        return nil
    end

    local active_clips = clip_state.active_clips

    if get_effective_value(self, 'clipChildren') then
        if has_degenerate_clip(self) then
            local previous_scissor = clip_state.scissor

            clip_state.active_clips[#active_clips + 1] = self
            clip_state.scissor = Rectangle.new(0, 0, 0, 0)
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

            local ordered_children = self._ordered_children

            for index = 1, #ordered_children do
                draw_subtree(ordered_children[index], graphics, draw_callback, clip_state)
            end

            clip_state.active_clips[#clip_state.active_clips] = nil
            clip_state.scissor = previous_scissor
            set_scissor_rect(graphics, previous_scissor)
            return nil
        end

        local next_stencil_value = (clip_state.stencil_value or 0) + 1

        set_stencil_test(graphics, previous_stencil_compare, previous_stencil_value)

        if type(graphics.stencil) == 'function' then
            graphics.stencil(function()
                draw_clip_polygon(graphics, self)
            end, 'increment', 1, true)
        end

        clip_state.stencil_compare = 'equal'
        clip_state.stencil_value = next_stencil_value
        set_stencil_test(graphics, clip_state.stencil_compare, clip_state.stencil_value)

        draw_callback(self)

        local ordered_children = self._ordered_children

        for index = 1, #ordered_children do
            draw_subtree(ordered_children[index], graphics, draw_callback, clip_state)
        end

        set_stencil_test(graphics, 'equal', next_stencil_value)

        if type(graphics.stencil) == 'function' then
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

    local ordered_children = self._ordered_children

    for index = 1, #ordered_children do
        draw_subtree(ordered_children[index], graphics, draw_callback, clip_state)
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

local function set_public_value(self, key, value, level)
    value = validate_public_value(self, key, value, level or 1)

    if self._public_values[key] == value then
        return value
    end

    self._public_values[key] = value
    self._responsive_dirty = true

    if key == 'breakpoints' then
        self._measurement_dirty = true
        self._local_transform_dirty = true
        mark_world_dirty(self)
        mark_descendant_geometry_dirty(self)
        return value
    end

    if MEASUREMENT_KEYS[key] then
        self._measurement_dirty = true
        self._local_transform_dirty = true
        mark_world_dirty(self)
        mark_descendant_geometry_dirty(self)
        return value
    end

    if LOCAL_TRANSFORM_KEYS[key] then
        self._local_transform_dirty = true
        mark_world_dirty(self)
        mark_descendant_world_dirty(self)
        return value
    end

    if key == 'zIndex' then
        mark_parent_order_dirty(self)
    end

    return value
end

local function detach_child(parent, child)
    local index = find_child_index(parent, child)

    if not index then
        return nil
    end

    table.remove(parent._children, index)
    parent._child_order_dirty = true
    child.parent = nil
    child._responsive_dirty = true
    child._measurement_dirty = true
    child._local_transform_dirty = true
    mark_world_dirty(child)
    mark_descendant_geometry_dirty(child)
    return child
end

local function destroy_subtree(node)
    if node._destroyed then
        return
    end

    if node.parent then
        detach_child(node.parent, node)
    end

    for index = #node._children, 1, -1 do
        local child = node._children[index]
        node._children[index] = nil
        child.parent = nil
        destroy_subtree(child)
    end

    node._ordered_children = nil
    node._destroyed = true
end

Container.__index = function(self, key)
    local method = rawget(Container, key)

    if method ~= nil then
        return method
    end

    local allowed_public_keys = rawget(self, '_allowed_public_keys')

    if allowed_public_keys and allowed_public_keys[key] then
        return rawget(self, '_public_values')[key]
    end

    return nil
end

Container.__newindex = function(self, key, value)
    local allowed_public_keys = rawget(self, '_allowed_public_keys')

    if allowed_public_keys and allowed_public_keys[key] then
        set_public_value(self, key, value, 2)
        return
    end

    rawset(self, key, value)
end

function Container._initialize(self, opts, extra_public_keys, config)
    if opts == nil then
        opts = {}
    else
        Assert.table('opts', opts, 2)
    end

    config = config or {}

    local allowed_public_keys = merge_public_keys(extra_public_keys)
    validate_public_keys(opts, allowed_public_keys)

    setmetatable(self, Container)

    self._ui_container_instance = true
    self._allowed_public_keys = allowed_public_keys
    self._config = config
    self._public_values = {}
    self._effective_values = {}
    self._children = {}
    self._ordered_children = {}
    self.parent = nil
    self._destroyed = false

    self._responsive_overrides = nil
    self._responsive_token = nil
    self._responsive_dirty = true
    self._measurement_dirty = true
    self._local_transform_dirty = true
    self._world_transform_dirty = true
    self._bounds_dirty = true
    self._world_inverse_dirty = true
    self._child_order_dirty = true

    self._measurement_context_width = nil
    self._measurement_context_height = nil

    self._resolved_width = 0
    self._resolved_height = 0
    self._local_transform_cache = Matrix.identity()
    self._world_transform_cache = Matrix.identity()
    self._world_inverse_cache = nil
    self._world_inverse_error = 'world transform is not invertible'
    self._local_bounds_cache = Rectangle.new(0, 0, 0, 0)
    self._world_bounds_cache = Rectangle.new(0, 0, 0, 0)

    set_initial_public_value(self, 'tag', opts.tag)
    set_initial_public_value(self, 'visible', default(opts.visible,
        DEFAULT_PUBLIC_VALUES.visible))
    set_initial_public_value(self, 'interactive', default(opts.interactive,
        DEFAULT_PUBLIC_VALUES.interactive))
    set_initial_public_value(self, 'enabled', default(opts.enabled,
        DEFAULT_PUBLIC_VALUES.enabled))
    set_initial_public_value(self, 'focusable', default(opts.focusable,
        DEFAULT_PUBLIC_VALUES.focusable))
    set_initial_public_value(self, 'clipChildren', default(opts.clipChildren,
        DEFAULT_PUBLIC_VALUES.clipChildren))
    set_initial_public_value(self, 'zIndex', default(opts.zIndex,
        DEFAULT_PUBLIC_VALUES.zIndex))
    set_initial_public_value(self, 'anchorX', default(opts.anchorX,
        DEFAULT_PUBLIC_VALUES.anchorX))
    set_initial_public_value(self, 'anchorY', default(opts.anchorY,
        DEFAULT_PUBLIC_VALUES.anchorY))
    set_initial_public_value(self, 'pivotX', default(opts.pivotX,
        DEFAULT_PUBLIC_VALUES.pivotX))
    set_initial_public_value(self, 'pivotY', default(opts.pivotY,
        DEFAULT_PUBLIC_VALUES.pivotY))
    set_initial_public_value(self, 'x', default(opts.x, DEFAULT_PUBLIC_VALUES.x))
    set_initial_public_value(self, 'y', default(opts.y, DEFAULT_PUBLIC_VALUES.y))
    set_initial_public_value(self, 'width', default(opts.width,
        DEFAULT_PUBLIC_VALUES.width))
    set_initial_public_value(self, 'height', default(opts.height,
        DEFAULT_PUBLIC_VALUES.height))
    set_initial_public_value(self, 'minWidth', opts.minWidth)
    set_initial_public_value(self, 'minHeight', opts.minHeight)
    set_initial_public_value(self, 'maxWidth', opts.maxWidth)
    set_initial_public_value(self, 'maxHeight', opts.maxHeight)
    set_initial_public_value(self, 'scaleX', default(opts.scaleX,
        DEFAULT_PUBLIC_VALUES.scaleX))
    set_initial_public_value(self, 'scaleY', default(opts.scaleY,
        DEFAULT_PUBLIC_VALUES.scaleY))
    set_initial_public_value(self, 'rotation', default(opts.rotation,
        DEFAULT_PUBLIC_VALUES.rotation))
    set_initial_public_value(self, 'skewX', default(opts.skewX,
        DEFAULT_PUBLIC_VALUES.skewX))
    set_initial_public_value(self, 'skewY', default(opts.skewY,
        DEFAULT_PUBLIC_VALUES.skewY))
    set_initial_public_value(self, 'breakpoints', opts.breakpoints)

    for key, value in pairs(opts) do
        if allowed_public_keys[key] and not is_base_public_key(key) then
            set_initial_public_value(self, key, value)
        end
    end

    refresh_effective_values(self)

    return self
end

function Container.new(opts)
    local self = {}
    return Container._initialize(self, opts)
end

function Container:_refresh_if_dirty()
    assert_not_destroyed(self, 2)

    if self._responsive_dirty then
        refresh_effective_values(self)
    end

    if self._measurement_dirty then
        refresh_measurement(self)
    end

    if self._local_transform_dirty then
        refresh_local_transform(self)
    end

    if self._world_transform_dirty then
        refresh_world_transform(self)
    end

    if self._bounds_dirty then
        refresh_bounds(self)
    end

    refresh_child_order_cache(self)
end

function Container:update(_)
    assert_not_destroyed(self, 2)
    self:_refresh_if_dirty()

    for index = 1, #self._children do
        self._children[index]:update()
    end

    if self._child_order_dirty then
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

    if child.parent then
        detach_child(child.parent, child)
    end

    child.parent = self
    self._children[#self._children + 1] = child
    self._child_order_dirty = true

    child._responsive_dirty = true
    child._measurement_dirty = true
    child._local_transform_dirty = true
    mark_world_dirty(child)
    mark_descendant_geometry_dirty(child)

    return child
end

function Container:removeChild(child)
    assert_not_destroyed(self, 2)
    assert_live_container(child, 'child', 2)

    return detach_child(self, child)
end

function Container:getChildren()
    return copy_array(self._children)
end

function Container:_get_ordered_children()
    ensure_current(self)
    return copy_array(self._ordered_children)
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
    return self._world_transform_cache:transform_point(x, y)
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

    if draw_callback == nil and type(graphics) == 'function' then
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

    if type(graphics) ~= 'table' then
        Assert.fail('graphics must be a graphics adapter table', 2)
    end

    if type(draw_callback) ~= 'function' then
        Assert.fail('draw_callback must be a function', 2)
    end

    ensure_current(self)

    return self:_draw_subtree_resolved(graphics, draw_callback)
end

function Container:_draw_subtree_resolved(graphics, draw_callback)
    assert_not_destroyed(self, 2)

    if type(graphics) ~= 'table' then
        Assert.fail('graphics must be a graphics adapter table', 2)
    end

    if type(draw_callback) ~= 'function' then
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
    self._responsive_dirty = true
    self._measurement_dirty = true
    self._local_transform_dirty = true
    mark_world_dirty(self)
    mark_descendant_geometry_dirty(self)
    return self
end

function Container:_set_measurement_context(width, height)
    assert_not_destroyed(self, 2)

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

    self._measurement_context_width = width
    self._measurement_context_height = height
    self._measurement_dirty = true
    self._local_transform_dirty = true
    mark_world_dirty(self)
    mark_descendant_geometry_dirty(self)
    return self
end

function Container:_set_resolved_responsive_overrides(token, overrides)
    assert_not_destroyed(self, 2)

    if overrides ~= nil then
        Assert.table('overrides', overrides, 2)

        for key in pairs(overrides) do
            if not self._allowed_public_keys[key] then
                Assert.fail(
                    'responsive override "' .. tostring(key) ..
                        '" is not supported',
                    2
                )
            end
        end
    end

    if self._responsive_token == token and self._responsive_overrides == overrides then
        return self
    end

    self._responsive_token = token
    self._responsive_overrides = overrides
    self._responsive_dirty = true
    self._measurement_dirty = true
    self._local_transform_dirty = true
    mark_world_dirty(self)
    mark_descendant_geometry_dirty(self)
    return self
end

function Container:destroy()
    destroy_subtree(self)
end

return Container
