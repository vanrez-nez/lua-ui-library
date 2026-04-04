local DemoColors = require('demos.common.colors')
local DemoInstruments = require('demos.common.drawable_demo_instruments')
local Hint = require('demos.common.hint')
local NativeControls = require('demos.common.native_controls')

local INSET_STEP = 5
local MAX_INSET = 60
local NAVIGATOR_ORDER = {
    'nested-spacing-inner',
    'nested-spacing-middle',
    'nested-spacing-outer',
}

local NODE_STYLES = {
    ['nested-spacing-outer'] = {
        label = 'Outer',
    },
    ['nested-spacing-middle'] = {
        label = 'Middle',
    },
    ['nested-spacing-inner'] = {
        label = 'Inner',
    },
}

local CONTROL_LAYOUT = {
    {
        side = 'top',
        rows = {
            { property = 'padding', inset = 'top', label = 'Top Padding' },
        },
    },
    {
        side = 'right',
        rows = {
            { property = 'padding', inset = 'right', label = 'Right Padding' },
        },
    },
    {
        side = 'bottom',
        rows = {
            { property = 'padding', inset = 'bottom', label = 'Bottom Padding' },
        },
    },
    {
        side = 'left',
        rows = {
            { property = 'padding', inset = 'left', label = 'Left Padding' },
        },
    },
}

local Setup = {}

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
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

local function set_inset(node, property, side, delta)
    local current = node[property]
    local next = {
        top = current.top,
        right = current.right,
        bottom = current.bottom,
        left = current.left,
    }
    next[side] = clamp((next[side] or 0) + delta, 0, MAX_INSET)
    node[property] = next
end

local function place_centered_in_parent(parent, child)
    local bounds = child:getLocalBounds()
    local slot = parent:resolveContentRect(
        bounds.width,
        bounds.height
    )

    child.x = slot.x
    child.y = slot.y
end

local function copy_color(color)
    if color == nil then
        return nil
    end

    return {
        color[1],
        color[2],
        color[3],
        color[4],
    }
end

function Setup.install(args)
    local scope = args.scope
    local helpers = args.helpers
    local stage = args.stage
    local root = args.root
    local label_font = scope:font(11)
    local title_font = scope:font(12)
    local selected_nav_index = 2
    local navigator = nil
    local controls = {}
    local nodes_by_id = {}

    for index = 1, #NAVIGATOR_ORDER do
        local node_id = NAVIGATOR_ORDER[index]
        local node = root:findById(node_id, -1)
        if node == nil then
            error('nested_padding_setup: missing node "' .. node_id .. '"', 2)
        end

        nodes_by_id[node_id] = node
        rawset(node, '_demo_label', NODE_STYLES[node_id].label)
        rawset(node, '_demo_base_border_color', copy_color(node.borderColor))
        Hint.set_hint_name(node, NODE_STYLES[node_id].label)
        DemoInstruments.set_spacing_hint(node, helpers)
    end

    local function selected_node()
        return nodes_by_id[NAVIGATOR_ORDER[selected_nav_index]]
    end

    local function root_node()
        return nodes_by_id['nested-spacing-outer']
    end

    local function middle_node()
        return nodes_by_id['nested-spacing-middle']
    end

    local function inner_node()
        return nodes_by_id['nested-spacing-inner']
    end

    local function sync_selection_border()
        local active = selected_node()

        for index = 1, #NAVIGATOR_ORDER do
            local node = nodes_by_id[NAVIGATOR_ORDER[index]]
            local base_border_color = rawget(node, '_demo_base_border_color')

            if node == active then
                node.borderColor = DemoColors.names.white
            else
                node.borderColor = base_border_color
            end
        end
    end

    local function update()
        local viewport = root:getWorldBounds()
        local outer = root_node()
        local middle = middle_node()
        local inner = inner_node()
        local outer_bounds = outer:getLocalBounds()

        sync_selection_border()
        outer.x = math.floor(viewport.x + ((viewport.width - outer_bounds.width) * 0.5) + 0.5)
        outer.y = math.floor(viewport.y + ((viewport.height - outer_bounds.height) * 0.5) + 0.5)
        place_centered_in_parent(outer, middle)
        place_centered_in_parent(middle, inner)

        navigator = NativeControls.build_centered_navigator_layout(
            viewport.width,
            114,
            title_font,
            rawget(selected_node(), '_demo_label') or 'Middle'
        )
        controls = NativeControls.build_edge_control_layout(selected_node():getWorldBounds(), CONTROL_LAYOUT)
    end

    local function mousepressed(x, y, button)
        if button ~= 1 then
            return false
        end

        if NativeControls.point_in_rect(navigator.left, x, y) then
            selected_nav_index = cycle_index(selected_nav_index, -1, #NAVIGATOR_ORDER)
            return true
        end

        if NativeControls.point_in_rect(navigator.right, x, y) then
            selected_nav_index = cycle_index(selected_nav_index, 1, #NAVIGATOR_ORDER)
            return true
        end

        for panel_index = 1, #controls do
            local panel = controls[panel_index]
            for row_index = 1, #panel.rows do
                local row = panel.rows[row_index]
                if NativeControls.point_in_rect(row.minus, x, y) then
                    set_inset(selected_node(), row.spec.property, row.spec.inset, -INSET_STEP)
                    return true
                end

                if NativeControls.point_in_rect(row.plus, x, y) then
                    set_inset(selected_node(), row.spec.property, row.spec.inset, INSET_STEP)
                    return true
                end
            end
        end

        return false
    end

    local function draw_overlay(graphics)
        local mouse_x, mouse_y = love.mouse.getPosition()
        local node = selected_node()
        local navigator_text = rawget(node, '_demo_label') or 'Middle'

        NativeControls.draw_button(
            graphics,
            title_font,
            navigator.left,
            '<',
            NativeControls.point_in_rect(navigator.left, mouse_x, mouse_y)
        )
        NativeControls.draw_button(
            graphics,
            title_font,
            navigator.right,
            '>',
            NativeControls.point_in_rect(navigator.right, mouse_x, mouse_y)
        )
        NativeControls.draw_rect(graphics, navigator.body, 'fill', DemoColors.roles.surface_alt)
        NativeControls.draw_rect(graphics, navigator.body, 'line', node.borderColor)
        graphics.setColor(DemoColors.roles.text)
        graphics.setFont(title_font)
        graphics.print(
            navigator_text,
            navigator.body.x + math.floor((navigator.body.width - title_font:getWidth(navigator_text)) * 0.5 + 0.5),
            navigator.body.y + 5
        )

        for panel_index = 1, #controls do
            local panel = controls[panel_index]
            NativeControls.draw_rect(
                graphics,
                panel.rect,
                'fill',
                NativeControls.set_alpha(DemoColors.roles.overlay_soft, 0.94)
            )
            NativeControls.draw_rect(graphics, panel.rect, 'line', DemoColors.roles.border_light)

            for row_index = 1, #panel.rows do
                local row = panel.rows[row_index]
                local current_value = selected_node()[row.spec.property][row.spec.inset]
                local label = string.format('%s: %d', row.spec.label, current_value)

                NativeControls.draw_button(
                    graphics,
                    title_font,
                    row.minus,
                    '-',
                    NativeControls.point_in_rect(row.minus, mouse_x, mouse_y)
                )
                NativeControls.draw_button(
                    graphics,
                    title_font,
                    row.plus,
                    '+',
                    NativeControls.point_in_rect(row.plus, mouse_x, mouse_y)
                )

                graphics.setColor(DemoColors.roles.text)
                graphics.setFont(label_font)
                graphics.print(label, row.label_x, row.label_y)
            end
        end
    end

    rawset(stage, '_demo_screen_hooks', {
        mousepressed = mousepressed,
        update = update,
        draw_overlay = draw_overlay,
    })
end

return Setup
