local DemoColors = require('demos.common.colors')
local LayoutDemoDebug = require('demos.common.layout_demo_debug')
local DemoInstruments = require('demos.common.drawable_demo_instruments')
local LayoutSpacingVisuals = require('demos.common.layout_spacing_visuals')
local NativeControls = require('demos.common.native_controls')

local SPACING_OPTIONS = {
    { label = 'None', value = { 0, 0, 0, 0 } },
    { label = 'Top', value = { 40, 0, 0, 0 } },
    { label = 'Right', value = { 0, 40, 0, 0 } },
    { label = 'Bottom', value = { 0, 0, 40, 0 } },
    { label = 'Left', value = { 0, 0, 0, 40 } },
    { label = 'All', value = { 40, 40, 40, 40 } },
}

local PRESET_OPTIONS = {
    {
        label = 'Custom',
        description = 'Manual exploration. Any control change leaves the curated presets and keeps the current state as-is.',
    },
    {
        label = 'Drawable Padding',
        description = 'Plain Drawable parent. Child padding changes the box that owns it, while child margin remains inert for placement.',
        config = {
            type_index = 1,
            child_padding_index = 6,
            child_margin_index = 1,
            child_width_index = 1,
            child_height_index = 1,
            parent_padding_index = 1,
            parent_margin_index = 1,
            parent_width_index = 1,
            parent_height_index = 1,
            parent_justify_index = 2,
            parent_align_index = 2,
        },
    },
    {
        label = 'Stack Margin',
        description = 'Stack consumes child margin as an inset against one shared box. The parent stays fixed while the child placement region shrinks.',
        config = {
            type_index = 2,
            child_padding_index = 1,
            child_margin_index = 6,
            child_width_index = 1,
            child_height_index = 1,
            parent_padding_index = 1,
            parent_margin_index = 1,
            parent_width_index = 1,
            parent_height_index = 1,
            parent_justify_index = 2,
            parent_align_index = 2,
        },
    },
    {
        label = 'Row Offset',
        description = 'Row consumes child margin in the horizontal sequence. Main-axis justify and cross-axis align stay available on the parent.',
        config = {
            type_index = 3,
            child_padding_index = 1,
            child_margin_index = 5,
            child_width_index = 1,
            child_height_index = 1,
            parent_padding_index = 1,
            parent_margin_index = 1,
            parent_width_index = 1,
            parent_height_index = 1,
            parent_justify_index = 2,
            parent_align_index = 2,
        },
    },
    {
        label = 'Column Offset',
        description = 'Column consumes child margin in the vertical sequence. Parent justify moves along the main axis while align controls the cross axis.',
        config = {
            type_index = 4,
            child_padding_index = 1,
            child_margin_index = 2,
            child_width_index = 1,
            child_height_index = 1,
            parent_padding_index = 1,
            parent_margin_index = 1,
            parent_width_index = 1,
            parent_height_index = 1,
            parent_justify_index = 2,
            parent_align_index = 2,
        },
    },
    {
        label = 'Flow Reading',
        description = 'Flow follows reading-order layout rules. It consumes child margin and supports justify and align, but child fill is not available.',
        config = {
            type_index = 5,
            child_padding_index = 1,
            child_margin_index = 6,
            child_width_index = 2,
            child_height_index = 1,
            parent_padding_index = 1,
            parent_margin_index = 1,
            parent_width_index = 1,
            parent_height_index = 1,
            parent_justify_index = 2,
            parent_align_index = 2,
        },
    },
}

local JUSTIFY_OPTIONS = {
    { label = 'Start', value = 'start' },
    { label = 'Center', value = 'center' },
    { label = 'End', value = 'end' },
    { label = 'Between', value = 'space-between' },
    { label = 'Around', value = 'space-around' },
}

local ALIGN_OPTIONS = {
    { label = 'Start', value = 'start' },
    { label = 'Center', value = 'center' },
    { label = 'End', value = 'end' },
    { label = 'Stretch', value = 'stretch' },
}

local FIXED_SIZE_OPTION = { label = 'Fixed', value = 144 }
local LARGE_PERCENT_SIZE_OPTION = { label = '80%', value = '80%' }
local PERCENT_SIZE_OPTION = { label = '60%', value = '60%' }
local CONTENT_SIZE_OPTION = { label = 'Content', value = 'content' }

local FILL_SIZE_OPTIONS = {
    { label = 'Fill', value = 'fill' },
}

local PARENT_FIXED_SIZE_OPTION = { label = 'Fixed', value = 300 }
local PARENT_LARGE_PERCENT_SIZE_OPTION = { label = '80%', value = '80%' }
local PARENT_PERCENT_SIZE_OPTION = { label = '60%', value = '60%' }
local PARENT_CONTENT_SIZE_OPTION = { label = 'Content', value = 'content' }

local TYPE_OPTIONS = {
    {
        label = 'Drawable',
        parent_id = 'spacing-parent-drawable',
        child_id = 'spacing-child-drawable',
        parent_label = 'Drawable Parent',
        child_label = 'Drawable Child',
        child_margin_contract = 'margin is inert under plain Drawable',
        child_margin_enabled = true,
        parent_margin_enabled = true,
        child_fill_enabled = false,
        child_percent_enabled = true,
        parent_fill_enabled = false,
        parent_justify_enabled = false,
        parent_align_enabled = false,
        use_bounds_overlay = false,
    },
    {
        label = 'Stack',
        parent_id = 'spacing-parent-stack',
        child_id = 'spacing-child-stack',
        parent_label = 'Stack Parent',
        child_label = 'Stack Child',
        child_margin_contract = 'margin insets the child placement region inside the same parent box',
        child_margin_enabled = true,
        parent_margin_enabled = false,
        child_fill_enabled = true,
        child_percent_enabled = true,
        parent_fill_enabled = false,
        parent_justify_enabled = false,
        parent_align_enabled = false,
        use_bounds_overlay = true,
    },
    {
        label = 'Row',
        parent_id = 'spacing-parent-row',
        child_id = 'spacing-child-row',
        parent_label = 'Row Parent',
        child_label = 'Row Child',
        child_margin_contract = 'margin contributes to sequential horizontal placement',
        child_margin_enabled = true,
        parent_margin_enabled = false,
        child_fill_enabled = true,
        child_percent_enabled = false,
        parent_fill_enabled = false,
        parent_justify_enabled = true,
        parent_align_enabled = true,
        use_bounds_overlay = true,
    },
    {
        label = 'Column',
        parent_id = 'spacing-parent-column',
        child_id = 'spacing-child-column',
        parent_label = 'Column Parent',
        child_label = 'Column Child',
        child_margin_contract = 'margin contributes to sequential vertical placement',
        child_margin_enabled = true,
        parent_margin_enabled = false,
        child_fill_enabled = true,
        child_percent_enabled = false,
        parent_fill_enabled = false,
        parent_justify_enabled = true,
        parent_align_enabled = true,
        use_bounds_overlay = true,
    },
    {
        label = 'Flow',
        parent_id = 'spacing-parent-flow',
        child_id = 'spacing-child-flow',
        parent_label = 'Flow Parent',
        child_label = 'Flow Child',
        child_margin_contract = 'margin contributes to wrapped row footprints and row placement',
        child_margin_enabled = true,
        parent_margin_enabled = false,
        child_fill_enabled = false,
        child_percent_enabled = false,
        parent_fill_enabled = false,
        parent_justify_enabled = true,
        parent_align_enabled = true,
        use_bounds_overlay = true,
    },
}

local Setup = {}

local function copy_spacing(value)
    return {
        value[1],
        value[2],
        value[3],
        value[4],
    }
end

local function cycle_index(index, delta, total)
    local next_index = index + delta

    if next_index < 1 then
        return total
    end

    if next_index > total then
        return 1
    end

    return next_index
end

local function find_required(root, id)
    local node = root:findById(id, -1)
    if node == nil then
        error('spacing_setup: missing node "' .. id .. '"', 2)
    end
    return node
end

local function has_insets(insets)
    return insets ~= nil and
        (insets.top ~= 0 or insets.right ~= 0 or insets.bottom ~= 0 or insets.left ~= 0)
end

local function append_inset_row(entries, helpers, label, insets)
    if not has_insets(insets) then
        return
    end

    entries[#entries + 1] = {
        label = label,
        badges = {
            helpers.badge('left', helpers.format_scalar(insets.left)),
            helpers.badge('top', helpers.format_scalar(insets.top)),
            helpers.badge('right', helpers.format_scalar(insets.right)),
            helpers.badge('bottom', helpers.format_scalar(insets.bottom)),
        },
    }
end

local function append_rect_row(entries, helpers, label, rect)
    entries[#entries + 1] = {
        label = label,
        badges = {
            helpers.badge('x', helpers.format_scalar(rect.x)),
            helpers.badge('y', helpers.format_scalar(rect.y)),
            helpers.badge('width', helpers.format_scalar(rect.width)),
            helpers.badge('height', helpers.format_scalar(rect.height)),
        },
    }
end

local function get_effective_content_rect(node)
    if type(node.getContentRect) == 'function' then
        return node:getContentRect()
    end

    return node:_get_effective_content_rect()
end

local function build_navigator_layout(left_x, top_y, body_width, font)
    local nav_height = font:getHeight() + 12
    local arrow_width = 24

    return {
        left = {
            x = left_x,
            y = top_y,
            width = arrow_width,
            height = nav_height,
        },
        body = {
            x = left_x + arrow_width + 6,
            y = top_y,
            width = body_width,
            height = nav_height,
        },
        right = {
            x = left_x + arrow_width + 6 + body_width + 6,
            y = top_y,
            width = arrow_width,
            height = nav_height,
        },
    }
end

local function navigator_width(layout)
    return layout.right.x + layout.right.width - layout.left.x
end

local function max_option_body_width(font, option_lists)
    local width = 0

    for list_index = 1, #option_lists do
        local option_list = option_lists[list_index]

        for option_index = 1, #option_list do
            width = math.max(width, font:getWidth(option_list[option_index].label))
        end
    end

    return width + 28
end

local function draw_centered_label(graphics, font, layout, text, y)
    graphics.print(
        text,
        layout.left.x + math.floor((navigator_width(layout) - font:getWidth(text)) / 2),
        y
    )
end

local function set_disabled_label_color(graphics, color, disabled)
    if disabled then
        graphics.setColor(NativeControls.set_alpha(color, 0.45))
        return
    end

    graphics.setColor(color)
end

local function active_option(type_index)
    return TYPE_OPTIONS[type_index]
end

local function active_child_width_options(type_index, parent_width_value)
    local option = active_option(type_index)
    local options = { FIXED_SIZE_OPTION }

    if option.child_percent_enabled or parent_width_value ~= 'content' then
        options[#options + 1] = LARGE_PERCENT_SIZE_OPTION
        options[#options + 1] = PERCENT_SIZE_OPTION
    end

    options[#options + 1] = CONTENT_SIZE_OPTION

    if option.child_fill_enabled and parent_width_value ~= 'content' then
        options[#options + 1] = FILL_SIZE_OPTIONS[1]
    end

    return options
end

local function active_child_height_options(type_index, parent_height_value)
    local option = active_option(type_index)
    local options = { FIXED_SIZE_OPTION }

    if option.child_percent_enabled or parent_height_value ~= 'content' then
        options[#options + 1] = LARGE_PERCENT_SIZE_OPTION
        options[#options + 1] = PERCENT_SIZE_OPTION
    end

    options[#options + 1] = CONTENT_SIZE_OPTION

    if option.child_fill_enabled and parent_height_value ~= 'content' then
        options[#options + 1] = FILL_SIZE_OPTIONS[1]
    end

    return options
end

local function active_parent_width_options(type_index)
    local option = active_option(type_index)
    local options = {
        PARENT_FIXED_SIZE_OPTION,
        PARENT_LARGE_PERCENT_SIZE_OPTION,
        PARENT_PERCENT_SIZE_OPTION,
        PARENT_CONTENT_SIZE_OPTION,
    }

    if option.parent_fill_enabled then
        options[#options + 1] = FILL_SIZE_OPTIONS[1]
    end

    return options
end

local function active_parent_height_options(type_index)
    local option = active_option(type_index)
    local options = {
        PARENT_FIXED_SIZE_OPTION,
        PARENT_LARGE_PERCENT_SIZE_OPTION,
        PARENT_PERCENT_SIZE_OPTION,
        PARENT_CONTENT_SIZE_OPTION,
    }

    if option.parent_fill_enabled then
        options[#options + 1] = FILL_SIZE_OPTIONS[1]
    end

    return options
end

local function set_parent_hint(node, helpers, type_label)
    helpers.set_hint(node, function(current)
        local bounds = current:getLocalBounds()
        local content = get_effective_content_rect(current)
        local entries = {
            {
                label = 'type',
                badges = {
                    helpers.badge(nil, type_label),
                },
            },
        }

        append_rect_row(entries, helpers, 'parent.container', bounds)
        append_rect_row(entries, helpers, 'parent.content', content)

        if current.justify ~= nil or current.align ~= nil then
            entries[#entries + 1] = {
                label = 'layout',
                badges = {
                    helpers.badge('justify', current.justify or 'start'),
                    helpers.badge('align', current.align or 'start'),
                },
            }
        end

        append_inset_row(entries, helpers, 'padding', current.padding)
        append_inset_row(entries, helpers, 'margin', current.margin)

        return entries
    end)
end

function Setup.install(args)
    local scope = args.scope
    local helpers = args.helpers
    local root = args.root
    local stage = args.stage
    local title_font = scope:font(12)
    local label_font = scope:font(11)
    local selector_body_width = max_option_body_width(title_font, {
        SPACING_OPTIONS,
        PRESET_OPTIONS,
        TYPE_OPTIONS,
        JUSTIFY_OPTIONS,
        ALIGN_OPTIONS,
        {
            FIXED_SIZE_OPTION,
            LARGE_PERCENT_SIZE_OPTION,
            PERCENT_SIZE_OPTION,
            CONTENT_SIZE_OPTION,
        },
        FILL_SIZE_OPTIONS,
        {
            PARENT_FIXED_SIZE_OPTION,
            PARENT_LARGE_PERCENT_SIZE_OPTION,
            PARENT_PERCENT_SIZE_OPTION,
            PARENT_CONTENT_SIZE_OPTION,
        },
    })
    local child_padding_index = 6
    local child_margin_index = 5
    local child_width_index = 1
    local child_height_index = 1
    local parent_padding_index = 1
    local parent_margin_index = 1
    local parent_width_index = 1
    local parent_height_index = 1
    local parent_justify_index = 2
    local parent_align_index = 2
    local preset_index = 1
    local type_index = 1
    local selector_layouts = nil

    local host = find_required(root, 'spacing-host')
    local drawable_parent = find_required(root, 'spacing-parent-drawable')
    local drawable_child = find_required(root, 'spacing-child-drawable')
    local stack_parent = find_required(root, 'spacing-parent-stack')
    local stack_child = find_required(root, 'spacing-child-stack')
    local row_parent = find_required(root, 'spacing-parent-row')
    local row_child = find_required(root, 'spacing-child-row')
    local column_parent = find_required(root, 'spacing-parent-column')
    local column_child = find_required(root, 'spacing-child-column')
    local flow_parent = find_required(root, 'spacing-parent-flow')
    local flow_child = find_required(root, 'spacing-child-flow')
    local parent_entries = {
        {
            option = TYPE_OPTIONS[1],
            parent = drawable_parent,
            child = drawable_child,
        },
        {
            option = TYPE_OPTIONS[2],
            parent = stack_parent,
            child = stack_child,
        },
        {
            option = TYPE_OPTIONS[3],
            parent = row_parent,
            child = row_child,
        },
        {
            option = TYPE_OPTIONS[4],
            parent = column_parent,
            child = column_child,
        },
        {
            option = TYPE_OPTIONS[5],
            parent = flow_parent,
            child = flow_child,
        },
    }

    for index = 1, #parent_entries do
        local entry = parent_entries[index]
        rawset(entry.parent, '_demo_label', '')
        helpers.set_hint_name(entry.parent, 'parent')
        set_parent_hint(entry.parent, helpers, entry.option.label)

        if entry.option.use_bounds_overlay then
            helpers.show_bounds(entry.parent)
            local overlay = rawget(entry.parent, '_demo_bounds_overlay')
            overlay.borderStyle = 'rough'
            overlay.borderPattern = 'dashed'
            overlay.borderDashLength = 8
            overlay.borderGapLength = 6
        end

        rawset(entry.child, '_demo_label', 'Child')
        rawset(entry.child, '_demo_label_rect', 'content')
        rawset(entry.child, '_demo_label_inset_x', 8)
        rawset(entry.child, '_demo_label_inset_y', 8)
        helpers.set_hint_name(entry.child, 'child')
        DemoInstruments.set_spacing_hint(entry.child, helpers, 'Drawable')
    end

    local function apply_parent_spacing()
        local padding_value = SPACING_OPTIONS[parent_padding_index].value
        local margin_value = SPACING_OPTIONS[parent_margin_index].value

        for index = 1, #parent_entries do
            local entry = parent_entries[index]
            entry.parent.padding = copy_spacing(padding_value)

            if entry.option.parent_margin_enabled then
                entry.parent.margin = copy_spacing(margin_value)
            end
        end
    end

    local function apply_parent_size()
        for index = 1, #parent_entries do
            local entry = parent_entries[index]
            local width_options = active_parent_width_options(index)
            local height_options = active_parent_height_options(index)
            local resolved_width_index = math.min(parent_width_index, #width_options)
            local resolved_height_index = math.min(parent_height_index, #height_options)

            entry.parent.width = width_options[resolved_width_index].value
            entry.parent.height = height_options[resolved_height_index].value
        end
    end

    local function apply_parent_layout_controls()
        local justify_value = JUSTIFY_OPTIONS[parent_justify_index].value
        local align_value = ALIGN_OPTIONS[parent_align_index].value

        for index = 1, #parent_entries do
            local entry = parent_entries[index]

            if entry.option.parent_justify_enabled then
                entry.parent.justify = justify_value
            end

            if entry.option.parent_align_enabled then
                entry.parent.align = align_value
            end
        end
    end

    local function apply_preset(index)
        local preset = PRESET_OPTIONS[index]
        local config = preset and preset.config or nil

        preset_index = index

        if config == nil then
            return
        end

        type_index = config.type_index
        child_padding_index = config.child_padding_index
        child_margin_index = config.child_margin_index
        child_width_index = config.child_width_index
        child_height_index = config.child_height_index
        parent_padding_index = config.parent_padding_index
        parent_margin_index = config.parent_margin_index
        parent_width_index = config.parent_width_index
        parent_height_index = config.parent_height_index
        parent_justify_index = config.parent_justify_index
        parent_align_index = config.parent_align_index
    end

    local function apply_parent_position()
    end

    local function center_parent_boxes()
        local changed = false

        for index = 1, #parent_entries do
            local entry = parent_entries[index]
            local bounds = entry.parent:getLocalBounds()
            local next_x = math.floor((host.width - bounds.width) / 2) - bounds.x
            local next_y = math.floor((host.height - bounds.height) / 2) - bounds.y

            if entry.parent.x ~= next_x then
                entry.parent.x = next_x
                changed = true
            end

            if entry.parent.y ~= next_y then
                entry.parent.y = next_y
                changed = true
            end
        end

        return changed
    end

    local function apply_child_spacing()
        local padding_value = SPACING_OPTIONS[child_padding_index].value
        local margin_value = SPACING_OPTIONS[child_margin_index].value

        for index = 1, #parent_entries do
            local entry = parent_entries[index]
            entry.child.padding = copy_spacing(padding_value)
            entry.child.margin = copy_spacing(margin_value)
        end
    end

    local function apply_child_size()
        for index = 1, #parent_entries do
            local entry = parent_entries[index]
            local parent_width_value = active_parent_width_options(index)[math.min(parent_width_index, #active_parent_width_options(index))].value
            local parent_height_value = active_parent_height_options(index)[math.min(parent_height_index, #active_parent_height_options(index))].value
            local width_options = active_child_width_options(index, parent_width_value)
            local height_options = active_child_height_options(index, parent_height_value)
            local resolved_width_index = math.min(child_width_index, #width_options)
            local resolved_height_index = math.min(child_height_index, #height_options)

            entry.child.width = width_options[resolved_width_index].value
            entry.child.height = height_options[resolved_height_index].value
        end
    end

    local function sync_type_visibility()
        local active_option = TYPE_OPTIONS[type_index]
        local active_parent_width_value = active_parent_width_options(type_index)[math.min(parent_width_index, #active_parent_width_options(type_index))].value
        local active_parent_height_value = active_parent_height_options(type_index)[math.min(parent_height_index, #active_parent_height_options(type_index))].value

        if child_width_index > #active_child_width_options(type_index, active_parent_width_value) then
            child_width_index = #active_child_width_options(type_index, active_parent_width_value)
        end

        if child_height_index > #active_child_height_options(type_index, active_parent_height_value) then
            child_height_index = #active_child_height_options(type_index, active_parent_height_value)
        end

        if parent_width_index > #active_parent_width_options(type_index) then
            parent_width_index = #active_parent_width_options(type_index)
        end

        if parent_height_index > #active_parent_height_options(type_index) then
            parent_height_index = #active_parent_height_options(type_index)
        end

        for index = 1, #parent_entries do
            local entry = parent_entries[index]
            local parent_bounds_overlay = rawget(entry.parent, '_demo_bounds_overlay')
            local active = index == type_index

            entry.parent.visible = active

            if parent_bounds_overlay ~= nil then
                parent_bounds_overlay.visible = active
            end
        end

        helpers.set_hint_name(parent_entries[type_index].parent, 'parent')
    end

    local function mark_custom()
        preset_index = 1
    end

    local function update()
        local viewport = root:getWorldBounds()
        local parent_width_options
        local parent_height_options
        local child_width_options
        local child_height_options
        local preset_layout
        local preset_top
        local description_top
        local description_height
        local content_top

        apply_parent_spacing()
        apply_parent_size()
        apply_parent_layout_controls()
        apply_child_spacing()
        apply_child_size()
        sync_type_visibility()

        parent_width_options = active_parent_width_options(type_index)
        parent_height_options = active_parent_height_options(type_index)
        child_width_options = active_child_width_options(type_index, parent_width_options[parent_width_index].value)
        child_height_options = active_child_height_options(type_index, parent_height_options[parent_height_index].value)

        local child_specs = {
            { key = 'child_padding', text = SPACING_OPTIONS[child_padding_index].label },
            { key = 'child_margin', text = SPACING_OPTIONS[child_margin_index].label },
            { key = 'child_width', text = child_width_options[child_width_index].label },
            { key = 'child_height', text = child_height_options[child_height_index].label },
        }
        local parent_specs = {
            { key = 'parent_type', text = TYPE_OPTIONS[type_index].label },
            { key = 'parent_padding', text = SPACING_OPTIONS[parent_padding_index].label },
            { key = 'parent_margin', text = SPACING_OPTIONS[parent_margin_index].label },
            { key = 'parent_width', text = parent_width_options[parent_width_index].label },
            { key = 'parent_height', text = parent_height_options[parent_height_index].label },
            { key = 'parent_justify', text = JUSTIFY_OPTIONS[parent_justify_index].label },
            { key = 'parent_align', text = ALIGN_OPTIONS[parent_align_index].label },
        }
        local row_gap = 32
        local side_gap = 36
        local child_temp = {}
        local parent_temp = {}
        local child_max_width = 0
        local parent_max_width = 0

        for index = 1, #child_specs do
            child_temp[index] = build_navigator_layout(0, 0, selector_body_width, title_font)
            child_max_width = math.max(child_max_width, navigator_width(child_temp[index]))
        end

        for index = 1, #parent_specs do
            parent_temp[index] = build_navigator_layout(0, 0, selector_body_width, title_font)
            parent_max_width = math.max(parent_max_width, navigator_width(parent_temp[index]))
        end

        local child_row_height = child_temp[1].body.height
        local parent_row_height = parent_temp[1].body.height
        local child_group_height = (child_row_height * #child_specs) + (row_gap * (#child_specs - 1))
        local parent_group_height = (parent_row_height * #parent_specs) + (row_gap * (#parent_specs - 1))
        local side_column_width = math.max(child_max_width, parent_max_width)
        local composition_width = side_column_width + side_gap + host.width + side_gap + side_column_width
        local composition_left_x = viewport.x + math.floor((viewport.width - composition_width) / 2)
        local child_left_x = composition_left_x + (side_column_width - child_max_width)
        local parent_left_x = composition_left_x + side_column_width + side_gap + host.width + side_gap
        host.x = composition_left_x + side_column_width + side_gap

        preset_layout = build_navigator_layout(0, 0, selector_body_width, title_font)
        preset_top = viewport.y + math.floor(viewport.height * 0.15)
        description_top = preset_top + preset_layout.body.height + 28
        description_height = (label_font:getHeight() * 4) + 18
        content_top = description_top + description_height + 28
        host.y = content_top

        local child_start_y = host.y + math.floor((host.height - child_group_height) / 2)
        local parent_start_y = host.y + math.floor((host.height - parent_group_height) / 2)

        selector_layouts = {}

        local preset_width = navigator_width(preset_layout)
        selector_layouts.preset = build_navigator_layout(
            host.x + math.floor((host.width - preset_width) / 2),
            preset_top,
            selector_body_width,
            title_font
        )
        selector_layouts.description = {
            x = viewport.x + math.floor((viewport.width - math.floor(viewport.width * 0.7)) / 2),
            y = description_top,
            width = math.floor(viewport.width * 0.7),
            height = description_height,
        }

        for index = 1, #child_specs do
            selector_layouts[child_specs[index].key] = build_navigator_layout(
                child_left_x,
                child_start_y + ((index - 1) * (child_row_height + row_gap)),
                selector_body_width,
                title_font
            )
        end

        for index = 1, #parent_specs do
            selector_layouts[parent_specs[index].key] = build_navigator_layout(
                parent_left_x,
                parent_start_y + ((index - 1) * (parent_row_height + row_gap)),
                selector_body_width,
                title_font
            )
        end
    end

    local function emit_state_dump()
        local option = active_option(type_index)
        local parent_width_options = active_parent_width_options(type_index)
        local parent_height_options = active_parent_height_options(type_index)
        local resolved_parent_width_index = math.min(parent_width_index, #parent_width_options)
        local resolved_parent_height_index = math.min(parent_height_index, #parent_height_options)
        local child_width_options = active_child_width_options(
            type_index,
            parent_width_options[resolved_parent_width_index].value
        )
        local child_height_options = active_child_height_options(
            type_index,
            parent_height_options[resolved_parent_height_index].value
        )
        local resolved_child_width_index = math.min(child_width_index, #child_width_options)
        local resolved_child_height_index = math.min(child_height_index, #child_height_options)
        local parent_margin_label = SPACING_OPTIONS[parent_margin_index].label
        local parent_justify_label = JUSTIFY_OPTIONS[parent_justify_index].label
        local parent_align_label = ALIGN_OPTIONS[parent_align_index].label

        if not option.parent_margin_enabled then
            parent_margin_label = parent_margin_label .. ' [disabled]'
        end

        if not option.parent_justify_enabled then
            parent_justify_label = parent_justify_label .. ' [disabled]'
        end

        if not option.parent_align_enabled then
            parent_align_label = parent_align_label .. ' [disabled]'
        end

        LayoutDemoDebug.dump('spacing', {
            LayoutDemoDebug.entry('preset', PRESET_OPTIONS[preset_index].label),
            LayoutDemoDebug.group('child', {
                LayoutDemoDebug.entry('padding', SPACING_OPTIONS[child_padding_index].label),
                LayoutDemoDebug.entry('margin', SPACING_OPTIONS[child_margin_index].label),
                LayoutDemoDebug.entry('width', child_width_options[resolved_child_width_index].label),
                LayoutDemoDebug.entry('height', child_height_options[resolved_child_height_index].label),
            }),
            LayoutDemoDebug.group('parent', {
                LayoutDemoDebug.entry('type', option.label),
                LayoutDemoDebug.entry('padding', SPACING_OPTIONS[parent_padding_index].label),
                LayoutDemoDebug.entry('margin', parent_margin_label),
                LayoutDemoDebug.entry('width', parent_width_options[resolved_parent_width_index].label),
                LayoutDemoDebug.entry('height', parent_height_options[resolved_parent_height_index].label),
                LayoutDemoDebug.entry('justify', parent_justify_label),
                LayoutDemoDebug.entry('align', parent_align_label),
            }),
        })
    end

    local function consume_click()
        emit_state_dump()
        return true
    end

    local function consume_manual_click()
        mark_custom()
        emit_state_dump()
        return true
    end

    local function mousepressed(x, y, button)
        local option = active_option(type_index)

        if button ~= 1 or selector_layouts == nil then
            return false
        end

        if NativeControls.point_in_rect(selector_layouts.preset.left, x, y) then
            apply_preset(cycle_index(preset_index, -1, #PRESET_OPTIONS))
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.preset.right, x, y) then
            apply_preset(cycle_index(preset_index, 1, #PRESET_OPTIONS))
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.child_padding.left, x, y) then
            child_padding_index = cycle_index(child_padding_index, -1, #SPACING_OPTIONS)
            return consume_manual_click()
        end

        if NativeControls.point_in_rect(selector_layouts.child_padding.right, x, y) then
            child_padding_index = cycle_index(child_padding_index, 1, #SPACING_OPTIONS)
            return consume_manual_click()
        end

        if NativeControls.point_in_rect(selector_layouts.child_margin.left, x, y) then
            if not option.child_margin_enabled then
                return consume_click()
            end
            child_margin_index = cycle_index(child_margin_index, -1, #SPACING_OPTIONS)
            return consume_manual_click()
        end

        if NativeControls.point_in_rect(selector_layouts.child_margin.right, x, y) then
            if not option.child_margin_enabled then
                return consume_click()
            end
            child_margin_index = cycle_index(child_margin_index, 1, #SPACING_OPTIONS)
            return consume_manual_click()
        end

        if NativeControls.point_in_rect(selector_layouts.child_width.left, x, y) then
            child_width_index = cycle_index(
                child_width_index,
                -1,
                #active_child_width_options(type_index, active_parent_width_options(type_index)[parent_width_index].value)
            )
            return consume_manual_click()
        end

        if NativeControls.point_in_rect(selector_layouts.child_width.right, x, y) then
            child_width_index = cycle_index(
                child_width_index,
                1,
                #active_child_width_options(type_index, active_parent_width_options(type_index)[parent_width_index].value)
            )
            return consume_manual_click()
        end

        if NativeControls.point_in_rect(selector_layouts.child_height.left, x, y) then
            child_height_index = cycle_index(
                child_height_index,
                -1,
                #active_child_height_options(type_index, active_parent_height_options(type_index)[parent_height_index].value)
            )
            return consume_manual_click()
        end

        if NativeControls.point_in_rect(selector_layouts.child_height.right, x, y) then
            child_height_index = cycle_index(
                child_height_index,
                1,
                #active_child_height_options(type_index, active_parent_height_options(type_index)[parent_height_index].value)
            )
            return consume_manual_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_padding.left, x, y) then
            parent_padding_index = cycle_index(parent_padding_index, -1, #SPACING_OPTIONS)
            return consume_manual_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_padding.right, x, y) then
            parent_padding_index = cycle_index(parent_padding_index, 1, #SPACING_OPTIONS)
            return consume_manual_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_margin.left, x, y) then
            if not option.parent_margin_enabled then
                return consume_click()
            end
            parent_margin_index = cycle_index(parent_margin_index, -1, #SPACING_OPTIONS)
            return consume_manual_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_margin.right, x, y) then
            if not option.parent_margin_enabled then
                return consume_click()
            end
            parent_margin_index = cycle_index(parent_margin_index, 1, #SPACING_OPTIONS)
            return consume_manual_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_width.left, x, y) then
            parent_width_index = cycle_index(parent_width_index, -1, #active_parent_width_options(type_index))
            return consume_manual_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_width.right, x, y) then
            parent_width_index = cycle_index(parent_width_index, 1, #active_parent_width_options(type_index))
            return consume_manual_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_height.left, x, y) then
            parent_height_index = cycle_index(parent_height_index, -1, #active_parent_height_options(type_index))
            return consume_manual_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_height.right, x, y) then
            parent_height_index = cycle_index(parent_height_index, 1, #active_parent_height_options(type_index))
            return consume_manual_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_justify.left, x, y) then
            if not option.parent_justify_enabled then
                return consume_click()
            end
            parent_justify_index = cycle_index(parent_justify_index, -1, #JUSTIFY_OPTIONS)
            return consume_manual_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_justify.right, x, y) then
            if not option.parent_justify_enabled then
                return consume_click()
            end
            parent_justify_index = cycle_index(parent_justify_index, 1, #JUSTIFY_OPTIONS)
            return consume_manual_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_align.left, x, y) then
            if not option.parent_align_enabled then
                return consume_click()
            end
            parent_align_index = cycle_index(parent_align_index, -1, #ALIGN_OPTIONS)
            return consume_manual_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_align.right, x, y) then
            if not option.parent_align_enabled then
                return consume_click()
            end
            parent_align_index = cycle_index(parent_align_index, 1, #ALIGN_OPTIONS)
            return consume_manual_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_type.left, x, y) then
            type_index = cycle_index(type_index, -1, #TYPE_OPTIONS)
            return consume_manual_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_type.right, x, y) then
            type_index = cycle_index(type_index, 1, #TYPE_OPTIONS)
            return consume_manual_click()
        end

        return false
    end

    local function draw_spacing_patterns(graphics)
        if selector_layouts == nil then
            return
        end

        local entry = parent_entries[type_index]
        LayoutSpacingVisuals.draw_margin_overlay(graphics, entry.parent)
        LayoutSpacingVisuals.draw_padding_overlay(graphics, entry.parent)
        LayoutSpacingVisuals.draw_margin_overlay(graphics, entry.child)
        LayoutSpacingVisuals.draw_padding_overlay(graphics, entry.child)
    end

    local function draw_overlay(graphics)
        if selector_layouts == nil then
            return
        end

        local mouse_x, mouse_y = love.mouse.getPosition()
        local active_label = TYPE_OPTIONS[type_index].label
        local active_preset = PRESET_OPTIONS[preset_index]
        local option = active_option(type_index)
        local parent_width_options = active_parent_width_options(type_index)
        local parent_height_options = active_parent_height_options(type_index)
        local child_width_options = active_child_width_options(type_index, parent_width_options[parent_width_index].value)
        local child_height_options = active_child_height_options(type_index, parent_height_options[parent_height_index].value)
        local child_margin_disabled = not option.child_margin_enabled
        local parent_margin_disabled = not option.parent_margin_enabled
        local parent_justify_disabled = not option.parent_justify_enabled
        local parent_align_disabled = not option.parent_align_enabled
        local field_gap = 4
        local child_panel = NativeControls.build_group_panel({
            selector_layouts.child_padding,
            selector_layouts.child_margin,
            selector_layouts.child_width,
            selector_layouts.child_height,
        }, title_font, label_font)
        local parent_panel = NativeControls.build_group_panel({
            selector_layouts.parent_type,
            selector_layouts.parent_padding,
            selector_layouts.parent_margin,
            selector_layouts.parent_width,
            selector_layouts.parent_height,
            selector_layouts.parent_justify,
            selector_layouts.parent_align,
        }, title_font, label_font)

        draw_spacing_patterns(graphics)

        graphics.setFont(label_font)
        graphics.setColor(DemoColors.roles.text)
        draw_centered_label(
            graphics,
            label_font,
            selector_layouts.preset,
            'Preset',
            selector_layouts.preset.body.y - label_font:getHeight() - field_gap
        )
        graphics.setColor(DemoColors.roles.text_muted)
        graphics.printf(
            active_preset.description,
            selector_layouts.description.x,
            selector_layouts.description.y,
            selector_layouts.description.width,
            'center'
        )

        NativeControls.draw_group_panel(graphics, title_font, child_panel, 'Child')
        NativeControls.draw_group_panel(graphics, title_font, parent_panel, 'Parent')

        graphics.setFont(label_font)
        graphics.setColor(DemoColors.roles.accent_amber_line)
        draw_centered_label(
            graphics,
            label_font,
            selector_layouts.child_padding,
            'Padding',
            selector_layouts.child_padding.body.y - label_font:getHeight() - field_gap
        )
        set_disabled_label_color(
            graphics,
            child_margin_disabled and DemoColors.roles.text_muted or DemoColors.roles.accent_violet_line,
            child_margin_disabled
        )
        draw_centered_label(
            graphics,
            label_font,
            selector_layouts.child_margin,
            'Margin',
            selector_layouts.child_margin.body.y - label_font:getHeight() - field_gap
        )
        graphics.setColor(DemoColors.roles.text)
        draw_centered_label(
            graphics,
            label_font,
            selector_layouts.child_width,
            'Width',
            selector_layouts.child_width.body.y - label_font:getHeight() - field_gap
        )
        draw_centered_label(
            graphics,
            label_font,
            selector_layouts.child_height,
            'Height',
            selector_layouts.child_height.body.y - label_font:getHeight() - field_gap
        )

        graphics.setFont(label_font)
        graphics.setColor(DemoColors.roles.text)
        draw_centered_label(
            graphics,
            label_font,
            selector_layouts.parent_type,
            'Type',
            selector_layouts.parent_type.body.y - label_font:getHeight() - field_gap
        )
        graphics.setColor(DemoColors.roles.accent_amber_line)
        draw_centered_label(
            graphics,
            label_font,
            selector_layouts.parent_padding,
            'Padding',
            selector_layouts.parent_padding.body.y - label_font:getHeight() - field_gap
        )
        set_disabled_label_color(
            graphics,
            parent_margin_disabled and DemoColors.roles.text_muted or DemoColors.roles.accent_violet_line,
            parent_margin_disabled
        )
        draw_centered_label(
            graphics,
            label_font,
            selector_layouts.parent_margin,
            'Margin',
            selector_layouts.parent_margin.body.y - label_font:getHeight() - field_gap
        )
        graphics.setColor(DemoColors.roles.text)
        draw_centered_label(
            graphics,
            label_font,
            selector_layouts.parent_width,
            'Width',
            selector_layouts.parent_width.body.y - label_font:getHeight() - field_gap
        )
        draw_centered_label(
            graphics,
            label_font,
            selector_layouts.parent_height,
            'Height',
            selector_layouts.parent_height.body.y - label_font:getHeight() - field_gap
        )
        set_disabled_label_color(
            graphics,
            parent_justify_disabled and DemoColors.roles.text_muted or DemoColors.roles.text,
            parent_justify_disabled
        )
        draw_centered_label(
            graphics,
            label_font,
            selector_layouts.parent_justify,
            'Justify',
            selector_layouts.parent_justify.body.y - label_font:getHeight() - field_gap
        )
        set_disabled_label_color(
            graphics,
            parent_align_disabled and DemoColors.roles.text_muted or DemoColors.roles.text,
            parent_align_disabled
        )
        draw_centered_label(
            graphics,
            label_font,
            selector_layouts.parent_align,
            'Align',
            selector_layouts.parent_align.body.y - label_font:getHeight() - field_gap
        )

        NativeControls.draw_navigator(
            graphics,
            title_font,
            selector_layouts.preset,
            active_preset.label,
            NativeControls.point_in_rect(selector_layouts.preset.left, mouse_x, mouse_y),
            NativeControls.point_in_rect(selector_layouts.preset.right, mouse_x, mouse_y),
            DemoColors.roles.border_light
        )
        NativeControls.draw_navigator(
            graphics,
            title_font,
            selector_layouts.child_padding,
            SPACING_OPTIONS[child_padding_index].label,
            NativeControls.point_in_rect(selector_layouts.child_padding.left, mouse_x, mouse_y),
            NativeControls.point_in_rect(selector_layouts.child_padding.right, mouse_x, mouse_y)
        )
        NativeControls.draw_navigator(
            graphics,
            title_font,
            selector_layouts.child_margin,
            SPACING_OPTIONS[child_margin_index].label,
            NativeControls.point_in_rect(selector_layouts.child_margin.left, mouse_x, mouse_y),
            NativeControls.point_in_rect(selector_layouts.child_margin.right, mouse_x, mouse_y),
            nil,
            child_margin_disabled
        )
        NativeControls.draw_navigator(
            graphics,
            title_font,
            selector_layouts.child_width,
            child_width_options[child_width_index].label,
            NativeControls.point_in_rect(selector_layouts.child_width.left, mouse_x, mouse_y),
            NativeControls.point_in_rect(selector_layouts.child_width.right, mouse_x, mouse_y)
        )
        NativeControls.draw_navigator(
            graphics,
            title_font,
            selector_layouts.child_height,
            child_height_options[child_height_index].label,
            NativeControls.point_in_rect(selector_layouts.child_height.left, mouse_x, mouse_y),
            NativeControls.point_in_rect(selector_layouts.child_height.right, mouse_x, mouse_y)
        )
        NativeControls.draw_navigator(
            graphics,
            title_font,
            selector_layouts.parent_type,
            active_label,
            NativeControls.point_in_rect(selector_layouts.parent_type.left, mouse_x, mouse_y),
            NativeControls.point_in_rect(selector_layouts.parent_type.right, mouse_x, mouse_y),
            DemoColors.roles.border_light
        )
        NativeControls.draw_navigator(
            graphics,
            title_font,
            selector_layouts.parent_padding,
            SPACING_OPTIONS[parent_padding_index].label,
            NativeControls.point_in_rect(selector_layouts.parent_padding.left, mouse_x, mouse_y),
            NativeControls.point_in_rect(selector_layouts.parent_padding.right, mouse_x, mouse_y)
        )
        NativeControls.draw_navigator(
            graphics,
            title_font,
            selector_layouts.parent_margin,
            SPACING_OPTIONS[parent_margin_index].label,
            NativeControls.point_in_rect(selector_layouts.parent_margin.left, mouse_x, mouse_y),
            NativeControls.point_in_rect(selector_layouts.parent_margin.right, mouse_x, mouse_y),
            nil,
            parent_margin_disabled
        )
        NativeControls.draw_navigator(
            graphics,
            title_font,
            selector_layouts.parent_width,
            parent_width_options[parent_width_index].label,
            NativeControls.point_in_rect(selector_layouts.parent_width.left, mouse_x, mouse_y),
            NativeControls.point_in_rect(selector_layouts.parent_width.right, mouse_x, mouse_y)
        )
        NativeControls.draw_navigator(
            graphics,
            title_font,
            selector_layouts.parent_height,
            parent_height_options[parent_height_index].label,
            NativeControls.point_in_rect(selector_layouts.parent_height.left, mouse_x, mouse_y),
            NativeControls.point_in_rect(selector_layouts.parent_height.right, mouse_x, mouse_y)
        )
        NativeControls.draw_navigator(
            graphics,
            title_font,
            selector_layouts.parent_justify,
            JUSTIFY_OPTIONS[parent_justify_index].label,
            NativeControls.point_in_rect(selector_layouts.parent_justify.left, mouse_x, mouse_y),
            NativeControls.point_in_rect(selector_layouts.parent_justify.right, mouse_x, mouse_y),
            nil,
            parent_justify_disabled
        )
        NativeControls.draw_navigator(
            graphics,
            title_font,
            selector_layouts.parent_align,
            ALIGN_OPTIONS[parent_align_index].label,
            NativeControls.point_in_rect(selector_layouts.parent_align.left, mouse_x, mouse_y),
            NativeControls.point_in_rect(selector_layouts.parent_align.right, mouse_x, mouse_y),
            nil,
            parent_align_disabled
        )
        graphics.setColor(DemoColors.roles.text)
        graphics.setFont(title_font)
        do
            local active_parent_bounds = parent_entries[type_index].parent:getWorldBounds()
            graphics.print(
                'Parent',
                active_parent_bounds.x,
                active_parent_bounds.y - title_font:getHeight() - 8
            )
        end
    end

    rawset(stage, '_demo_screen_hooks', {
        update = update,
        after_update = function()
            return center_parent_boxes()
        end,
        mousepressed = mousepressed,
        draw_overlay = draw_overlay,
    })
end

return Setup
