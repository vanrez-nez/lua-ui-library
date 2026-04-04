local DemoColors = require('demos.common.colors')

local NativeControls = {}

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

function NativeControls.draw_button(graphics, font, rect, label, hovered)
    NativeControls.draw_rect(
        graphics,
        rect,
        'fill',
        hovered and DemoColors.roles.surface_emphasis or DemoColors.roles.surface_interactive
    )
    NativeControls.draw_rect(graphics, rect, 'line', DemoColors.roles.border_light)

    graphics.setColor(DemoColors.roles.text)
    graphics.setFont(font)
    graphics.print(
        label,
        rect.x + floor((rect.width - font:getWidth(label)) * 0.5),
        rect.y + floor((rect.height - font:getHeight()) * 0.5) - 1
    )
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
