local Assert = require('lib.ui.utils.assert')
local Container = require('lib.ui.core.container')
local LayoutNode = require('lib.ui.layout.layout_node')
local Rectangle = require('lib.ui.core.rectangle')
local LayoutSpacing = require('lib.ui.layout.spacing')
local SafeAreaContainerSchema = require('lib.ui.layout.safe_area_container_schema')

local max = math.max
local min = math.min

local SafeAreaContainer = LayoutNode:extends('SafeAreaContainer')
SafeAreaContainer._schema = SafeAreaContainerSchema

local APPLY_FLAG_KEYS = {
    left = 'applyLeft',
    top = 'applyTop',
    right = 'applyRight',
    bottom = 'applyBottom',
    applyLeft = 'applyLeft',
    applyTop = 'applyTop',
    applyRight = 'applyRight',
    applyBottom = 'applyBottom',
}

local function effective_values(node)
    return setmetatable({}, {
        __index = function(_, key)
            return node[key]
        end,
    })
end

local function child_is_visible(child)
    return child.visible ~= false
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
    local children = self._children

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

local function resolve_stage(node, stage)
    if stage ~= nil and stage._ui_stage_instance == true then
        return stage
    end

    local current = node

    while current ~= nil and current.parent ~= nil do
        current = current.parent
    end

    if current ~= nil and current._ui_stage_instance == true then
        return current
    end

    return nil
end

local function resolve_layout_world_rect(node)
    local values = effective_values(node)
    local width = node._resolved_width or 0
    local height = node._resolved_height or 0
    local parent_width = 0
    local parent_height = 0
    local world_x = node._layout_offset_x or 0
    local world_y = node._layout_offset_y or 0

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

    local safe_area_bounds = stage_root._safe_area_bounds_cache

    if not Rectangle.is_rectangle(safe_area_bounds) then
        return 0, 0, 0, 0
    end

    local world_rect = resolve_layout_world_rect(self)
    local values = effective_values(self)
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
    local padding = self.padding or {
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

local function resize_to_safe_area_content(self, content_width, content_height, stage)
    local left_inset, top_inset, right_inset, bottom_inset =
        resolve_content_edge_insets(self, stage)
    return self:_apply_content_measurement(
        max(0, left_inset + content_width + right_inset),
        max(0, top_inset + content_height + bottom_inset)
    )
end

local function mark_children_parent_region_dirty(self)
    local children = self._children

    for index = 1, #children do
        local child = children[index]
        child.dirty:mark('responsive')
        child:_mark_parent_layout_dependency_dirty()
    end
end



function SafeAreaContainer:constructor(opts)
    LayoutNode.constructor(self, opts, SafeAreaContainerSchema, {
        allow_content_width = true,
        allow_content_height = true,
    })
    self._ui_layout_kind = 'SafeAreaContainer'
end

function SafeAreaContainer:set_apply_flag(side, value)
    local key = APPLY_FLAG_KEYS[side]

    if key == nil then
        Assert.fail('SafeAreaContainer.set_apply_flag side is invalid', 2)
    end

    self[key] = value
    return self
end

function SafeAreaContainer.new(opts)
    return SafeAreaContainer(opts)
end

function SafeAreaContainer:_refresh_layout_content_rect(stage)
    local width = self._resolved_width or 0
    local height = self._resolved_height or 0
    local left_inset, top_inset, right_inset, bottom_inset =
        resolve_content_edge_insets(self, stage)
    local previous_rect = self._layout_content_rect_cache
    local next_rect = Rectangle(
        left_inset,
        top_inset,
        max(0, width - left_inset - right_inset),
        max(0, height - top_inset - bottom_inset)
    )

    self._layout_content_rect_cache = next_rect

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

    if self.dirty:is_dirty('layout') then
        self:_apply_layout(stage)
        self.dirty:clear('layout')
    end

    return self
end

function SafeAreaContainer:_apply_layout(stage)
    local content_rect = self:_refresh_layout_content_rect(stage)
    local children = place_children(self, content_rect)
    local effective_values = effective_values(self)
    local width_mode = effective_values.width
    local height_mode = effective_values.height

    if width_mode ~= 'content' and height_mode ~= 'content' then
        return self
    end

    local content_width, content_height = measure_content_extent(children, content_rect)

    if resize_to_safe_area_content(self, content_width, content_height, stage) then
        content_rect = self:_refresh_layout_content_rect(stage)
        place_children(self, content_rect)
    end

    return self
end

return SafeAreaContainer
