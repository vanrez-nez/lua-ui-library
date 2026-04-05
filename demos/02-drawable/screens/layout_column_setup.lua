local DemoColors = require('demos.common.colors')
local LayoutDemoDebug = require('demos.common.layout_demo_debug')
local LayoutSpacingVisuals = require('demos.common.layout_spacing_visuals')
local NativeControls = require('demos.common.native_controls')

local Setup = {}

local ELEMENT_OPTIONS = {
    { label = 'Header' },
    { label = 'Body' },
    { label = 'Footer' },
}

local SPACING_OPTIONS = {
    { label = 'None', value = { 0, 0, 0, 0 } },
    { label = 'Top', value = { 10, 0, 0, 0 } },
    { label = 'Right', value = { 0, 10, 0, 0 } },
    { label = 'Bottom', value = { 0, 0, 10, 0 } },
    { label = 'Left', value = { 0, 0, 0, 10 } },
    { label = 'Horizontal', value = { 0, 10, 0, 10 } },
    { label = 'Vertical', value = { 10, 0, 10, 0 } },
    { label = 'All', value = { 10, 10, 10, 10 } },
    { label = 'Wide', value = { 10, 15, 10, 15 } },
    { label = 'Roomy', value = { 15, 15, 15, 15 } },
}

local GAP_OPTIONS = {
    { label = '0', value = 0 },
    { label = '15', value = 15 },
    { label = '30', value = 30 },
    { label = '45', value = 45 },
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

local PARENT_SIZE_OPTIONS = {
    { label = 'Fixed', value = 'fixed' },
    { label = '80%', value = '80%' },
    { label = 'Content', value = 'content' },
}

local CHILD_SIZE_OPTIONS = {
    { label = 'Fixed', value = 'fixed' },
    { label = '80%', value = '80%' },
    { label = 'Fill', value = 'fill' },
}

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

local function find_required(root, id)
    local node = root:findById(id, -1)
    if node == nil then
        error('layout_column_setup: missing node "' .. id .. '"', 2)
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

local function set_parent_hint(node, helpers)
    helpers.set_hint(node, function(current)
        local entries = {
            {
                label = 'type',
                badges = {
                    helpers.badge(nil, 'Column'),
                },
            },
        }

        append_rect_row(entries, helpers, 'parent.container', current:getLocalBounds())
        append_rect_row(entries, helpers, 'parent.content', current:_get_effective_content_rect())
        entries[#entries + 1] = {
            label = 'layout',
            badges = {
                helpers.badge('justify', current.justify or 'start'),
                helpers.badge('align', current.align or 'start'),
                helpers.badge('gap', helpers.format_scalar(current.gap or 0)),
            },
        }
        append_inset_row(entries, helpers, 'padding', current.padding)

        return entries
    end)
end

local function set_child_hint(node, helpers)
    helpers.set_hint(node, function(current)
        local entries = {
            {
                label = 'type',
                badges = {
                    helpers.badge(nil, 'Drawable'),
                },
            },
            {
                label = 'position',
                badges = {
                    helpers.badge('x', helpers.format_scalar(current.x or 0)),
                    helpers.badge('y', helpers.format_scalar(current.y or 0)),
                    helpers.badge('zIndex', helpers.format_scalar(current.zIndex or 0)),
                },
            },
        }

        append_rect_row(entries, helpers, 'child.container', current:getLocalBounds())
        append_rect_row(entries, helpers, 'child.content', current:getContentRect())
        append_inset_row(entries, helpers, 'padding', current.padding)
        append_inset_row(entries, helpers, 'margin', current.margin)

        return entries
    end)
end

function Setup.install(args)
    local helpers = args.helpers
    local root = args.root
    local scope = args.scope
    local stage = args.stage
    local title_font = scope:font(12)
    local label_font = scope:font(11)
    local parent = find_required(root, 'layout-column-parent')
    local header = find_required(root, 'layout-column-header')
    local body = find_required(root, 'layout-column-body')
    local footer = find_required(root, 'layout-column-footer')
    local parent_fixed_width = parent.width
    local parent_fixed_height = parent.height
    local selector_body_width = max_option_body_width(title_font, {
        ELEMENT_OPTIONS,
        SPACING_OPTIONS,
        GAP_OPTIONS,
        JUSTIFY_OPTIONS,
        ALIGN_OPTIONS,
        PARENT_SIZE_OPTIONS,
        CHILD_SIZE_OPTIONS,
    })
    local parent_padding_index = 10
    local parent_height_index = 1
    local parent_gap_index = 2
    local parent_justify_index = 1
    local parent_align_index = 2
    local selected_element_index = 1
    local selector_layouts = nil
    local child_entries = {
        {
            node = header,
            label = 'Header',
            padding_index = 8,
            margin_index = 1,
            width_index = 1,
            height_index = 1,
            fixed_width = header.width,
            fixed_height = header.height,
        },
        {
            node = body,
            label = 'Body',
            padding_index = 8,
            margin_index = 7,
            width_index = 1,
            height_index = 1,
            fixed_width = body.width,
            fixed_height = body.height,
        },
        {
            node = footer,
            label = 'Footer',
            padding_index = 9,
            margin_index = 1,
            width_index = 1,
            height_index = 1,
            fixed_width = footer.width,
            fixed_height = footer.height,
        },
    }

    rawset(parent, '_demo_label', '')
    helpers.set_hint_name(parent, 'parent')
    set_parent_hint(parent, helpers)
    helpers.show_bounds(parent)

    local parent_bounds_overlay = rawget(parent, '_demo_bounds_overlay')
    parent_bounds_overlay.borderStyle = 'rough'
    parent_bounds_overlay.borderPattern = 'dashed'
    parent_bounds_overlay.borderDashLength = 8
    parent_bounds_overlay.borderGapLength = 6

    for index = 1, #child_entries do
        local entry = child_entries[index]

        rawset(entry.node, '_demo_label', entry.label)
        rawset(entry.node, '_demo_label_rect', 'content')
        rawset(entry.node, '_demo_label_inset_x', 0)
        rawset(entry.node, '_demo_label_inset_y', 0)
        helpers.set_hint_name(entry.node, 'child')
        set_child_hint(entry.node, helpers)
    end

    local function resolve_parent_height(fixed_value)
        local option = PARENT_SIZE_OPTIONS[parent_height_index].value

        if option == 'fixed' then
            return fixed_value
        end

        return option
    end

    local function active_child_width_options()
        return CHILD_SIZE_OPTIONS
    end

    local function active_child_height_options()
        if PARENT_SIZE_OPTIONS[parent_height_index].value == 'content' then
            return { CHILD_SIZE_OPTIONS[1] }
        end

        return CHILD_SIZE_OPTIONS
    end

    local function clamp_index(index, option_list)
        if index > #option_list then
            return #option_list
        end

        return index
    end

    local function apply_parent_controls()
        parent.padding = copy_spacing(SPACING_OPTIONS[parent_padding_index].value)
        parent.width = parent_fixed_width
        parent.height = resolve_parent_height(parent_fixed_height)
        parent.gap = GAP_OPTIONS[parent_gap_index].value
        parent.justify = JUSTIFY_OPTIONS[parent_justify_index].value
        parent.align = ALIGN_OPTIONS[parent_align_index].value
    end

    local function apply_child_controls()
        local width_options = active_child_width_options()
        local height_options = active_child_height_options()

        for index = 1, #child_entries do
            local entry = child_entries[index]
            local width_option
            local height_option

            entry.width_index = clamp_index(entry.width_index, width_options)
            entry.height_index = clamp_index(entry.height_index, height_options)
            width_option = width_options[entry.width_index].value
            height_option = height_options[entry.height_index].value

            entry.node.padding = copy_spacing(SPACING_OPTIONS[entry.padding_index].value)
            entry.node.margin = copy_spacing(SPACING_OPTIONS[entry.margin_index].value)
            entry.node.width = width_option == 'fixed' and entry.fixed_width or width_option
            entry.node.height = height_option == 'fixed' and entry.fixed_height or height_option
        end
    end

    local function build_selector_layouts()
        local bounds = parent:getWorldBounds()
        local field_gap = 4
        local row_gap = 30
        local side_gap = 40
        local probe_layout = build_navigator_layout(0, 0, selector_body_width, title_font)
        local control_width = navigator_width(probe_layout)
        local row_step = probe_layout.body.height + label_font:getHeight() + field_gap + row_gap
        local center_y = bounds.y + (bounds.height * 0.5)
        local parent_probe_layouts = {}
        local child_probe_layouts = {}
        local parent_layouts
        local child_layouts

        for index = 1, 5 do
            parent_probe_layouts[index] = build_navigator_layout(
                bounds.x - control_width - side_gap,
                (index - 1) * row_step,
                selector_body_width,
                title_font
            )
            child_probe_layouts[index] = build_navigator_layout(
                bounds.x + bounds.width + side_gap,
                (index - 1) * row_step,
                selector_body_width,
                title_font
            )
        end

        parent_layouts = NativeControls.center_group_layouts_y(
            parent_probe_layouts,
            title_font,
            label_font,
            center_y
        )
        child_layouts = NativeControls.center_group_layouts_y(
            child_probe_layouts,
            title_font,
            label_font,
            center_y
        )

        selector_layouts = {
            parent_padding = parent_layouts[1],
            parent_height = parent_layouts[2],
            parent_gap = parent_layouts[3],
            parent_justify = parent_layouts[4],
            parent_align = parent_layouts[5],
            element = child_layouts[1],
            child_padding = child_layouts[2],
            child_margin = child_layouts[3],
            child_width = child_layouts[4],
            child_height = child_layouts[5],
            field_gap = field_gap,
        }
    end

    local function mousepressed(x, y, button)
        local selected = child_entries[selected_element_index]
        local width_options = active_child_width_options()
        local height_options = active_child_height_options()
        local function consume_click()
            LayoutDemoDebug.dump('layout_column', {
                LayoutDemoDebug.entry('element', child_entries[selected_element_index].label),
                LayoutDemoDebug.group('child', {
                    LayoutDemoDebug.entry('padding', SPACING_OPTIONS[child_entries[selected_element_index].padding_index].label),
                    LayoutDemoDebug.entry('margin', SPACING_OPTIONS[child_entries[selected_element_index].margin_index].label),
                    LayoutDemoDebug.entry('width', active_child_width_options()[child_entries[selected_element_index].width_index].label),
                    LayoutDemoDebug.entry('height', active_child_height_options()[child_entries[selected_element_index].height_index].label),
                }),
                LayoutDemoDebug.group('parent', {
                    LayoutDemoDebug.entry('padding', SPACING_OPTIONS[parent_padding_index].label),
                    LayoutDemoDebug.entry('height', PARENT_SIZE_OPTIONS[parent_height_index].label),
                    LayoutDemoDebug.entry('gap', GAP_OPTIONS[parent_gap_index].label),
                    LayoutDemoDebug.entry('justify', JUSTIFY_OPTIONS[parent_justify_index].label),
                    LayoutDemoDebug.entry('align', ALIGN_OPTIONS[parent_align_index].label),
                }),
            })
            return true
        end

        if button ~= 1 then
            return false
        end

        build_selector_layouts()

        if NativeControls.point_in_rect(selector_layouts.parent_padding.left, x, y) then
            parent_padding_index = cycle_index(parent_padding_index, -1, #SPACING_OPTIONS)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_padding.right, x, y) then
            parent_padding_index = cycle_index(parent_padding_index, 1, #SPACING_OPTIONS)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_height.left, x, y) then
            parent_height_index = cycle_index(parent_height_index, -1, #PARENT_SIZE_OPTIONS)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_height.right, x, y) then
            parent_height_index = cycle_index(parent_height_index, 1, #PARENT_SIZE_OPTIONS)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_gap.left, x, y) then
            parent_gap_index = cycle_index(parent_gap_index, -1, #GAP_OPTIONS)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_gap.right, x, y) then
            parent_gap_index = cycle_index(parent_gap_index, 1, #GAP_OPTIONS)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_justify.left, x, y) then
            parent_justify_index = cycle_index(parent_justify_index, -1, #JUSTIFY_OPTIONS)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_justify.right, x, y) then
            parent_justify_index = cycle_index(parent_justify_index, 1, #JUSTIFY_OPTIONS)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_align.left, x, y) then
            parent_align_index = cycle_index(parent_align_index, -1, #ALIGN_OPTIONS)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_align.right, x, y) then
            parent_align_index = cycle_index(parent_align_index, 1, #ALIGN_OPTIONS)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.element.left, x, y) then
            selected_element_index = cycle_index(selected_element_index, -1, #child_entries)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.element.right, x, y) then
            selected_element_index = cycle_index(selected_element_index, 1, #child_entries)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.child_padding.left, x, y) then
            selected.padding_index = cycle_index(selected.padding_index, -1, #SPACING_OPTIONS)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.child_padding.right, x, y) then
            selected.padding_index = cycle_index(selected.padding_index, 1, #SPACING_OPTIONS)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.child_margin.left, x, y) then
            selected.margin_index = cycle_index(selected.margin_index, -1, #SPACING_OPTIONS)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.child_margin.right, x, y) then
            selected.margin_index = cycle_index(selected.margin_index, 1, #SPACING_OPTIONS)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.child_width.left, x, y) then
            selected.width_index = cycle_index(selected.width_index, -1, #width_options)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.child_width.right, x, y) then
            selected.width_index = cycle_index(selected.width_index, 1, #width_options)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.child_height.left, x, y) then
            selected.height_index = cycle_index(selected.height_index, -1, #height_options)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.child_height.right, x, y) then
            selected.height_index = cycle_index(selected.height_index, 1, #height_options)
            return consume_click()
        end

        return false
    end

    rawset(stage, '_demo_screen_hooks', {
        update = function()
            local viewport = root:getWorldBounds()
            local bounds = parent:getLocalBounds()
            local selected = child_entries[selected_element_index]

            apply_parent_controls()
            apply_child_controls()
            parent.x = math.floor((viewport.width - bounds.width) * 0.5)
            parent.y = math.floor((viewport.height - bounds.height) * 0.5)

            build_selector_layouts()

            parent_bounds_overlay.borderColor = { 184, 191, 207 }

            for index = 1, #child_entries do
                local entry = child_entries[index]
                if index == selected_element_index then
                    entry.node.borderColor = { 255, 255, 255, 255 }
                elseif entry.label == 'Header' then
                    entry.node.borderColor = { 117, 184, 255 }
                elseif entry.label == 'Body' then
                    entry.node.borderColor = { 125, 235, 168 }
                else
                    entry.node.borderColor = { 255, 208, 117 }
                end
            end
        end,
        mousepressed = mousepressed,
        draw_overlay = function(graphics)
            local bounds = parent:getWorldBounds()
            local hovered_node = helpers._draw_context and helpers._draw_context.hovered_node or nil
            local mouse_x, mouse_y = love.mouse.getPosition()
            local selected = child_entries[selected_element_index]
            local child_width_options = active_child_width_options()
            local child_height_options = active_child_height_options()
            local parent_panel = NativeControls.build_group_panel({
                selector_layouts.parent_padding,
                selector_layouts.parent_height,
                selector_layouts.parent_gap,
                selector_layouts.parent_justify,
                selector_layouts.parent_align,
            }, title_font, label_font)
            local child_panel = NativeControls.build_group_panel({
                selector_layouts.element,
                selector_layouts.child_padding,
                selector_layouts.child_margin,
                selector_layouts.child_width,
                selector_layouts.child_height,
            }, title_font, label_font)

            LayoutSpacingVisuals.draw_margin_overlay(graphics, selected.node)
            LayoutSpacingVisuals.draw_padding_overlay(graphics, selected.node)

            LayoutSpacingVisuals.draw_hovered_overlays(graphics, hovered_node, {
                parent = parent,
                children = { header, body, footer },
                show_column_gap = true,
            })

            graphics.setColor(0.95, 0.95, 0.95, 1)
            graphics.setFont(title_font)
            graphics.print('Parent', bounds.x, bounds.y - title_font:getHeight() - 10)
            NativeControls.draw_group_panel(graphics, title_font, parent_panel, 'Parent')
            NativeControls.draw_group_panel(graphics, title_font, child_panel, 'Child')

            graphics.setFont(label_font)
            graphics.setColor(DemoColors.roles.text)
            draw_centered_label(graphics, label_font, selector_layouts.parent_padding, 'Padding', selector_layouts.parent_padding.body.y - label_font:getHeight() - selector_layouts.field_gap)
            draw_centered_label(graphics, label_font, selector_layouts.parent_height, 'Height', selector_layouts.parent_height.body.y - label_font:getHeight() - selector_layouts.field_gap)
            draw_centered_label(graphics, label_font, selector_layouts.parent_gap, 'Gap', selector_layouts.parent_gap.body.y - label_font:getHeight() - selector_layouts.field_gap)
            draw_centered_label(graphics, label_font, selector_layouts.parent_justify, 'Justify', selector_layouts.parent_justify.body.y - label_font:getHeight() - selector_layouts.field_gap)
            draw_centered_label(graphics, label_font, selector_layouts.parent_align, 'Align', selector_layouts.parent_align.body.y - label_font:getHeight() - selector_layouts.field_gap)
            draw_centered_label(graphics, label_font, selector_layouts.element, 'Element', selector_layouts.element.body.y - label_font:getHeight() - selector_layouts.field_gap)
            draw_centered_label(graphics, label_font, selector_layouts.child_padding, 'Padding', selector_layouts.child_padding.body.y - label_font:getHeight() - selector_layouts.field_gap)
            draw_centered_label(graphics, label_font, selector_layouts.child_margin, 'Margin', selector_layouts.child_margin.body.y - label_font:getHeight() - selector_layouts.field_gap)
            draw_centered_label(graphics, label_font, selector_layouts.child_width, 'Width', selector_layouts.child_width.body.y - label_font:getHeight() - selector_layouts.field_gap)
            draw_centered_label(graphics, label_font, selector_layouts.child_height, 'Height', selector_layouts.child_height.body.y - label_font:getHeight() - selector_layouts.field_gap)

            NativeControls.draw_navigator(graphics, title_font, selector_layouts.parent_padding, SPACING_OPTIONS[parent_padding_index].label, NativeControls.point_in_rect(selector_layouts.parent_padding.left, mouse_x, mouse_y), NativeControls.point_in_rect(selector_layouts.parent_padding.right, mouse_x, mouse_y), DemoColors.roles.border_light)
            NativeControls.draw_navigator(graphics, title_font, selector_layouts.parent_height, PARENT_SIZE_OPTIONS[parent_height_index].label, NativeControls.point_in_rect(selector_layouts.parent_height.left, mouse_x, mouse_y), NativeControls.point_in_rect(selector_layouts.parent_height.right, mouse_x, mouse_y))
            NativeControls.draw_navigator(graphics, title_font, selector_layouts.parent_gap, GAP_OPTIONS[parent_gap_index].label, NativeControls.point_in_rect(selector_layouts.parent_gap.left, mouse_x, mouse_y), NativeControls.point_in_rect(selector_layouts.parent_gap.right, mouse_x, mouse_y))
            NativeControls.draw_navigator(graphics, title_font, selector_layouts.parent_justify, JUSTIFY_OPTIONS[parent_justify_index].label, NativeControls.point_in_rect(selector_layouts.parent_justify.left, mouse_x, mouse_y), NativeControls.point_in_rect(selector_layouts.parent_justify.right, mouse_x, mouse_y))
            NativeControls.draw_navigator(graphics, title_font, selector_layouts.parent_align, ALIGN_OPTIONS[parent_align_index].label, NativeControls.point_in_rect(selector_layouts.parent_align.left, mouse_x, mouse_y), NativeControls.point_in_rect(selector_layouts.parent_align.right, mouse_x, mouse_y))
            NativeControls.draw_navigator(graphics, title_font, selector_layouts.element, selected.label, NativeControls.point_in_rect(selector_layouts.element.left, mouse_x, mouse_y), NativeControls.point_in_rect(selector_layouts.element.right, mouse_x, mouse_y), DemoColors.roles.border_light)
            NativeControls.draw_navigator(graphics, title_font, selector_layouts.child_padding, SPACING_OPTIONS[selected.padding_index].label, NativeControls.point_in_rect(selector_layouts.child_padding.left, mouse_x, mouse_y), NativeControls.point_in_rect(selector_layouts.child_padding.right, mouse_x, mouse_y))
            NativeControls.draw_navigator(graphics, title_font, selector_layouts.child_margin, SPACING_OPTIONS[selected.margin_index].label, NativeControls.point_in_rect(selector_layouts.child_margin.left, mouse_x, mouse_y), NativeControls.point_in_rect(selector_layouts.child_margin.right, mouse_x, mouse_y))
            NativeControls.draw_navigator(graphics, title_font, selector_layouts.child_width, child_width_options[selected.width_index].label, NativeControls.point_in_rect(selector_layouts.child_width.left, mouse_x, mouse_y), NativeControls.point_in_rect(selector_layouts.child_width.right, mouse_x, mouse_y))
            NativeControls.draw_navigator(graphics, title_font, selector_layouts.child_height, child_height_options[selected.height_index].label, NativeControls.point_in_rect(selector_layouts.child_height.left, mouse_x, mouse_y), NativeControls.point_in_rect(selector_layouts.child_height.right, mouse_x, mouse_y))
        end,
    })
end

return Setup
