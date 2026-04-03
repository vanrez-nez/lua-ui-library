local DemoColors = require('demos.common.colors')
local DemoInstruments = require('demos.02-drawable.demo_instruments')
local NativeControls = require('demos.common.native_controls')

local INSET_STEP = 5
local MAX_INSET = 60
local NAVIGATOR_ORDER = { 3, 2, 1 }

local NODE_STYLES = {
    {
        label = 'Outer',
        fill = DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.18),
        line = DemoColors.roles.accent_green_line,
    },
    {
        label = 'Middle',
        fill = DemoColors.rgba(DemoColors.roles.accent_violet_fill, 0.18),
        line = DemoColors.roles.accent_violet_line,
    },
    {
        label = 'Inner',
        fill = DemoColors.rgba(DemoColors.roles.accent_cyan_fill, 0.2),
        line = DemoColors.roles.accent_cyan_line,
    },
}

local CONTROL_LAYOUT = {
    {
        side = 'top',
        rows = {
            { property = 'padding', inset = 'top', label = 'Top Padding' },
            { property = 'margin', inset = 'top', label = 'Top Margin' },
        },
    },
    {
        side = 'right',
        rows = {
            { property = 'padding', inset = 'right', label = 'Right Padding' },
            { property = 'margin', inset = 'right', label = 'Right Margin' },
        },
    },
    {
        side = 'bottom',
        rows = {
            { property = 'padding', inset = 'bottom', label = 'Bottom Padding' },
            { property = 'margin', inset = 'bottom', label = 'Bottom Margin' },
        },
    },
    {
        side = 'left',
        rows = {
            { property = 'padding', inset = 'left', label = 'Left Padding' },
            { property = 'margin', inset = 'left', label = 'Left Margin' },
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

function Setup.install(args)
    local scope = args.scope
    local owner = args.owner
    local helpers = args.helpers
    local nodes = args.nodes
    local label_font = scope:font(11)
    local title_font = scope:font(12)
    local selected_nav_index = 2
    local navigator = nil
    local controls = {}

    for index = 1, #nodes do
        DemoInstruments.decorate_drawable(nodes[index], NODE_STYLES[index])
        DemoInstruments.set_spacing_hint(nodes[index], helpers)
    end

    local function cleanup()
        for index = #nodes, 1, -1 do
            local node = nodes[index]
            if rawget(node, '_destroyed') ~= true then
                node:destroy()
            end
        end
    end

    scope:on_cleanup(cleanup)

    local function selected_index()
        return NAVIGATOR_ORDER[selected_nav_index]
    end

    local function selected_node()
        return nodes[selected_index()]
    end

    local function update()
        navigator = NativeControls.build_centered_navigator_layout(
            love.graphics.getWidth(),
            owner.header_height + 10,
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
        local selected_style = NODE_STYLES[selected_index()]
        local selected_bounds = node:getWorldBounds()
        local content_rect = DemoInstruments.to_world_rect(node, node:getContentRect())
        local navigator_text = rawget(node, '_demo_label') or 'Middle'

        if DemoInstruments.has_insets(node.margin) then
            local margin = node.margin
            local margin_rect = DemoInstruments.to_world_rect(node, {
                x = -margin.left,
                y = -margin.top,
                width = node.width + margin.left + margin.right,
                height = node.height + margin.top + margin.bottom,
            })
            NativeControls.draw_rect(
                graphics,
                margin_rect,
                'line',
                NativeControls.set_alpha(DemoColors.roles.accent_highlight, 0.85),
                2
            )
        end

        NativeControls.draw_rect(
            graphics,
            content_rect,
            'fill',
            NativeControls.set_alpha(DemoColors.roles.accent_amber_fill, 0.16)
        )
        NativeControls.draw_rect(graphics, content_rect, 'line', DemoColors.roles.accent_amber_line)
        NativeControls.draw_rect(graphics, selected_bounds, 'line', selected_style.line, 3)

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
        NativeControls.draw_rect(graphics, navigator.body, 'line', selected_style.line)
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

    return {
        mousepressed = mousepressed,
        update = update,
        draw_overlay = draw_overlay,
    }
end

return Setup
