local Assert = require('lib.ui.utils.assert')
local LayoutNode = require('lib.ui.layout.layout_node')
local Types = require('lib.ui.utils.types')
local MathUtils = require('lib.ui.utils.math')
local LayoutSpacing = require('lib.ui.layout.spacing')
local Direction = require('lib.ui.layout.direction')
local ContentFillGuard = require('lib.ui.layout.content_fill_guard')

local max = math.max
local clamp_number = MathUtils.clamp_number
local resolve_axis_size = MathUtils.resolve_axis_size
local is_percentage_string = MathUtils.is_percentage_string

local SequentialLayout = {}

local function effective_values(node)
    return setmetatable({}, {
        __index = function(_, key)
            return node[key]
        end,
    })
end

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
    return child.visible ~= false
end

local function get_axis_keys(config)
    return
        config.main_size_key,
        config.cross_size_key,
        config.main_min_key,
        config.main_max_key,
        config.cross_min_key,
        config.cross_max_key
end

local function get_axis_size(node, axis_key)
    if axis_key == 'width' then
        return node._resolved_width or 0
    end

    return node._resolved_height or 0
end

local function get_rect_axis_size(rect, axis_key)
    if axis_key == 'width' then
        return rect.width or 0
    end

    return rect.height or 0
end

local function depends_on_parent_axis(value)
    return value == 'fill' or is_percentage_string(value)
end

local function validate_effective_props(self, config)
    local effective_values = effective_values(self)
    local justify = effective_values.justify
    local align = effective_values.align
    local wrap = effective_values.wrap
    local gap = effective_values.gap

    Assert.number(config.kind .. '.gap', gap, 3)
    Assert.boolean(config.kind .. '.wrap', wrap, 3)

    if not Types.is_string(justify) or not JUSTIFY_VALUES[justify] then
        Assert.fail(
            config.kind ..
                '.justify must be "start", "center", "end", "space-between", or "space-around"',
            3
        )
    end

    if not Types.is_string(align) or not ALIGN_VALUES[align] then
        Assert.fail(
            config.kind ..
                '.align must be "start", "center", "end", or "stretch"',
            3
        )
    end

    if config.kind == 'Row' then
        Direction.validate('Row', effective_values.direction, 3)
    end

    return justify, align, wrap, gap
end

local function resolve_axis(value, available, min_value, max_value, config, axis_key)
    if value == 'content' or value == nil then
        return nil
    end

    if value == 'fill' then
        if axis_key == config.main_size_key then
            return nil
        end

        return clamp_number(
            available or 0,
            min_value,
            max_value
        )
    end

    return clamp_number(
        resolve_axis_size(value, available),
        min_value,
        max_value
    )
end

local function refresh_entry_outer_sizes(entry)
    entry.outer_main = LayoutSpacing.get_outer_size(
        entry.final_main,
        entry.main_leading,
        entry.main_trailing
    )
    entry.outer_cross = LayoutSpacing.get_outer_size(
        entry.final_cross,
        entry.cross_leading,
        entry.cross_trailing
    )
    return entry
end

local function get_line_main_extent(line, gap)
    local total = 0

    for index = 1, #line.entries do
        total = total + (line.entries[index].outer_main or 0)
    end

    if #line.entries > 1 then
        total = total + gap * (#line.entries - 1)
    end

    return total
end

local function refresh_line_cross_extent(line)
    local cross_extent = 0

    for index = 1, #line.entries do
        cross_extent = max(cross_extent, line.entries[index].outer_cross or 0)
    end

    line.cross_extent = cross_extent
    return cross_extent
end

local function measure_entry(entry, stage, config, available_main, available_cross,
        forced_main, forced_cross)
    local child = entry.child
    local values = entry.values
    local main_size_key, cross_size_key, main_min_key, main_max_key,
        cross_min_key, cross_max_key = get_axis_keys(config)
    local resolved_main = forced_main
    local resolved_cross = forced_cross

    if resolved_main == nil then
        resolved_main = resolve_axis(
            values[main_size_key],
            available_main,
            values[main_min_key],
            values[main_max_key],
            config,
            main_size_key
        )
    end

    if resolved_cross == nil then
        resolved_cross = resolve_axis(
            values[cross_size_key],
            available_cross,
            values[cross_min_key],
            values[cross_max_key],
            config,
            cross_size_key
        )
    end

    if config.main_size_key == 'width' then
        child:_apply_resolved_size(resolved_main, resolved_cross)
    else
        child:_apply_resolved_size(resolved_cross, resolved_main)
    end

    if LayoutNode.is_layout_node(child) then
        child:_run_layout_pass(stage)
    end

    child:_refresh_if_dirty()

    entry.final_main = get_axis_size(child, config.main_size_key)
    entry.final_cross = get_axis_size(child, config.cross_size_key)
    refresh_entry_outer_sizes(entry)

    return entry
end

local function assert_no_circular_dependency(self, child, config, align)
    local self_values = effective_values(self)
    local child_values = effective_values(child)

    if self_values[config.main_size_key] == 'content' and
        depends_on_parent_axis(child_values[config.main_size_key]) then
        Assert.fail(
            config.kind ..
                ' has a circular measurement dependency because ' ..
                config.main_size_key ..
                ' = "content" and a child depends on parent ' ..
                config.main_size_key,
            3
        )
    end

    if self_values[config.cross_size_key] == 'content' and
        (depends_on_parent_axis(child_values[config.cross_size_key]) or
            align == 'stretch') then
        Assert.fail(
            config.kind ..
                ' has a circular measurement dependency because ' ..
                config.cross_size_key ..
                ' = "content" and a child depends on parent ' ..
                config.cross_size_key,
            3
        )
    end
end

local function make_entry(child, config)
    local margin = LayoutSpacing.get_effective_margin(child)
    local main_leading, main_trailing, cross_leading, cross_trailing =
        LayoutSpacing.resolve_axis_margins(margin, config.main_size_key)

    return {
        child = child,
        values = effective_values(child),
        margin = margin,
        main_leading = main_leading,
        main_trailing = main_trailing,
        cross_leading = cross_leading,
        cross_trailing = cross_trailing,
        final_main = 0,
        final_cross = 0,
        outer_main = LayoutSpacing.get_outer_size(0, main_leading, main_trailing),
        outer_cross = LayoutSpacing.get_outer_size(0, cross_leading, cross_trailing),
    }
end

local function build_lines(entries, available_main, gap, wrap)
    local lines = {}
    local line = nil

    for index = 1, #entries do
        local entry = entries[index]
        local entry_main = entry.pack_main

        if line == nil then
            line = {
                entries = {},
                pack_extent = 0,
                cross_extent = 0,
            }
            lines[#lines + 1] = line
        end

        local next_extent = line.pack_extent + entry_main

        if #line.entries > 0 then
            next_extent = next_extent + gap
        end

        if wrap and #line.entries > 0 and next_extent > available_main then
            line = {
                entries = {},
                pack_extent = 0,
                cross_extent = 0,
            }
            lines[#lines + 1] = line
            next_extent = entry_main
        end

        line.entries[#line.entries + 1] = entry
        line.pack_extent = next_extent
    end

    return lines
end

local function allocate_fill_sizes(line, available_main, gap, config)
    local fixed_extent = 0
    local fill_margin_extent = 0
    local fill_entries = {}

    for index = 1, #line.entries do
        local entry = line.entries[index]

        if entry.values[config.main_size_key] == 'fill' then
            fill_entries[#fill_entries + 1] = entry
            fill_margin_extent = fill_margin_extent +
                entry.main_leading +
                entry.main_trailing
        else
            fixed_extent = fixed_extent + (entry.outer_main or 0)
        end
    end

    if #fill_entries == 0 then
        return line
    end

    local remaining = available_main - fixed_extent - fill_margin_extent

    if #line.entries > 1 then
        remaining = remaining - gap * (#line.entries - 1)
    end

    local unresolved = {}

    for index = 1, #fill_entries do
        unresolved[index] = fill_entries[index]
    end

    local available_remaining = max(0, remaining)

    while #unresolved > 0 do
        local share = available_remaining / #unresolved
        local clamped = false

        for index = #unresolved, 1, -1 do
            local entry = unresolved[index]
            local values = entry.values
            local resolved = clamp_number(
                share,
                values[config.main_min_key],
                values[config.main_max_key]
            )

            if resolved ~= share then
                entry.final_main = resolved
                available_remaining = available_remaining - resolved
                refresh_entry_outer_sizes(entry)
                table.remove(unresolved, index)
                clamped = true
            end
        end

        if not clamped then
            break
        end
    end

    if #unresolved > 0 then
        local share = available_remaining / #unresolved

        for index = 1, #unresolved do
            local entry = unresolved[index]
            local values = entry.values

            entry.final_main = clamp_number(
                share,
                values[config.main_min_key],
                values[config.main_max_key]
            )
            refresh_entry_outer_sizes(entry)
        end
    end

    return line
end

local function resolve_justify(justify, available_main, used_main, gap, child_count)
    local base = 0
    local between_gap = gap

    if child_count == 0 then
        return base, between_gap
    end

    local extra = available_main - used_main

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

local function resize_to_sequential_content(self, main_content_size, cross_content_size,
        config)
    local effective_values = effective_values(self)
    local resolved_width = self._resolved_width or 0
    local resolved_height = self._resolved_height or 0
    local padding = effective_values.padding or {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
    }

    if config.main_size_key == 'width' then
        if effective_values.width == 'content' then
            resolved_width = clamp_number(
                padding.left + main_content_size + padding.right,
                effective_values.minWidth,
                effective_values.maxWidth
            )
        end

        if effective_values.height == 'content' then
            resolved_height = clamp_number(
                padding.top + cross_content_size + padding.bottom,
                effective_values.minHeight,
                effective_values.maxHeight
            )
        end
    else
        if effective_values.height == 'content' then
            resolved_height = clamp_number(
                padding.top + main_content_size + padding.bottom,
                effective_values.minHeight,
                effective_values.maxHeight
            )
        end

        if effective_values.width == 'content' then
            resolved_width = clamp_number(
                padding.left + cross_content_size + padding.right,
                effective_values.minWidth,
                effective_values.maxWidth
            )
        end
    end

    return self:_apply_resolved_size(resolved_width, resolved_height)
end

local function place_invisible_children(self, invisible_children, content_rect)
    for index = 1, #invisible_children do
        local child = invisible_children[index]
        child:_set_layout_offset(content_rect.x, content_rect.y)
        child:_refresh_if_dirty()
    end
end

function SequentialLayout.apply(self, stage, config)
    if self._sequential_layout_measurement_in_progress then
        Assert.fail(
            'circular measurement dependency detected while measuring ' ..
                config.kind,
            3
        )
    end

    self._sequential_layout_measurement_in_progress = true

    local ok, result = xpcall(function()
        local justify, align, wrap, gap = validate_effective_props(self, config)
        local effective_values = effective_values(self)
        local children = rawget(self, '_children')
        local content_rect
        local available_main
        local available_cross
        local main_mode = effective_values[config.main_size_key]
        local visible_entries = {}
        local invisible_children = {}

        ContentFillGuard.assert_valid(
            config.kind,
            effective_values,
            children,
            { config.main_size_key },
            3
        )

        content_rect = self:_refresh_layout_content_rect()
        available_main = get_rect_axis_size(content_rect, config.main_size_key)
        available_cross = get_rect_axis_size(content_rect, config.cross_size_key)

        if wrap and main_mode == 'content' then
            wrap = false
        end

        for index = 1, #children do
            local child = children[index]

            if child_is_visible(child) then
                assert_no_circular_dependency(self, child, config, align)

                local entry = make_entry(child, config)
                local main_value = entry.values[config.main_size_key]

                if main_value == 'fill' then
                    entry.final_main = clamp_number(
                        0,
                        entry.values[config.main_min_key],
                        entry.values[config.main_max_key]
                    )
                    refresh_entry_outer_sizes(entry)
                    entry.pack_main = entry.outer_main
                else
                    measure_entry(entry, stage, config, available_main, available_cross)
                    entry.pack_main = entry.outer_main
                end

                visible_entries[#visible_entries + 1] = entry
            else
                invisible_children[#invisible_children + 1] = child
            end
        end

        local lines = build_lines(visible_entries, available_main, gap, wrap)

        for line_index = 1, #lines do
            local line = lines[line_index]

            allocate_fill_sizes(line, available_main, gap, config)

            for entry_index = 1, #line.entries do
                local entry = line.entries[entry_index]

                if entry.values[config.main_size_key] == 'fill' then
                    measure_entry(
                        entry,
                        stage,
                        config,
                        available_main,
                        available_cross,
                        entry.final_main
                    )
                end
            end

            refresh_line_cross_extent(line)

            local stretch_cross = line.cross_extent

            if not wrap and effective_values[config.cross_size_key] ~= 'content' and
                align == 'stretch' then
                stretch_cross = available_cross
            end

            if align == 'stretch' then
                for entry_index = 1, #line.entries do
                    local entry = line.entries[entry_index]

                    measure_entry(
                        entry,
                        stage,
                        config,
                        available_main,
                        available_cross,
                        entry.final_main,
                        max(0, stretch_cross - entry.cross_leading - entry.cross_trailing)
                    )
                end
            end

            line.main_extent = get_line_main_extent(line, gap)
            refresh_line_cross_extent(line)
        end

        local main_content_size = 0
        local cross_content_size = 0

        for line_index = 1, #lines do
            local line = lines[line_index]

            main_content_size = max(main_content_size, line.main_extent or 0)
            cross_content_size = cross_content_size + (line.cross_extent or 0)

            if line_index > 1 then
                cross_content_size = cross_content_size + gap
            end
        end

        if resize_to_sequential_content(
                self,
                main_content_size,
                cross_content_size,
                config
            ) then
            content_rect = self:_refresh_layout_content_rect()
            available_main = get_rect_axis_size(content_rect, config.main_size_key)
            available_cross = get_rect_axis_size(content_rect, config.cross_size_key)
        end

        local cross_cursor = 0
        local direction = 'ltr'

        if config.kind == 'Row' then
            direction = effective_values.direction
        end

        for line_index = 1, #lines do
            local line = lines[line_index]
            local base_main, between_gap = resolve_justify(
                justify,
                available_main,
                line.main_extent or 0,
                gap,
                #line.entries
            )
            local main_cursor = base_main

            for entry_index = 1, #line.entries do
                local entry = line.entries[entry_index]
                local child = entry.child
                local cross_position = cross_cursor + entry.cross_leading
                local available_line_cross = line.cross_extent or 0

                if not wrap then
                    available_line_cross = available_cross
                end

                if align == 'center' then
                    cross_position = cross_cursor +
                        ((available_line_cross - (entry.outer_cross or 0)) / 2) +
                        entry.cross_leading
                elseif align == 'end' then
                    cross_position = cross_cursor +
                        (available_line_cross - (entry.outer_cross or 0)) +
                        entry.cross_leading
                end

                local main_position = main_cursor + entry.main_leading

                if config.kind == 'Row' and direction == 'rtl' then
                    main_position = available_main -
                        main_cursor -
                        (entry.outer_main or 0) +
                        entry.main_leading
                end

                local offset_x = content_rect.x
                local offset_y = content_rect.y

                if config.main_position_key == 'x' then
                    offset_x = offset_x + main_position
                    offset_y = offset_y + cross_position
                else
                    offset_x = offset_x + cross_position
                    offset_y = offset_y + main_position
                end

                child:_set_layout_offset(offset_x, offset_y)
                child:_refresh_if_dirty()

                main_cursor = main_cursor + (entry.outer_main or 0)

                if entry_index < #line.entries then
                    main_cursor = main_cursor + between_gap
                end
            end

            cross_cursor = cross_cursor + (line.cross_extent or 0)

            if line_index < #lines then
                cross_cursor = cross_cursor + gap
            end
        end

        place_invisible_children(self, invisible_children, content_rect)

        return self
    end, function(err)
        return err
    end)

    self._sequential_layout_measurement_in_progress = false

    if not ok then
        error(result, 0)
    end

    return result
end

return SequentialLayout
