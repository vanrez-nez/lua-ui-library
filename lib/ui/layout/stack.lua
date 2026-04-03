local LayoutNode = require('lib.ui.layout.layout_node')
local MathUtils = require('lib.ui.utils.math')
local Rectangle = require('lib.ui.core.rectangle')
local LayoutSpacing = require('lib.ui.layout.spacing')

local max = math.max
local min = math.min
local clamp_number = MathUtils.clamp_number

local Stack = LayoutNode:extends('Stack')
Stack._schema = require('lib.ui.layout.stack_schema')

local function child_is_visible(child)
    local effective_values = rawget(child, '_effective_values')

    if effective_values == nil then
        return true
    end

    return effective_values.visible ~= false
end

local function get_child_parent_local_bounds(child)
    local matrix = child._local_transform_cache
    local width = child._resolved_width or 0
    local height = child._resolved_height or 0
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
        local margin = LayoutSpacing.get_effective_margin(child)
        local offset_x, offset_y =
            LayoutSpacing.resolve_stack_layout_offset(content_rect, child, margin)
        child:_set_layout_offset(offset_x, offset_y)
        child:_refresh_if_dirty()
    end

    return children
end

local function measure_content_extent(children, content_rect)
    local content_bounds = nil

    for index = 1, #children do
        local child = children[index]

        if child_is_visible(child) then
            local margin = LayoutSpacing.get_effective_margin(child)
            local bounds = get_child_parent_local_bounds(child)
            local left, top, right, bottom =
                LayoutSpacing.resolve_outer_edges(bounds, margin)
            local outer_bounds = Rectangle.from_edges(
                left - content_rect.x,
                top - content_rect.y,
                right - content_rect.x,
                bottom - content_rect.y
            )

            if content_bounds == nil then
                content_bounds = outer_bounds
            else
                content_bounds = content_bounds:union(outer_bounds)
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

local function apply_content_measurement(self, content_width, content_height)
    local effective_values = rawget(self, '_effective_values') or {}
    local padding = effective_values.padding or {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
    }
    local resolved_width = self._resolved_width or 0
    local resolved_height = self._resolved_height or 0

    if effective_values.width == 'content' then
        resolved_width = clamp_number(
            padding.left + content_width + padding.right,
            effective_values.minWidth,
            effective_values.maxWidth
        )
    end

    if effective_values.height == 'content' then
        resolved_height = clamp_number(
            padding.top + content_height + padding.bottom,
            effective_values.minHeight,
            effective_values.maxHeight
        )
    end

    if self._resolved_width == resolved_width and
        self._resolved_height == resolved_height then
        return false
    end

    self._resolved_width = resolved_width
    self._resolved_height = resolved_height
    self._local_bounds_cache = Rectangle(0, 0, resolved_width, resolved_height)
    self._local_transform_dirty = true
    self._world_transform_dirty = true
    self._bounds_dirty = true
    self._world_inverse_dirty = true
    self:_refresh_layout_content_rect()

    local children = rawget(self, '_children') or {}

    for index = 1, #children do
        children[index]:_mark_parent_layout_dependency_dirty()
    end

    return true
end

function Stack:constructor(opts)
    LayoutNode.constructor(self, opts, nil, {
        allow_content_width = true,
        allow_content_height = true,
    })
    self._ui_layout_kind = 'Stack'
end

function Stack.new(opts)
    return Stack(opts)
end

function Stack:_apply_layout(_)
    local content_rect = self:_refresh_layout_content_rect()
    local children = place_children(self, content_rect)
    local width_mode = self._effective_values.width
    local height_mode = self._effective_values.height

    if width_mode ~= 'content' and height_mode ~= 'content' then
        return self
    end

    local content_width, content_height = measure_content_extent(children, content_rect)

    if apply_content_measurement(self, content_width, content_height) then
        content_rect = self:_refresh_layout_content_rect()
        place_children(self, content_rect)
    end

    return self
end

return Stack
