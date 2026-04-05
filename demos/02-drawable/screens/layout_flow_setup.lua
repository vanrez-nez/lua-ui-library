local DemoColors = require('demos.common.colors')
local LayoutDemoDebug = require('demos.common.layout_demo_debug')
local LayoutSpacingVisuals = require('demos.common.layout_spacing_visuals')
local NativeControls = require('demos.common.native_controls')

local Setup = {}

local ELEMENT_OPTIONS = {
    { label = 'Alpha' },
    { label = 'Beta' },
    { label = 'Gamma' },
    { label = 'Delta' },
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

local WRAP_OPTIONS = {
    { label = 'Off', value = false },
    { label = 'On', value = true },
}

local DIRECTION_OPTIONS = {
    { label = 'LTR', value = 'ltr' },
    { label = 'RTL', value = 'rtl' },
}

local JUSTIFY_OPTIONS = {
    { label = 'Start', value = 'start' },
    { label = 'Center', value = 'center' },
    { label = 'End', value = 'end' },
    { label = 'Between', value = 'space-between' },
    { label = 'Around', value = 'space-around' },
}

local PARENT_WIDTH_OPTIONS = {
    { label = 'Fixed', value = 'fixed' },
    { label = '20%', value = '20%' },
    { label = '40%', value = '40%' },
    { label = '80%', value = '80%' },
}

local CHILD_SIZE_OPTIONS = {
    { label = 'Fixed', value = 'fixed' },
    { label = '20%', value = '20%' },
    { label = '40%', value = '40%' },
    { label = '80%', value = '80%' },
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
        error('layout_flow_setup: missing node "' .. id .. '"', 2)
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
                    helpers.badge(nil, 'Flow'),
                },
            },
        }

        append_rect_row(entries, helpers, 'parent.container', current:getLocalBounds())
        append_rect_row(entries, helpers, 'parent.content', current:_get_effective_content_rect())
        entries[#entries + 1] = {
            label = 'layout',
            badges = {
                helpers.badge('justify', current.justify or 'start'),
                helpers.badge('gap', helpers.format_scalar(current.gap or 0)),
                helpers.badge('wrap', tostring(current.wrap == true)),
                helpers.badge('direction', current.direction or 'ltr'),
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
    local parent = find_required(root, 'layout-flow-parent')
    local alpha = find_required(root, 'layout-flow-alpha')
    local beta = find_required(root, 'layout-flow-beta')
    local gamma = find_required(root, 'layout-flow-gamma')
    local delta = find_required(root, 'layout-flow-delta')
    local parent_fixed_width = parent.width
    local parent_fixed_height = parent.height
    local selector_body_width = max_option_body_width(title_font, {
        ELEMENT_OPTIONS,
        SPACING_OPTIONS,
        GAP_OPTIONS,
        WRAP_OPTIONS,
        DIRECTION_OPTIONS,
        JUSTIFY_OPTIONS,
        PARENT_WIDTH_OPTIONS,
        CHILD_SIZE_OPTIONS,
    })
    local parent_padding_index = 10
    local parent_width_index = 1
    local parent_gap_index = 2
    local parent_wrap_index = 2
    local parent_direction_index = 1
    local parent_justify_index = 1
    local selected_element_index = 1
    local selector_layouts = nil
    local child_entries = {
        {
            node = alpha,
            label = 'Alpha',
            padding_index = 9,
            margin_index = 1,
            width_index = 1,
            height_index = 1,
            fixed_width = alpha.width,
            fixed_height = alpha.height,
        },
        {
            node = beta,
            label = 'Beta',
            padding_index = 8,
            margin_index = 6,
            width_index = 1,
            height_index = 1,
            fixed_width = beta.width,
            fixed_height = beta.height,
        },
        {
            node = gamma,
            label = 'Gamma',
            padding_index = 9,
            margin_index = 1,
            width_index = 1,
            height_index = 1,
            fixed_width = gamma.width,
            fixed_height = gamma.height,
        },
        {
            node = delta,
            label = 'Delta',
            padding_index = 9,
            margin_index = 1,
            width_index = 1,
            height_index = 1,
            fixed_width = delta.width,
            fixed_height = delta.height,
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

    local function resolve_parent_width()
        local option = PARENT_WIDTH_OPTIONS[parent_width_index].value

        if option == 'fixed' then
            return parent_fixed_width
        end

        return option
    end

    local function apply_parent_constraints(viewport)
        local side_gap = 40
        local panel_padding = 24
        local probe_layout = build_navigator_layout(0, 0, selector_body_width, title_font)
        local control_width = navigator_width(probe_layout)
        local side_column_width = control_width + panel_padding
        local horizontal_margin = 30
        local vertical_margin = 80
        local max_width = math.max(
            200,
            viewport.width - (side_column_width * 2) - (side_gap * 2) - (horizontal_margin * 2)
        )
        local max_height = math.max(
            200,
            viewport.height - (vertical_margin * 2)
        )

        parent.maxWidth = max_width
        parent.maxHeight = max_height
    end

    local function apply_parent_controls(viewport)
        apply_parent_constraints(viewport)
        parent.padding = copy_spacing(SPACING_OPTIONS[parent_padding_index].value)
        parent.width = resolve_parent_width()
        parent.height = parent_fixed_height
        parent.gap = GAP_OPTIONS[parent_gap_index].value
        parent.wrap = WRAP_OPTIONS[parent_wrap_index].value
        parent.direction = DIRECTION_OPTIONS[parent_direction_index].value
        parent.justify = JUSTIFY_OPTIONS[parent_justify_index].value
    end

    local function apply_child_controls()
        for index = 1, #child_entries do
            local entry = child_entries[index]
            local width_option = CHILD_SIZE_OPTIONS[entry.width_index].value
            local height_option = CHILD_SIZE_OPTIONS[entry.height_index].value

            entry.node.padding = copy_spacing(SPACING_OPTIONS[entry.padding_index].value)
            entry.node.margin = copy_spacing(SPACING_OPTIONS[entry.margin_index].value)
            entry.node.width = width_option == 'fixed' and entry.fixed_width or width_option
            entry.node.height = height_option == 'fixed' and entry.fixed_height or height_option
        end
    end

    local function build_selector_layouts()
        local viewport = root:getWorldBounds()
        local bounds = parent:getWorldBounds()
        local field_gap = 4
        local row_gap = 30
        local side_gap = 40
        local probe_layout = build_navigator_layout(0, 0, selector_body_width, title_font)
        local control_width = navigator_width(probe_layout)
        local row_height = probe_layout.body.height
        local parent_column_height = (row_height * 6) + ((label_font:getHeight() + field_gap) * 6) + (row_gap * 5)
        local child_column_height = (row_height * 5) + ((label_font:getHeight() + field_gap) * 5) + (row_gap * 4)
        local start_y = math.floor((viewport.height - math.max(parent_column_height, child_column_height)) * 0.5)

        selector_layouts = {
            parent_padding = build_navigator_layout(bounds.x - control_width - side_gap, start_y, selector_body_width, title_font),
            parent_width = build_navigator_layout(bounds.x - control_width - side_gap, start_y + ((row_height + label_font:getHeight() + field_gap + row_gap) * 1), selector_body_width, title_font),
            parent_gap = build_navigator_layout(bounds.x - control_width - side_gap, start_y + ((row_height + label_font:getHeight() + field_gap + row_gap) * 2), selector_body_width, title_font),
            parent_wrap = build_navigator_layout(bounds.x - control_width - side_gap, start_y + ((row_height + label_font:getHeight() + field_gap + row_gap) * 3), selector_body_width, title_font),
            parent_direction = build_navigator_layout(bounds.x - control_width - side_gap, start_y + ((row_height + label_font:getHeight() + field_gap + row_gap) * 4), selector_body_width, title_font),
            parent_justify = build_navigator_layout(bounds.x - control_width - side_gap, start_y + ((row_height + label_font:getHeight() + field_gap + row_gap) * 5), selector_body_width, title_font),
            element = build_navigator_layout(bounds.x + bounds.width + side_gap, start_y, selector_body_width, title_font),
            child_padding = build_navigator_layout(bounds.x + bounds.width + side_gap, start_y + ((row_height + label_font:getHeight() + field_gap + row_gap) * 1), selector_body_width, title_font),
            child_margin = build_navigator_layout(bounds.x + bounds.width + side_gap, start_y + ((row_height + label_font:getHeight() + field_gap + row_gap) * 2), selector_body_width, title_font),
            child_width = build_navigator_layout(bounds.x + bounds.width + side_gap, start_y + ((row_height + label_font:getHeight() + field_gap + row_gap) * 3), selector_body_width, title_font),
            child_height = build_navigator_layout(bounds.x + bounds.width + side_gap, start_y + ((row_height + label_font:getHeight() + field_gap + row_gap) * 4), selector_body_width, title_font),
            field_gap = field_gap,
        }
    end

    local function mousepressed(x, y, button)
        local selected = child_entries[selected_element_index]
        local function consume_click()
            LayoutDemoDebug.dump('layout_flow', {
                LayoutDemoDebug.entry('element', child_entries[selected_element_index].label),
                LayoutDemoDebug.group('child', {
                    LayoutDemoDebug.entry('padding', SPACING_OPTIONS[child_entries[selected_element_index].padding_index].label),
                    LayoutDemoDebug.entry('margin', SPACING_OPTIONS[child_entries[selected_element_index].margin_index].label),
                    LayoutDemoDebug.entry('width', CHILD_SIZE_OPTIONS[child_entries[selected_element_index].width_index].label),
                    LayoutDemoDebug.entry('height', CHILD_SIZE_OPTIONS[child_entries[selected_element_index].height_index].label),
                }),
                LayoutDemoDebug.group('parent', {
                    LayoutDemoDebug.entry('padding', SPACING_OPTIONS[parent_padding_index].label),
                    LayoutDemoDebug.entry('width', PARENT_WIDTH_OPTIONS[parent_width_index].label),
                    LayoutDemoDebug.entry('gap', GAP_OPTIONS[parent_gap_index].label),
                    LayoutDemoDebug.entry('wrap', WRAP_OPTIONS[parent_wrap_index].label),
                    LayoutDemoDebug.entry('direction', DIRECTION_OPTIONS[parent_direction_index].label),
                    LayoutDemoDebug.entry('justify', JUSTIFY_OPTIONS[parent_justify_index].label),
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

        if NativeControls.point_in_rect(selector_layouts.parent_width.left, x, y) then
            parent_width_index = cycle_index(parent_width_index, -1, #PARENT_WIDTH_OPTIONS)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_width.right, x, y) then
            parent_width_index = cycle_index(parent_width_index, 1, #PARENT_WIDTH_OPTIONS)
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

        if NativeControls.point_in_rect(selector_layouts.parent_wrap.left, x, y) then
            parent_wrap_index = cycle_index(parent_wrap_index, -1, #WRAP_OPTIONS)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_wrap.right, x, y) then
            parent_wrap_index = cycle_index(parent_wrap_index, 1, #WRAP_OPTIONS)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_direction.left, x, y) then
            parent_direction_index = cycle_index(parent_direction_index, -1, #DIRECTION_OPTIONS)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.parent_direction.right, x, y) then
            parent_direction_index = cycle_index(parent_direction_index, 1, #DIRECTION_OPTIONS)
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
            selected.width_index = cycle_index(selected.width_index, -1, #CHILD_SIZE_OPTIONS)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.child_width.right, x, y) then
            selected.width_index = cycle_index(selected.width_index, 1, #CHILD_SIZE_OPTIONS)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.child_height.left, x, y) then
            selected.height_index = cycle_index(selected.height_index, -1, #CHILD_SIZE_OPTIONS)
            return consume_click()
        end

        if NativeControls.point_in_rect(selector_layouts.child_height.right, x, y) then
            selected.height_index = cycle_index(selected.height_index, 1, #CHILD_SIZE_OPTIONS)
            return consume_click()
        end

        return false
    end

    rawset(stage, '_demo_screen_hooks', {
        update = function()
            local viewport = root:getWorldBounds()
            local bounds = parent:getLocalBounds()
            local selected = child_entries[selected_element_index]

            apply_parent_controls(viewport)
            apply_child_controls()
            parent.x = math.floor((viewport.width - bounds.width) * 0.5)
            parent.y = math.floor((viewport.height - bounds.height) * 0.5)

            build_selector_layouts()

            parent_bounds_overlay.borderColor = { 184, 191, 207 }

            for index = 1, #child_entries do
                local entry = child_entries[index]
                if index == selected_element_index then
                    entry.node.borderColor = { 255, 255, 255, 255 }
                elseif entry.label == 'Alpha' then
                    entry.node.borderColor = { 117, 184, 255 }
                elseif entry.label == 'Beta' then
                    entry.node.borderColor = { 125, 235, 168 }
                elseif entry.label == 'Gamma' then
                    entry.node.borderColor = { 255, 208, 117 }
                else
                    entry.node.borderColor = { 210, 165, 255 }
                end
            end
        end,
        mousepressed = mousepressed,
        draw_overlay = function(graphics)
            local bounds = parent:getWorldBounds()
            local hovered_node = helpers._draw_context and helpers._draw_context.hovered_node or nil
            local mouse_x, mouse_y = love.mouse.getPosition()
            local selected = child_entries[selected_element_index]
            local parent_panel = NativeControls.build_group_panel({
                selector_layouts.parent_padding,
                selector_layouts.parent_width,
                selector_layouts.parent_gap,
                selector_layouts.parent_wrap,
                selector_layouts.parent_direction,
                selector_layouts.parent_justify,
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
                children = { alpha, beta, gamma, delta },
                show_flow_gap = true,
            })

            graphics.setColor(0.95, 0.95, 0.95, 1)
            graphics.setFont(title_font)
            graphics.print('Parent', bounds.x, bounds.y - title_font:getHeight() - 10)
            NativeControls.draw_group_panel(graphics, title_font, parent_panel, 'Parent')
            NativeControls.draw_group_panel(graphics, title_font, child_panel, 'Child')

            graphics.setFont(label_font)
            graphics.setColor(DemoColors.roles.text)
            draw_centered_label(graphics, label_font, selector_layouts.parent_padding, 'Padding', selector_layouts.parent_padding.body.y - label_font:getHeight() - selector_layouts.field_gap)
            draw_centered_label(graphics, label_font, selector_layouts.parent_width, 'Width', selector_layouts.parent_width.body.y - label_font:getHeight() - selector_layouts.field_gap)
            draw_centered_label(graphics, label_font, selector_layouts.parent_gap, 'Gap', selector_layouts.parent_gap.body.y - label_font:getHeight() - selector_layouts.field_gap)
            draw_centered_label(graphics, label_font, selector_layouts.parent_wrap, 'Wrap', selector_layouts.parent_wrap.body.y - label_font:getHeight() - selector_layouts.field_gap)
            draw_centered_label(graphics, label_font, selector_layouts.parent_direction, 'Direction', selector_layouts.parent_direction.body.y - label_font:getHeight() - selector_layouts.field_gap)
            draw_centered_label(graphics, label_font, selector_layouts.parent_justify, 'Justify', selector_layouts.parent_justify.body.y - label_font:getHeight() - selector_layouts.field_gap)
            draw_centered_label(graphics, label_font, selector_layouts.element, 'Element', selector_layouts.element.body.y - label_font:getHeight() - selector_layouts.field_gap)
            draw_centered_label(graphics, label_font, selector_layouts.child_padding, 'Padding', selector_layouts.child_padding.body.y - label_font:getHeight() - selector_layouts.field_gap)
            draw_centered_label(graphics, label_font, selector_layouts.child_margin, 'Margin', selector_layouts.child_margin.body.y - label_font:getHeight() - selector_layouts.field_gap)
            draw_centered_label(graphics, label_font, selector_layouts.child_width, 'Width', selector_layouts.child_width.body.y - label_font:getHeight() - selector_layouts.field_gap)
            draw_centered_label(graphics, label_font, selector_layouts.child_height, 'Height', selector_layouts.child_height.body.y - label_font:getHeight() - selector_layouts.field_gap)

            NativeControls.draw_navigator(graphics, title_font, selector_layouts.parent_padding, SPACING_OPTIONS[parent_padding_index].label, NativeControls.point_in_rect(selector_layouts.parent_padding.left, mouse_x, mouse_y), NativeControls.point_in_rect(selector_layouts.parent_padding.right, mouse_x, mouse_y), DemoColors.roles.border_light)
            NativeControls.draw_navigator(graphics, title_font, selector_layouts.parent_width, PARENT_WIDTH_OPTIONS[parent_width_index].label, NativeControls.point_in_rect(selector_layouts.parent_width.left, mouse_x, mouse_y), NativeControls.point_in_rect(selector_layouts.parent_width.right, mouse_x, mouse_y))
            NativeControls.draw_navigator(graphics, title_font, selector_layouts.parent_gap, GAP_OPTIONS[parent_gap_index].label, NativeControls.point_in_rect(selector_layouts.parent_gap.left, mouse_x, mouse_y), NativeControls.point_in_rect(selector_layouts.parent_gap.right, mouse_x, mouse_y))
            NativeControls.draw_navigator(graphics, title_font, selector_layouts.parent_wrap, WRAP_OPTIONS[parent_wrap_index].label, NativeControls.point_in_rect(selector_layouts.parent_wrap.left, mouse_x, mouse_y), NativeControls.point_in_rect(selector_layouts.parent_wrap.right, mouse_x, mouse_y))
            NativeControls.draw_navigator(graphics, title_font, selector_layouts.parent_direction, DIRECTION_OPTIONS[parent_direction_index].label, NativeControls.point_in_rect(selector_layouts.parent_direction.left, mouse_x, mouse_y), NativeControls.point_in_rect(selector_layouts.parent_direction.right, mouse_x, mouse_y))
            NativeControls.draw_navigator(graphics, title_font, selector_layouts.parent_justify, JUSTIFY_OPTIONS[parent_justify_index].label, NativeControls.point_in_rect(selector_layouts.parent_justify.left, mouse_x, mouse_y), NativeControls.point_in_rect(selector_layouts.parent_justify.right, mouse_x, mouse_y))
            NativeControls.draw_navigator(graphics, title_font, selector_layouts.element, selected.label, NativeControls.point_in_rect(selector_layouts.element.left, mouse_x, mouse_y), NativeControls.point_in_rect(selector_layouts.element.right, mouse_x, mouse_y), DemoColors.roles.border_light)
            NativeControls.draw_navigator(graphics, title_font, selector_layouts.child_padding, SPACING_OPTIONS[selected.padding_index].label, NativeControls.point_in_rect(selector_layouts.child_padding.left, mouse_x, mouse_y), NativeControls.point_in_rect(selector_layouts.child_padding.right, mouse_x, mouse_y))
            NativeControls.draw_navigator(graphics, title_font, selector_layouts.child_margin, SPACING_OPTIONS[selected.margin_index].label, NativeControls.point_in_rect(selector_layouts.child_margin.left, mouse_x, mouse_y), NativeControls.point_in_rect(selector_layouts.child_margin.right, mouse_x, mouse_y))
            NativeControls.draw_navigator(graphics, title_font, selector_layouts.child_width, CHILD_SIZE_OPTIONS[selected.width_index].label, NativeControls.point_in_rect(selector_layouts.child_width.left, mouse_x, mouse_y), NativeControls.point_in_rect(selector_layouts.child_width.right, mouse_x, mouse_y))
            NativeControls.draw_navigator(graphics, title_font, selector_layouts.child_height, CHILD_SIZE_OPTIONS[selected.height_index].label, NativeControls.point_in_rect(selector_layouts.child_height.left, mouse_x, mouse_y), NativeControls.point_in_rect(selector_layouts.child_height.right, mouse_x, mouse_y))
        end,
    })
end

return Setup
