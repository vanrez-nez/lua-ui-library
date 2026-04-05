local DemoColors = require('demos.common.colors')

local NativeControls = {}
local DISABLED_ALPHA = 0.25
local GROUP_PANEL_PADDING = 12
local GROUP_PANEL_TITLE_GAP = 10

local function floor(value)
    return math.floor(value + 0.5)
end

function NativeControls.point_in_rect(rect, x, y)
    return x >= rect.x
        and y >= rect.y
        and x <= rect.x + rect.width
        and y <= rect.y + rect.height
end

function NativeControls.set_alpha(color, alpha)
    return {
        color[1],
        color[2],
        color[3],
        (color[4] or 1) * alpha,
    }
end

function NativeControls.draw_rect(graphics, rect, mode, color, line_width)
    graphics.setColor(color)
    if line_width ~= nil then
        graphics.setLineWidth(line_width)
    end
    graphics.rectangle(mode, rect.x, rect.y, rect.width, rect.height)
    if line_width ~= nil then
        graphics.setLineWidth(1)
    end
end

function NativeControls.draw_button(graphics, font, rect, label, hovered, disabled)
    local fill_color = disabled and DemoColors.roles.surface_alt or
        (hovered and DemoColors.roles.surface_emphasis or DemoColors.roles.surface_interactive)
    local border_color = disabled and DemoColors.roles.border or DemoColors.roles.border_light
    local text_color = disabled and DemoColors.roles.text_muted or DemoColors.roles.text

    if disabled then
        fill_color = NativeControls.set_alpha(fill_color, DISABLED_ALPHA)
        border_color = NativeControls.set_alpha(border_color, DISABLED_ALPHA)
        text_color = NativeControls.set_alpha(text_color, DISABLED_ALPHA)
    end

    NativeControls.draw_rect(
        graphics,
        rect,
        'fill',
        fill_color
    )
    NativeControls.draw_rect(
        graphics,
        rect,
        'line',
        border_color
    )

    graphics.setColor(text_color)
    graphics.setFont(font)
    graphics.print(
        label,
        rect.x + floor((rect.width - font:getWidth(label)) * 0.5),
        rect.y + floor((rect.height - font:getHeight()) * 0.5) - 1
    )
end

function NativeControls.build_group_panel(layouts, title_font, label_font)
    local min_x = nil
    local min_y = nil
    local max_x = nil
    local max_y = nil
    local title_height = title_font:getHeight()
    local label_height = label_font:getHeight()

    for index = 1, #layouts do
        local layout = layouts[index]
        local top = layout.body.y - label_height - GROUP_PANEL_TITLE_GAP - title_height - GROUP_PANEL_TITLE_GAP
        local right = layout.right.x + layout.right.width
        local bottom = layout.body.y + layout.body.height

        if min_x == nil or layout.left.x < min_x then
            min_x = layout.left.x
        end

        if min_y == nil or top < min_y then
            min_y = top
        end

        if max_x == nil or right > max_x then
            max_x = right
        end

        if max_y == nil or bottom > max_y then
            max_y = bottom
        end
    end

    if min_x == nil then
        return nil
    end

    return {
        x = min_x - GROUP_PANEL_PADDING,
        y = min_y - GROUP_PANEL_PADDING,
        width = (max_x - min_x) + (GROUP_PANEL_PADDING * 2),
        height = (max_y - min_y) + (GROUP_PANEL_PADDING * 2),
        title_x = min_x - GROUP_PANEL_PADDING + 10,
        title_y = min_y - GROUP_PANEL_PADDING + 8,
    }
end

function NativeControls.draw_group_panel(graphics, title_font, panel, title)
    local border_color = NativeControls.set_alpha(DemoColors.roles.border, 0.15)
    local label_width = title_font:getWidth(title)
    local label_gap = 8
    local top_y = panel.y
    local left_x = panel.x
    local right_x = panel.x + panel.width
    local bottom_y = panel.y + panel.height
    local label_left = panel.title_x - label_gap
    local label_right = panel.title_x + label_width + label_gap
    local label_y = top_y - math.floor(title_font:getHeight() * 0.5)

    graphics.setColor(border_color)
    graphics.line(left_x, top_y, label_left, top_y)
    graphics.line(label_right, top_y, right_x, top_y)
    graphics.line(left_x, top_y, left_x, bottom_y)
    graphics.line(right_x, top_y, right_x, bottom_y)
    graphics.line(left_x, bottom_y, right_x, bottom_y)

    graphics.setColor(DemoColors.roles.text_muted)
    graphics.setFont(title_font)
    graphics.print(title, panel.title_x, label_y)
end

function NativeControls.translate_navigator_layout(layout, dx, dy)
    return {
        left = {
            x = layout.left.x + dx,
            y = layout.left.y + dy,
            width = layout.left.width,
            height = layout.left.height,
        },
        body = {
            x = layout.body.x + dx,
            y = layout.body.y + dy,
            width = layout.body.width,
            height = layout.body.height,
        },
        right = {
            x = layout.right.x + dx,
            y = layout.right.y + dy,
            width = layout.right.width,
            height = layout.right.height,
        },
    }
end

function NativeControls.translate_navigator_layouts(layouts, dx, dy)
    local shifted_layouts = {}

    for index = 1, #layouts do
        shifted_layouts[index] = NativeControls.translate_navigator_layout(layouts[index], dx, dy)
    end

    return shifted_layouts
end

function NativeControls.center_group_layouts_y(layouts, title_font, label_font, center_y)
    local panel = NativeControls.build_group_panel(layouts, title_font, label_font)
    local offset_y

    if panel == nil then
        return layouts
    end

    offset_y = floor(center_y - (panel.y + (panel.height * 0.5)))
    return NativeControls.translate_navigator_layouts(layouts, 0, offset_y)
end

function NativeControls.build_centered_navigator_layout(screen_width, top_y, font, text)
    local nav_height = font:getHeight() + 12
    local arrow_width = 24
    local body_width = font:getWidth(text) + 28
    local total_width = body_width + (arrow_width * 2) + 12
    local left_x = floor((screen_width - total_width) * 0.5)

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

function NativeControls.draw_navigator(graphics, font, layout, text, hovered_left, hovered_right, body_line_color, disabled)
    local fill_color = disabled and DemoColors.roles.surface or DemoColors.roles.surface_alt
    local line_color = disabled and DemoColors.roles.border or (body_line_color or DemoColors.roles.border_light)
    local text_color = disabled and DemoColors.roles.text_muted or DemoColors.roles.text

    if disabled then
        fill_color = NativeControls.set_alpha(fill_color, DISABLED_ALPHA)
        line_color = NativeControls.set_alpha(line_color, DISABLED_ALPHA)
        text_color = NativeControls.set_alpha(text_color, DISABLED_ALPHA)
    end

    NativeControls.draw_button(
        graphics,
        font,
        layout.left,
        '<',
        hovered_left,
        disabled
    )
    NativeControls.draw_button(
        graphics,
        font,
        layout.right,
        '>',
        hovered_right,
        disabled
    )
    NativeControls.draw_rect(
        graphics,
        layout.body,
        'fill',
        fill_color
    )
    NativeControls.draw_rect(
        graphics,
        layout.body,
        'line',
        line_color
    )

    graphics.setColor(text_color)
    graphics.setFont(font)
    graphics.print(
        text,
        layout.body.x + floor((layout.body.width - font:getWidth(text)) * 0.5),
        layout.body.y + floor((layout.body.height - font:getHeight()) * 0.5) - 1
    )
end

function NativeControls.build_edge_control_layout(bounds, control_layout)
    local panel_gap = 36
    local panel_padding = 6
    local row_height = 24
    local row_gap = 4
    local button_size = 20
    local value_width = 128
    local panel_width = (panel_padding * 2) + button_size + 6 + value_width + 6 + button_size
    local layout = {}

    for index = 1, #control_layout do
        local panel = control_layout[index]
        local panel_rect
        local row_count = #panel.rows
        local panel_height = (panel_padding * 2) + (row_height * row_count) +
            (math.max(0, row_count - 1) * row_gap)

        if panel.side == 'top' then
            panel_rect = {
                x = floor(bounds.x + ((bounds.width - panel_width) * 0.5)),
                y = floor(bounds.y - panel_height - panel_gap),
                width = panel_width,
                height = panel_height,
            }
        elseif panel.side == 'bottom' then
            panel_rect = {
                x = floor(bounds.x + ((bounds.width - panel_width) * 0.5)),
                y = floor(bounds.y + bounds.height + panel_gap),
                width = panel_width,
                height = panel_height,
            }
        elseif panel.side == 'left' then
            panel_rect = {
                x = floor(bounds.x - panel_width - panel_gap),
                y = floor(bounds.y + ((bounds.height - panel_height) * 0.5)),
                width = panel_width,
                height = panel_height,
            }
        else
            panel_rect = {
                x = floor(bounds.x + bounds.width + panel_gap),
                y = floor(bounds.y + ((bounds.height - panel_height) * 0.5)),
                width = panel_width,
                height = panel_height,
            }
        end

        local rows = {}
        for row_index = 1, #panel.rows do
            local row = panel.rows[row_index]
            local row_y = panel_rect.y + panel_padding + ((row_index - 1) * (row_height + row_gap))
            local minus_rect = {
                x = panel_rect.x + panel_padding,
                y = row_y + 2,
                width = button_size,
                height = button_size,
            }
            local plus_rect = {
                x = panel_rect.x + panel_rect.width - panel_padding - button_size,
                y = row_y + 2,
                width = button_size,
                height = button_size,
            }

            rows[#rows + 1] = {
                spec = row,
                minus = minus_rect,
                plus = plus_rect,
                label_x = minus_rect.x + button_size + 8,
                label_y = row_y + 4,
            }
        end

        layout[#layout + 1] = {
            rect = panel_rect,
            rows = rows,
        }
    end

    return layout
end

return NativeControls
