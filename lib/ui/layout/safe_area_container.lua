local Assert = require('lib.ui.utils.assert')
local Container = require('lib.ui.core.container')
local LayoutNode = require('lib.ui.layout.layout_node')
local Rectangle = require('lib.ui.core.rectangle')

local max = math.max
local min = math.min

local SafeAreaContainer = LayoutNode:extends('SafeAreaContainer')
SafeAreaContainer._schema = require('lib.ui.layout.safe_area_container_schema')

local EXTRA_PUBLIC_KEYS = {
    applyTop = true,
    applyBottom = true,
    applyLeft = true,
    applyRight = true,
}

local function validate_apply_flag(name, value, level)
    Assert.boolean(name, value, level or 1)
end

local function set_apply_flag(self, key, value, level)
    validate_apply_flag('SafeAreaContainer.' .. key, value, level)

    local public_values = rawget(self, '_public_values')
    if public_values and public_values[key] == value then
        return value
    end

    if public_values then
        public_values[key] = value
    end
    self:markDirty()
    return value
end

local function child_is_visible(child)
    local effective_values = rawget(child, '_effective_values')

    if effective_values == nil then
        return true
    end

    return effective_values.visible ~= false
end

local function get_child_parent_local_bounds(child)
    local matrix = rawget(child, '_local_transform_cache')
    local width = rawget(child, '_resolved_width') or 0
    local height = rawget(child, '_resolved_height') or 0
    local x1, y1 = matrix:transform_point(0, 0)
    local x2, y2 = matrix:transform_point(width, 0)
    local x3, y3 = matrix:transform_point(width, height)
    local x4, y4 = matrix:transform_point(0, height)

    return Rectangle.bounding_box({
        { x = x1, y = y1 },
        { x = x2, y = y2 },
        { x = x3, y = y3 },
        { x = x4, y = y4 },
    })
end

local function place_children(self, content_rect)
    local children = rawget(self, '_children') or {}

    for index = 1, #children do
        local child = children[index]
        child:_set_layout_offset(content_rect.x, content_rect.y)
        child:_refresh_if_dirty()
    end

    return children
end

local function measure_content_extent(children, content_rect)
    local content_bounds = nil

    for index = 1, #children do
        local child = children[index]

        if child_is_visible(child) then
            local bounds = get_child_parent_local_bounds(child):translate(
                -content_rect.x,
                -content_rect.y
            )

            if content_bounds == nil then
                content_bounds = bounds
            else
                content_bounds = content_bounds:union(bounds)
            end
        end
    end

    if content_bounds == nil then
        return 0, 0
    end

    return
        max(0, content_bounds:right()) - min(0, content_bounds:left()),
        max(0, content_bounds:bottom()) - min(0, content_bounds:top())
end

local function resolve_stage(node, stage)
    if stage ~= nil and rawget(stage, '_ui_stage_instance') == true and
        not rawget(stage, '_destroyed') then
        return stage
    end

    local current = node

    while current ~= nil and current.parent ~= nil do
        current = current.parent
    end

    if current ~= nil and rawget(current, '_ui_stage_instance') == true and
        not rawget(current, '_destroyed') then
        return current
    end

    return nil
end

local function resolve_layout_world_rect(node)
    local values = rawget(node, '_effective_values') or {}
    local width = rawget(node, '_resolved_width') or 0
    local height = rawget(node, '_resolved_height') or 0
    local parent_width = 0
    local parent_height = 0
    local world_x = rawget(node, '_layout_offset_x') or 0
    local world_y = rawget(node, '_layout_offset_y') or 0

    if node.parent ~= nil then
        local parent_world_rect = resolve_layout_world_rect(node.parent)
        local parent_content_rect = node.parent:_get_effective_content_rect()

        world_x = world_x + parent_world_rect.x
        world_y = world_y + parent_world_rect.y
        parent_width = parent_content_rect.width or 0
        parent_height = parent_content_rect.height or 0
    end

    world_x = world_x + ((values.anchorX or 0) * parent_width) + (values.x or 0)
    world_y = world_y + ((values.anchorY or 0) * parent_height) + (values.y or 0)

    return Rectangle(world_x, world_y, width, height)
end

local function resolve_safe_area_insets(self, stage)
    local stage_root = resolve_stage(self, stage)

    if stage_root == nil then
        return 0, 0, 0, 0
    end

    local safe_area_bounds = rawget(stage_root, '_safe_area_bounds_cache')

    if not Rectangle.is_rectangle(safe_area_bounds) then
        return 0, 0, 0, 0
    end

    local world_rect = resolve_layout_world_rect(self)
    local values = rawget(self, '_effective_values') or {}
    local left = world_rect:left()
    local top = world_rect:top()
    local right = world_rect:right()
    local bottom = world_rect:bottom()

    if values.applyLeft then
        left = max(left, safe_area_bounds:left())
    end

    if values.applyTop then
        top = max(top, safe_area_bounds:top())
    end

    if values.applyRight then
        right = min(right, safe_area_bounds:right())
    end

    if values.applyBottom then
        bottom = min(bottom, safe_area_bounds:bottom())
    end

    if right < left then
        right = left
    end

    if bottom < top then
        bottom = top
    end

    return
        max(0, left - world_rect:left()),
        max(0, top - world_rect:top()),
        max(0, world_rect:right() - right),
        max(0, world_rect:bottom() - bottom)
end

local function resolve_content_edge_insets(self, stage)
    local padding = (rawget(self, '_effective_values') or {}).padding or {
        left = 0,
        top = 0,
        right = 0,
        bottom = 0,
    }
    local safe_left, safe_top, safe_right, safe_bottom =
        resolve_safe_area_insets(self, stage)

    return
        safe_left + padding.left,
        safe_top + padding.top,
        safe_right + padding.right,
        safe_bottom + padding.bottom
end

local function apply_content_measurement(self, content_width, content_height, stage)
    local effective_values = rawget(self, '_effective_values') or {}
    local resolved_width = rawget(self, '_resolved_width') or 0
    local resolved_height = rawget(self, '_resolved_height') or 0
    local left_inset, top_inset, right_inset, bottom_inset =
        resolve_content_edge_insets(self, stage)

    if effective_values.width == 'content' then
        resolved_width = max(
            0,
            left_inset + content_width + right_inset
        )

        if effective_values.minWidth ~= nil and
            resolved_width < effective_values.minWidth then
            resolved_width = effective_values.minWidth
        end

        if effective_values.maxWidth ~= nil and
            resolved_width > effective_values.maxWidth then
            resolved_width = effective_values.maxWidth
        end
    end

    if effective_values.height == 'content' then
        resolved_height = max(
            0,
            top_inset + content_height + bottom_inset
        )

        if effective_values.minHeight ~= nil and
            resolved_height < effective_values.minHeight then
            resolved_height = effective_values.minHeight
        end

        if effective_values.maxHeight ~= nil and
            resolved_height > effective_values.maxHeight then
            resolved_height = effective_values.maxHeight
        end
    end

    if rawget(self, '_resolved_width') == resolved_width and
        rawget(self, '_resolved_height') == resolved_height then
        return false
    end

    rawset(self, '_resolved_width', resolved_width)
    rawset(self, '_resolved_height', resolved_height)
    rawset(self, '_local_bounds_cache', Rectangle(0, 0, resolved_width, resolved_height))
    rawset(self, '_local_transform_dirty', true)
    rawset(self, '_world_transform_dirty', true)
    rawset(self, '_bounds_dirty', true)
    rawset(self, '_world_inverse_dirty', true)
    self:_refresh_layout_content_rect(stage)

    local children = rawget(self, '_children') or {}

    for index = 1, #children do
        children[index]:_mark_parent_layout_dependency_dirty()
    end

    return true
end

local function mark_children_parent_region_dirty(self)
    local children = rawget(self, '_children') or {}

    for index = 1, #children do
        local child = children[index]
        rawset(child, '_responsive_dirty', true)
        child:_mark_parent_layout_dependency_dirty()
    end
end



function SafeAreaContainer:constructor(opts)
    LayoutNode.constructor(self, opts, nil, {
        allow_content_width = true,
        allow_content_height = true,
    })
    self._ui_layout_kind = 'SafeAreaContainer'
end

function SafeAreaContainer.new(opts)
    return SafeAreaContainer(opts)
end

function SafeAreaContainer:_refresh_layout_content_rect(stage)
    local width = rawget(self, '_resolved_width') or 0
    local height = rawget(self, '_resolved_height') or 0
    local left_inset, top_inset, right_inset, bottom_inset =
        resolve_content_edge_insets(self, stage)
    local previous_rect = rawget(self, '_layout_content_rect_cache')
    local next_rect = Rectangle(
        left_inset,
        top_inset,
        max(0, width - left_inset - right_inset),
        max(0, height - top_inset - bottom_inset)
    )

    rawset(self, '_layout_content_rect_cache', next_rect)

    if previous_rect ~= nil and not previous_rect:equals(next_rect, 1e-9) then
        mark_children_parent_region_dirty(self)
    end

    return next_rect
end

function SafeAreaContainer:_prepare_for_layout_pass(stage)
    Container._prepare_for_layout_pass(self)
    self:_refresh_layout_content_rect(stage)
    return self
end

function SafeAreaContainer:_run_layout_pass(stage)
    self:_refresh_layout_content_rect(stage)

    if rawget(self, '_layout_dirty') then
        self:_apply_layout(stage)
        rawset(self, '_layout_dirty', false)
    end

    return self
end

function SafeAreaContainer:_apply_layout(stage)
    local content_rect = self:_refresh_layout_content_rect(stage)
    local children = place_children(self, content_rect)
    local effective_values = rawget(self, '_effective_values') or {}
    local width_mode = effective_values.width
    local height_mode = effective_values.height

    if width_mode ~= 'content' and height_mode ~= 'content' then
        return self
    end

    local content_width, content_height = measure_content_extent(children, content_rect)

    if apply_content_measurement(self, content_width, content_height, stage) then
        content_rect = self:_refresh_layout_content_rect(stage)
        place_children(self, content_rect)
    end

    return self
end

return SafeAreaContainer
