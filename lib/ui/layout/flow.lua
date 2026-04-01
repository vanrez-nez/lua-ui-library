local Assert = require('lib.ui.utils.assert')
local LayoutNode = require('lib.ui.layout.layout_node')
local Types = require('lib.ui.utils.types')
local MathUtils = require('lib.ui.utils.math')
local Rectangle = require('lib.ui.core.rectangle')

local max = math.max
local clamp_number = MathUtils.clamp_number
local resolve_axis_size = MathUtils.resolve_axis_size
local is_percentage_string = MathUtils.is_percentage_string

local Flow = LayoutNode:extends('Flow')

local JUSTIFY_VALUES = {
    start = true,
    center = true,
    ['end'] = true,
    ['space-between'] = true,
    ['space-around'] = true,
}

local ALIGN_VALUES = {
    start = true,
    center = true,
    ['end'] = true,
    stretch = true,
}

local function child_is_visible(child)
    local effective_values = rawget(child, '_effective_values')

    if effective_values == nil then
        return true
    end

    return effective_values.visible ~= false
end

local function get_axis_size(node, axis_key)
    if axis_key == 'width' then
        return node._resolved_width or 0
    end

    return node._resolved_height or 0
end

local function depends_on_parent_axis(value)
    return value == 'fill' or is_percentage_string(value)
end

local function apply_resolved_size(node, width, height)
    local resolved_width = width
    local resolved_height = height

    if resolved_width == nil then
        resolved_width = node._resolved_width or 0
    end

    if resolved_height == nil then
        resolved_height = node._resolved_height or 0
    end

    if node._resolved_width == resolved_width and
        node._resolved_height == resolved_height then
        node._measurement_dirty = false
        return false
    end

    node._resolved_width = resolved_width
    node._resolved_height = resolved_height
    node._measurement_dirty = false
    node._local_bounds_cache = Rectangle(0, 0, resolved_width, resolved_height)
    node._local_transform_dirty = true
    node._world_transform_dirty = true
    node._bounds_dirty = true
    node._world_inverse_dirty = true

    if node._ui_layout_instance == true and
        Types.is_function(node._refresh_layout_content_rect) then
        node:_refresh_layout_content_rect()
    end

    local children = rawget(node, '_children') or {}

    for index = 1, #children do
        children[index]:_mark_parent_layout_dependency_dirty()
    end

    return true
end

local function resolve_axis(value, available, min_value, max_value)
    if value == 'content' or value == nil then
        return nil
    end

    return clamp_number(
        resolve_axis_size(value, available),
        min_value,
        max_value
    )
end

local function validate_effective_props(self)
    local effective_values = rawget(self, '_effective_values') or {}
    local gap = effective_values.gap
    local wrap = effective_values.wrap
    local justify = effective_values.justify
    local align = effective_values.align

    Assert.number('Flow.gap', gap, 3)
    Assert.boolean('Flow.wrap', wrap, 3)

    if not Types.is_string(justify) or not JUSTIFY_VALUES[justify] then
        Assert.fail(
            'Flow.justify must be "start", "center", "end", or "space-between", or "space-around"',
            3
        )
    end

    if not Types.is_string(align) or not ALIGN_VALUES[align] then
        Assert.fail(
            'Flow.align must be "start", "center", "end", or "stretch"',
            3
        )
    end

    return gap, wrap, justify, align
end

local function measure_entry(entry, stage, available_width, available_height,
        forced_width, forced_height)
    local child = entry.child
    local values = entry.values
    local resolved_width = forced_width
    local resolved_height = forced_height

    if resolved_width == nil then
        resolved_width = resolve_axis(
            values.width,
            available_width,
            values.minWidth,
            values.maxWidth
        )
    end

    if resolved_height == nil then
        resolved_height = resolve_axis(
            values.height,
            available_height,
            values.minHeight,
            values.maxHeight
        )
    end

    apply_resolved_size(child, resolved_width, resolved_height)

    if LayoutNode.is_layout_node(child) then
        child:_run_layout_pass(stage)
    end

    child:_refresh_if_dirty()
    entry.width = get_axis_size(child, 'width')
    entry.height = get_axis_size(child, 'height')
    return entry
end

local function assert_no_circular_dependency(self, child)
    local self_values = rawget(self, '_effective_values') or {}
    local child_values = rawget(child, '_effective_values') or {}

    if self_values.width == 'content' and
        depends_on_parent_axis(child_values.width) then
        Assert.fail(
            'Flow has a circular measurement dependency because width = "content" and a child depends on parent width',
            3
        )
    end

    if self_values.height == 'content' and
        depends_on_parent_axis(child_values.height) then
        Assert.fail(
            'Flow has a circular measurement dependency because height = "content" and a child depends on parent height',
            3
        )
    end
end

local function make_entry(child)
    return {
        child = child,
        values = rawget(child, '_effective_values') or {},
        width = 0,
        height = 0,
        pack_width = 0,
    }
end

local function refresh_row_height(row)
    local height = 0

    for index = 1, #row.entries do
        height = max(height, row.entries[index].height or 0)
    end

    row.height = height
    return height
end

local function build_rows(entries, available_width, gap, wrap)
    local rows = {}
    local row = nil

    for index = 1, #entries do
        local entry = entries[index]
        local next_width = entry.pack_width

        if row == nil then
            row = {
                entries = {},
                pack_width = 0,
                height = 0,
            }
            rows[#rows + 1] = row
        end

        if #row.entries > 0 then
            next_width = next_width + row.pack_width + gap
        end

        if wrap and #row.entries > 0 and next_width > available_width then
            refresh_row_height(row)
            row = {
                entries = {},
                pack_width = 0,
                height = 0,
            }
            rows[#rows + 1] = row
            next_width = entry.pack_width
        end

        row.entries[#row.entries + 1] = entry
        row.pack_width = next_width
        row.height = max(row.height or 0, entry.height or 0)
    end

    return rows
end

local function resolve_justify(justify, available_width, used_width, gap, child_count)
    local base_x = 0
    local between_gap = gap

    if child_count == 0 then
        return base_x, between_gap
    end

    local extra = available_width - used_width

    if justify == 'center' then
        return extra / 2, between_gap
    end

    if justify == 'end' then
        return extra, between_gap
    end

    if extra <= 0 then
        return 0, between_gap
    end

    if justify == 'space-between' then
        if child_count == 1 then
            return 0, between_gap
        end

        return 0, between_gap + (extra / (child_count - 1))
    end

    if justify == 'space-around' then
        local around = extra / child_count
        return around / 2, between_gap + around
    end

    return 0, between_gap
end

local function resolve_last_row_alignment(align, available_width, used_width, gap)
    local extra = available_width - used_width

    if extra <= 0 then
        return 0, gap
    end

    if align == 'center' then
        return extra / 2, gap
    end

    if align == 'end' then
        return extra, gap
    end

    return 0, gap
end

local function apply_self_content_measurement(self, content_width, content_height)
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

local function place_invisible_children(self, invisible_children, content_rect)
    for index = 1, #invisible_children do
        local child = invisible_children[index]
        child:_set_layout_offset(content_rect.x, content_rect.y)
        child:_refresh_if_dirty()
    end
end

function Flow:constructor(opts)
    LayoutNode.constructor(self, opts)
    self._ui_layout_kind = 'Flow'
end

function Flow.new(opts)
    return Flow(opts)
end

function Flow:_apply_layout(stage)
    if self._flow_layout_measurement_in_progress then
        Assert.fail(
            'circular measurement dependency detected while measuring Flow',
            3
        )
    end

    self._flow_layout_measurement_in_progress = true

    local ok, result = xpcall(function()
        local gap, wrap, justify, align = validate_effective_props(self)
        local content_rect = self:_refresh_layout_content_rect()
        local available_width = content_rect.width or 0
        local available_height = content_rect.height or 0
        local effective_values = rawget(self, '_effective_values') or {}
        local children = rawget(self, '_children') or {}
        local visible_entries = {}
        local invisible_children = {}

        if wrap and effective_values.width == 'content' then
            wrap = false
        end

        for index = 1, #children do
            local child = children[index]

            if child_is_visible(child) then
                assert_no_circular_dependency(self, child)

                local entry = make_entry(child)
                measure_entry(entry, stage, available_width, available_height)
                entry.pack_width = entry.width
                visible_entries[#visible_entries + 1] = entry
            else
                invisible_children[#invisible_children + 1] = child
            end
        end

        local rows = build_rows(visible_entries, available_width, gap, wrap)
        local content_width = 0
        local content_height = 0

        for row_index = 1, #rows do
            local row = rows[row_index]

            refresh_row_height(row)
            content_width = max(content_width, row.pack_width or 0)
            content_height = content_height + (row.height or 0)

            if row_index < #rows then
                content_height = content_height + gap
            end
        end

        if apply_self_content_measurement(self, content_width, content_height) then
            content_rect = self:_refresh_layout_content_rect()
            available_width = content_rect.width or 0
        end

        local y_cursor = 0
        local use_last_row_alignment = wrap and #rows > 1

        for row_index = 1, #rows do
            local row = rows[row_index]
            local base_x
            local between_gap

            if use_last_row_alignment and row_index == #rows then
                -- The last wrapped row aligns by Flow.align and keeps the declared gap.
                base_x, between_gap = resolve_last_row_alignment(
                    align,
                    available_width,
                    row.pack_width or 0,
                    gap
                )
            else
                base_x, between_gap = resolve_justify(
                    justify,
                    available_width,
                    row.pack_width or 0,
                    gap,
                    #row.entries
                )
            end

            local x_cursor = base_x

            for entry_index = 1, #row.entries do
                local entry = row.entries[entry_index]
                local child = entry.child

                child:_set_layout_offset(content_rect.x + x_cursor, content_rect.y + y_cursor)
                child:_refresh_if_dirty()

                x_cursor = x_cursor + (entry.width or 0)

                if entry_index < #row.entries then
                    x_cursor = x_cursor + between_gap
                end
            end

            y_cursor = y_cursor + (row.height or 0)

            if row_index < #rows then
                y_cursor = y_cursor + gap
            end
        end

        place_invisible_children(self, invisible_children, content_rect)

        return self
    end, function(err)
        return err
    end)

    self._flow_layout_measurement_in_progress = false

    if not ok then
        error(result, 0)
    end

    return result
end

return Flow
