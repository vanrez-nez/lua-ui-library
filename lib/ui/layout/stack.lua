local LayoutNode = require('lib.ui.layout.layout_node')
local Rectangle = require('lib.ui.core.rectangle')
local LayoutSpacing = require('lib.ui.layout.spacing')
local ContentFillGuard = require('lib.ui.layout.content_fill_guard')
local Schema = require('lib.ui.utils.schema')
local StackSchema = require('lib.ui.layout.stack_schema')
local Constants = require('lib.ui.core.constants')

local max = math.max
local min = math.min

local Stack = LayoutNode:extends('Stack')
Stack.schema = Schema.extend(LayoutNode.schema, StackSchema)

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

local function resize_to_content(self, content_width, content_height)
    local padding = self.padding or {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
    }
    return self:_apply_content_measurement(
        padding.left + content_width + padding.right,
        padding.top + content_height + padding.bottom
    )
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
    local values = effective_values(self)
    local children = self._children
    local width_mode = values.width
    local height_mode = values.height
    local content_rect

    ContentFillGuard.assert_valid(
        'Stack',
        values,
        children,
        { 'width', 'height' },
        3
    )

    content_rect = self:_refresh_layout_content_rect()
    place_children(self, content_rect)

    if width_mode ~= Constants.SIZE_MODE_CONTENT and height_mode ~= Constants.SIZE_MODE_CONTENT then
        return self
    end

    local content_width, content_height = measure_content_extent(children, content_rect)

    if resize_to_content(self, content_width, content_height) then
        content_rect = self:_refresh_layout_content_rect()
        place_children(self, content_rect)
    end

    return self
end

return Stack
