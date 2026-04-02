local DemoColors = require('demos.common.colors')
local Motion = require('lib.ui.motion')
local UI = require('lib.ui')

local Stage = UI.Stage
local Drawable = UI.Drawable

local ScreenHelpers = {}
ScreenHelpers._draw_context = nil
ScreenHelpers._hint_font = nil

function ScreenHelpers.round(value)
    return math.floor((value or 0) + 0.5)
end

function ScreenHelpers.format_rect(rect)
    return string.format(
        'x:%d y:%d w:%d h:%d',
        ScreenHelpers.round(rect.x),
        ScreenHelpers.round(rect.y),
        ScreenHelpers.round(rect.width),
        ScreenHelpers.round(rect.height)
    )
end

function ScreenHelpers.format_insets(insets)
    if insets == nil then
        return 'nil'
    end

    return string.format(
        't:%d r:%d b:%d l:%d',
        ScreenHelpers.round(insets.top),
        ScreenHelpers.round(insets.right),
        ScreenHelpers.round(insets.bottom),
        ScreenHelpers.round(insets.left)
    )
end

function ScreenHelpers.format_scalar(value)
    if type(value) == 'number' then
        return tostring(ScreenHelpers.round(value * 100) / 100)
    end

    if value == nil then
        return 'nil'
    end

    return tostring(value)
end

function ScreenHelpers.is_visible(node)
    local effective_values = rawget(node, '_effective_values')
    return not (effective_values ~= nil and effective_values.visible == false)
end

local function set_color_with_alpha(graphics, color, alpha)
    graphics.setColor(color[1], color[2], color[3], (color[4] or 1) * alpha)
end

local function get_world_quad(node, rect)
    local local_rect = rect or node:getLocalBounds()
    local x1, y1 = node:localToWorld(local_rect.x, local_rect.y)
    local x2, y2 = node:localToWorld(local_rect.x + local_rect.width, local_rect.y)
    local x3, y3 = node:localToWorld(local_rect.x + local_rect.width, local_rect.y + local_rect.height)
    local x4, y4 = node:localToWorld(local_rect.x, local_rect.y + local_rect.height)

    return {
        x1, y1,
        x2, y2,
        x3, y3,
        x4, y4,
    }
end

local function make_badge(key, value)
    return {
        key = key,
        value = value,
    }
end

ScreenHelpers.badge = make_badge

local function normalize_hint_entries(entries)
    local normalized = {}

    for index = 1, #entries do
        local entry = entries[index]
        if type(entry) == 'table' then
            normalized[#normalized + 1] = entry
        end
    end

    return normalized
end

function ScreenHelpers.set_hint(node, hint)
    rawset(node, '_demo_hint', hint)
    return node
end

function ScreenHelpers.set_markers(node, opts)
    rawset(node, '_demo_markers', opts)
    return node
end

function ScreenHelpers.get_hint_entries(node)
    local hint = rawget(node, '_demo_hint')
    if type(hint) == 'function' then
        return normalize_hint_entries(hint(node))
    end

    if type(hint) == 'table' then
        return normalize_hint_entries(hint)
    end

    local content_rect = node:getContentRect()
    local opts = rawget(node, '_demo_opts') or {}

    return {
        {
            label = 'node',
            badges = {
                make_badge('name', rawget(node, '_demo_label') or (node.tag or 'drawable')),
            },
        },
        {
            label = 'props',
            badges = {
                make_badge('x', ScreenHelpers.format_scalar(opts.x)),
                make_badge('y', ScreenHelpers.format_scalar(opts.y)),
                make_badge('width', ScreenHelpers.format_scalar(opts.width)),
                make_badge('height', ScreenHelpers.format_scalar(opts.height)),
            },
        },
        {
            label = 'rect',
            badges = {
                make_badge('content', ScreenHelpers.format_rect(content_rect)),
            },
        },
    }
end

function ScreenHelpers.draw_hover_overlay(graphics)
    local draw_context = ScreenHelpers._draw_context
    if draw_context == nil or draw_context.hovered_node == nil then
        return
    end

    local entries = ScreenHelpers.get_hint_entries(draw_context.hovered_node)
    if entries == nil or #entries == 0 then
        return
    end

    local previous_font = graphics.getFont()
    local font = ScreenHelpers._hint_font or previous_font
    graphics.setFont(font)
    local line_height = font:getHeight()
    local padding = 10
    local gap = 4
    local row_gap = 8
    local badge_padding_x = 4
    local badge_padding_y = 4
    local badge_gap = 4
    local segment_gap = 4
    local label_gap = 10
    local width = 0
    local layout = {}

    for index = 1, #entries do
        local entry = entries[index]
        local label = tostring(entry.label or 'info')
        local label_width = font:getWidth(label .. ':')
        local badges = entry.badges or {}
        local badge_layout = {}
        local badges_width = 0

        for badge_index = 1, #badges do
            local badge = badges[badge_index]
            local key_text = badge.key and (tostring(badge.key) .. ': ') or ''
            local value_text = tostring(badge.value)
            local badge_width = font:getWidth(key_text) + font:getWidth(value_text) + (badge_padding_x * 2)

            badge_layout[#badge_layout + 1] = {
                key_text = key_text,
                value_text = value_text,
                width = badge_width,
            }

            badges_width = badges_width + badge_width
            if badge_index < #badges then
                badges_width = badges_width + badge_gap + segment_gap
            end
        end

        local row_width = label_width + label_gap + badges_width
        width = math.max(width, row_width)
        layout[#layout + 1] = {
            label = label,
            label_width = label_width,
            badges = badge_layout,
        }
    end

    local badge_height = line_height + (badge_padding_y * 2)
    local overlay_width = width + (padding * 2)
    local overlay_height = (#layout * badge_height) + ((math.max(0, #layout - 1)) * row_gap) + (padding * 2)
    local screen_width, screen_height = graphics.getDimensions()
    local x = draw_context.mouse_x + gap
    local y = draw_context.mouse_y + gap

    if x + overlay_width > screen_width - 12 then
        x = draw_context.mouse_x - overlay_width - gap
    end

    if y + overlay_height > screen_height - 12 then
        y = draw_context.mouse_y - overlay_height - gap
    end

    x = math.max(12, x)
    y = math.max(12, y)

    graphics.setColor(DemoColors.roles.surface)
    graphics.rectangle('fill', x, y, overlay_width, overlay_height)
    graphics.setColor(DemoColors.roles.border_light)
    graphics.rectangle('line', x, y, overlay_width, overlay_height)

    local current_y = y + padding
    for index = 1, #layout do
        local row = layout[index]
        local cursor_x = x + padding

        graphics.setColor(DemoColors.roles.accent_highlight)
        graphics.print(row.label .. ':', cursor_x, current_y + badge_padding_y)
        cursor_x = cursor_x + row.label_width + label_gap

        for badge_index = 1, #row.badges do
            local badge = row.badges[badge_index]

            graphics.setColor(DemoColors.roles.surface_emphasis)
            graphics.rectangle('fill', cursor_x, current_y, badge.width, badge_height)
            graphics.setColor(DemoColors.roles.border_light)
            graphics.rectangle('line', cursor_x, current_y, badge.width, badge_height)

            local text_x = cursor_x + badge_padding_x
            local text_y = current_y + badge_padding_y

            if badge.key_text ~= '' then
                graphics.setColor(DemoColors.roles.body_subtle)
                graphics.print(badge.key_text, text_x, text_y)
                text_x = text_x + font:getWidth(badge.key_text)
            end

            graphics.setColor(DemoColors.roles.body)
            graphics.print(badge.value_text, text_x, text_y)

            cursor_x = cursor_x + badge.width
            if badge_index < #row.badges then
                cursor_x = cursor_x + badge_gap + segment_gap
            end
        end

        current_y = current_y + badge_height + row_gap
    end

    graphics.setFont(previous_font)
end

local function draw_rect_outline(graphics, node, rect, color, alpha)
    set_color_with_alpha(graphics, color, alpha or 1)
    graphics.polygon('line', get_world_quad(node, rect))
end

local function draw_rect_fill(graphics, node, rect, color, alpha)
    set_color_with_alpha(graphics, color, alpha or 1)
    graphics.polygon('fill', get_world_quad(node, rect))
end

function ScreenHelpers.draw_demo_node(graphics, node)
    if not rawget(node, '_demo_box') or not ScreenHelpers.is_visible(node) then
        return
    end

    local draw_context = ScreenHelpers._draw_context
    local bounds = node:getWorldBounds()
    local label = rawget(node, '_demo_label') or (node.tag or 'drawable')
    local fill_color = rawget(node, '_demo_fill_color') or DemoColors.rgba(DemoColors.roles.accent_blue_fill, 0.2)
    local line_color = rawget(node, '_demo_line_color') or DemoColors.roles.accent_blue_line
    local is_hovered = false

    if draw_context ~= nil and node:containsPoint(draw_context.mouse_x, draw_context.mouse_y) then
        is_hovered = true
        local area = math.max(1, bounds.width * bounds.height)
        if draw_context.hovered_area == nil or area <= draw_context.hovered_area then
            draw_context.hovered_area = area
            draw_context.hovered_node = node
        end
    end

    local margin = node.margin
    if rawget(node, '_demo_show_margin') and margin ~= nil then
        local expanded = {
            x = -margin.left,
            y = -margin.top,
            width = node.width + margin.left + margin.right,
            height = node.height + margin.top + margin.bottom,
        }
        draw_rect_outline(graphics, node, expanded, DemoColors.roles.accent_highlight, 0.7)
    end

    draw_rect_fill(graphics, node, node:getLocalBounds(), fill_color, is_hovered and 1 or 0.78)
    draw_rect_outline(graphics, node, node:getLocalBounds(), line_color, 1)

    if rawget(node, '_demo_show_content') then
        local content_rect = node:getContentRect()
        draw_rect_fill(graphics, node, content_rect, DemoColors.rgba(DemoColors.roles.accent_amber_fill, 0.2), 1)
        draw_rect_outline(graphics, node, content_rect, DemoColors.roles.accent_amber_line, 1)
    end

    local sample_size = rawget(node, '_demo_sample_size')
    if sample_size ~= nil then
        local resolved = node:resolveContentRect(sample_size.width, sample_size.height)
        draw_rect_fill(graphics, node, resolved, DemoColors.rgba(DemoColors.roles.accent_cyan_fill, 0.35), 1)
        draw_rect_outline(graphics, node, resolved, DemoColors.roles.accent_cyan_line, 1)
    end

    local motion_bar = rawget(node, '_demo_motion_bar')
    if motion_bar == true then
        local opacity = node:_get_motion_value('root', 'opacity') or 0
        local bar_rect = {
            x = 8,
            y = math.max(8, node.height - 18),
            width = math.max(0, (node.width - 16) * opacity),
            height = 8,
        }
        draw_rect_fill(graphics, node, bar_rect, DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.9), 1)
        draw_rect_outline(graphics, node, {
            x = 8,
            y = math.max(8, node.height - 18),
            width = math.max(0, node.width - 16),
            height = 8,
        }, DemoColors.roles.accent_green_line, 0.9)
    end

    graphics.setColor(DemoColors.roles.body)
    local label_x, label_y = node:localToWorld(8, 8)
    graphics.print(label, label_x, label_y)
end

function ScreenHelpers.make_stage(scope)
    local stage = Stage.new({
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight(),
    })

    if ScreenHelpers._hint_font == nil then
        ScreenHelpers._hint_font = love.graphics.newFont(10)
    end

    scope:on_cleanup(function()
        stage:destroy()
    end)

    return stage
end

function ScreenHelpers.mark_box(node, label, fill_color, line_color)
    rawset(node, '_demo_box', true)
    rawset(node, '_demo_label', label)
    rawset(node, '_demo_fill_color', fill_color)
    rawset(node, '_demo_line_color', line_color)
    return node
end

function ScreenHelpers.make_node(scope, parent, opts, label, fill_color, line_color)
    local node = ScreenHelpers.mark_box(Drawable.new(opts), label, fill_color, line_color)
    rawset(node, '_demo_opts', opts)
    parent:addChild(node)

    scope:on_cleanup(function()
        if rawget(node, '_destroyed') ~= true then
            node:destroy()
        end
    end)

    return node
end

function ScreenHelpers.show_content(node, sample_width, sample_height)
    rawset(node, '_demo_show_content', true)
    if sample_width ~= nil and sample_height ~= nil then
        rawset(node, '_demo_sample_size', {
            width = sample_width,
            height = sample_height,
        })
    end
    return node
end

function ScreenHelpers.show_margin(node)
    rawset(node, '_demo_show_margin', true)
    return node
end

function ScreenHelpers.show_motion_bar(node)
    rawset(node, '_demo_motion_bar', true)
    return node
end

function ScreenHelpers.request_motion(node, phase, payload)
    return Motion.request(node, phase, payload or {})
end

function ScreenHelpers.sync_stage(stage)
    stage:resize(love.graphics.getWidth(), love.graphics.getHeight())
    stage:update(0)
end

function ScreenHelpers.screen_wrapper(owner, description, build)
    return function(index, scope)
        local stage = ScreenHelpers.make_stage(scope)
        local state = build(scope, stage)
        local info_index = nil
        local header_description = state.description or description

        if state.sidebar ~= nil then
            info_index = owner:add_info_item(state.sidebar_title or state.title, {})
        end

        owner:set_title(state.title)
        owner:set_description(header_description)

        return {
            keypressed = function(_, key)
                if type(state.keypressed) == 'function' then
                    return state.keypressed(_, key) == true
                end

                return false
            end,
            mousepressed = function(_, x, y, button)
                if type(state.mousepressed) == 'function' then
                    return state.mousepressed(_, x, y, button) == true
                end

                return false
            end,
            update = function(_, dt)
                if type(state.update) == 'function' then
                    state.update(dt)
                end

                stage:resize(love.graphics.getWidth(), love.graphics.getHeight())
                stage:update(dt)
                owner:set_title(state.title)
                owner:set_description(header_description)
                if info_index ~= nil then
                    owner:set_info_title(info_index, state.sidebar_title or state.title)
                    owner:set_info_lines(info_index, state.sidebar(index, owner:get_screen_count()))
                end
            end,
            draw = function()
                if not rawget(stage, '_update_ran') then
                    ScreenHelpers.sync_stage(stage)
                end

                local mouse_x, mouse_y = love.mouse.getPosition()
                ScreenHelpers._draw_context = {
                    mouse_x = mouse_x,
                    mouse_y = mouse_y,
                    hovered_node = nil,
                    hovered_area = nil,
                }

                stage:draw(love.graphics, function(node)
                    ScreenHelpers.draw_demo_node(love.graphics, node)
                end)
                ScreenHelpers.draw_hover_overlay(love.graphics)
                ScreenHelpers._draw_context = nil
            end,
        }
    end
end

return ScreenHelpers
