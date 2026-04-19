local Assert = require('lib.ui.utils.assert')
local LayoutNode = require('lib.ui.layout.layout_node')
local Types = require('lib.ui.utils.types')
local MathUtils = require('lib.ui.utils.math')
local LayoutSpacing = require('lib.ui.layout.spacing')
local Direction = require('lib.ui.layout.direction')
local ContentFillGuard = require('lib.ui.layout.content_fill_guard')
local FlowSchema = require('lib.ui.layout.flow_schema')
local Enums = require('lib.ui.core.enums')
local Constants = require('lib.ui.core.constants')
local Enum = require('lib.ui.utils.enum')

local max = math.max
local clamp_number = MathUtils.clamp_number
local resolve_axis_size = MathUtils.resolve_axis_size
local is_percentage_string = MathUtils.is_percentage_string
local enum_has = Enum.enum_has

local Flow = LayoutNode:extends('Flow')
Flow._schema = FlowSchema

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

local function get_axis_size(node, axis_key)
    if axis_key == 'width' then
        return node._resolved_width or 0
    end

    return node._resolved_height or 0
end

local function depends_on_parent_axis(value)
    return value == Constants.SIZE_MODE_FILL or is_percentage_string(value)
end

local function resolve_axis(value, available, min_value, max_value)
        if value == Constants.SIZE_MODE_CONTENT or value == nil then
        return nil
    end

    if value == Constants.SIZE_MODE_FILL then
        Assert.fail('Flow does not define fill resolution for child axes', 3)
    end

    return clamp_number(
        resolve_axis_size(value, available),
        min_value,
        max_value
    )
end

local function validate_effective_props(self)
    local effective_values = effective_values(self)
    local gap = effective_values.gap
    local wrap = effective_values.wrap
    local justify = effective_values.justify
    local align = effective_values.align
    local direction = effective_values.direction

    Assert.number('Flow.gap', gap, 3)
    Assert.boolean('Flow.wrap', wrap, 3)

    if not Types.is_string(justify) or not enum_has(Enums.Justify, justify) then
        Assert.fail(
            'Flow.justify must be "start", "center", "end", or "space-between", or "space-around"',
            3
        )
    end

    if not Types.is_string(align) or not enum_has(Enums.Alignment, align) then
        Assert.fail(
            'Flow.align must be "start", "center", "end", or "stretch"',
            3
        )
    end

    Direction.validate('Flow', direction, 3)

    return gap, wrap, justify, align, direction
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

    child:_apply_resolved_size(resolved_width, resolved_height)

    if LayoutNode.is_layout_node(child) then
        child:_run_layout_pass(stage)
    end

    child:_refresh_if_dirty()
    entry.width = get_axis_size(child, 'width')
    entry.height = get_axis_size(child, 'height')
    entry.outer_width = LayoutSpacing.get_outer_size(
        entry.width,
        entry.margin.left,
        entry.margin.right
    )
    entry.outer_height = LayoutSpacing.get_outer_size(
        entry.height,
        entry.margin.top,
        entry.margin.bottom
    )
    return entry
end

local function assert_no_circular_dependency(self, child)
    local self_values = effective_values(self)
    local child_values = effective_values(child)

    if self_values.width == Constants.SIZE_MODE_CONTENT and
        depends_on_parent_axis(child_values.width) then
        Assert.fail(
            'Flow has a circular measurement dependency because width = "content" and a child depends on parent width',
            3
        )
    end

    if self_values.height == Constants.SIZE_MODE_CONTENT and
        depends_on_parent_axis(child_values.height) then
        Assert.fail(
            'Flow has a circular measurement dependency because height = "content" ' ..
                'and a child depends on parent height',
            3
        )
    end
end

local function make_entry(child)
    local margin = LayoutSpacing.get_effective_margin(child)

    return {
        child = child,
        values = effective_values(child),
        margin = margin,
        width = 0,
        height = 0,
        outer_width = LayoutSpacing.get_outer_size(0, margin.left, margin.right),
        outer_height = LayoutSpacing.get_outer_size(0, margin.top, margin.bottom),
        pack_width = 0,
    }
end

local function refresh_row_height(row)
    local height = 0

    for index = 1, #row.entries do
        height = max(height, row.entries[index].outer_height or 0)
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
        row.height = max(row.height or 0, entry.outer_height or 0)
    end

    return rows
end

local function resolve_justify(justify, available_width, used_width, gap, child_count, is_last_wrapped_row)
    local base_x = 0
    local between_gap = gap

    if child_count == 0 then
        return base_x, between_gap
    end

    local extra = available_width - used_width

    if justify == Constants.ALIGN_CENTER then
        return extra / 2, between_gap
    end

    if justify == Constants.ALIGN_END then
        return extra, between_gap
    end

    if extra <= 0 then
        return 0, between_gap
    end

    if justify == Constants.JUSTIFY_SPACE_BETWEEN then
        -- Flow keeps justify as the owner of the last wrapped row. The only
        -- special-case is sparse last-row space-between, where one large gap
        -- becomes visually misleading, so it degenerates to start.
        if child_count == 1 or (is_last_wrapped_row and child_count <= 2) then
            return 0, between_gap
        end

        return 0, between_gap + (extra / (child_count - 1))
    end

    if justify == Constants.JUSTIFY_SPACE_AROUND then
        local around = extra / child_count
        return around / 2, between_gap + around
    end

    return 0, between_gap
end
local function reverse_entries(entries)
    local reversed = {}

    for index = #entries, 1, -1 do
        reversed[#reversed + 1] = entries[index]
    end

    return reversed
end

local function resize_to_flow_content(self, content_width, content_height)
    local padding = effective_values.padding or {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
    }
    local resolved_width = self._resolved_width or 0
    local resolved_height = self._resolved_height or 0

    if effective_values.width == Constants.SIZE_MODE_CONTENT then
        resolved_width = clamp_number(
            padding.left + content_width + padding.right,
            effective_values.minWidth,
            effective_values.maxWidth
        )
    end

    if effective_values.height == Constants.SIZE_MODE_CONTENT then
        resolved_height = clamp_number(
            padding.top + content_height + padding.bottom,
            effective_values.minHeight,
            effective_values.maxHeight
        )
    end

    return self:_apply_resolved_size(resolved_width, resolved_height)
end

local function place_invisible_children(invisible_children, content_rect)
    for index = 1, #invisible_children do
        local child = invisible_children[index]
        child:_set_layout_offset(content_rect.x, content_rect.y)
        child:_refresh_if_dirty()
    end
end

function Flow:constructor(opts)
    LayoutNode.constructor(self, opts, FlowSchema, {
        allow_content_width = true,
        allow_content_height = true,
    })
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
        local gap, wrap, justify, _, direction = validate_effective_props(self)
        local children = self._children
        local content_rect
        local available_width
        local available_height
        local visible_entries = {}
        local invisible_children = {}

        ContentFillGuard.assert_valid(
            'Flow',
            effective_values,
            children,
            { 'width' },
            3
        )

        content_rect = self:_refresh_layout_content_rect()
        available_width = content_rect.width or 0
        available_height = content_rect.height or 0

        if wrap and effective_values.width == Constants.SIZE_MODE_CONTENT then
            wrap = false
        end

        for index = 1, #children do
            local child = children[index]

            if child_is_visible(child) then
                assert_no_circular_dependency(self, child)

                local entry = make_entry(child)
                measure_entry(entry, stage, available_width, available_height)
                entry.pack_width = entry.outer_width
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

        if resize_to_flow_content(self, content_width, content_height) then
            content_rect = self:_refresh_layout_content_rect()
            available_width = content_rect.width or 0
        end

        local y_cursor = 0

        for row_index = 1, #rows do
            local row = rows[row_index]
            local placement_entries = row.entries
            local base_x
            local between_gap
            local is_last_wrapped_row = wrap and #rows > 1 and row_index == #rows

            base_x, between_gap = resolve_justify(
                justify,
                available_width,
                row.pack_width or 0,
                gap,
                #row.entries,
                is_last_wrapped_row
            )

            if direction == Constants.DIRECTION_RTL then
                placement_entries = reverse_entries(row.entries)
            end

            local x_cursor = base_x

            if direction == Constants.DIRECTION_RTL then
                for entry_index = #placement_entries, 1, -1 do
                    local entry = placement_entries[entry_index]
                    local child = entry.child
                    local offset_x = content_rect.x + content_rect.width -
                        x_cursor -
                        (entry.outer_width or 0) +
                        entry.margin.left

                    child:_set_layout_offset(
                        offset_x,
                        content_rect.y + y_cursor + entry.margin.top
                    )
                    child:_refresh_if_dirty()

                    x_cursor = x_cursor + (entry.outer_width or 0)

                    if entry_index > 1 then
                        x_cursor = x_cursor + between_gap
                    end
                end
            else
                for entry_index = 1, #placement_entries do
                    local entry = placement_entries[entry_index]
                    local child = entry.child

                    child:_set_layout_offset(
                        content_rect.x + x_cursor + entry.margin.left,
                        content_rect.y + y_cursor + entry.margin.top
                    )
                    child:_refresh_if_dirty()

                    x_cursor = x_cursor + (entry.outer_width or 0)

                    if entry_index < #placement_entries then
                        x_cursor = x_cursor + between_gap
                    end
                end
            end

            y_cursor = y_cursor + (row.height or 0)

            if row_index < #rows then
                y_cursor = y_cursor + gap
            end
        end

        place_invisible_children(invisible_children, content_rect)

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
