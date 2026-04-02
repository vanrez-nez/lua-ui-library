local DemoColors = require('demos.common.colors')
local UI = require('lib.ui')

local Stage = UI.Stage
local Container = UI.Container

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

local function random_range(minimum, maximum)
    if maximum <= minimum then
        return minimum
    end

    return love.math.random(minimum, maximum)
end

function ScreenHelpers.random_root_position(width, height, margin)
    local viewport_width = love.graphics.getWidth()
    local viewport_height = love.graphics.getHeight()
    local inset = margin or 96
    local max_x = math.max(inset, viewport_width - width - inset)
    local max_y = math.max(inset, viewport_height - height - inset - 72)

    return {
        x = random_range(inset, max_x),
        y = random_range(inset, max_y),
    }
end

function ScreenHelpers.make_size_pulse(node, base_width, base_height, width_amplitude, height_amplitude, speed)
    local phase = love.math.random() * (math.pi * 2)
    local pulse_speed = speed or 1.2
    local pulse_width = width_amplitude or 24
    local pulse_height = height_amplitude or 18

    return function(dt)
        local resolved_width = base_width
        local resolved_height = base_height

        if type(base_width) == 'function' then
            resolved_width = base_width()
        end

        if type(base_height) == 'function' then
            resolved_height = base_height()
        end

        phase = phase + (dt * pulse_speed)
        node.width = ScreenHelpers.round(resolved_width + (math.sin(phase) * pulse_width))
        node.height = ScreenHelpers.round(resolved_height + (math.cos(phase) * pulse_height))
    end
end

function ScreenHelpers.is_visible(node)
    local effective_values = rawget(node, '_effective_values')
    return not (effective_values ~= nil and effective_values.visible == false)
end

local function format_value(value)
    if value == nil then
        return 'nil'
    end

    if type(value) == 'number' then
        return tostring(ScreenHelpers.round(value))
    end

    return tostring(value)
end

local function point_in_rect(x, y, rect)
    return x >= rect.x and y >= rect.y and x <= (rect.x + rect.width) and y <= (rect.y + rect.height)
end

local function set_color_with_alpha(graphics, color, alpha)
    graphics.setColor(color[1], color[2], color[3], (color[4] or 1) * alpha)
end

local function make_badge(key, value)
    return {
        key = key,
        value = value,
    }
end

ScreenHelpers.badge = make_badge

local function make_text_entry(label, text)
    return {
        label = label,
        badges = {
            make_badge(nil, text),
        },
    }
end

local function normalize_hint_entries(entries)
    local normalized = {}

    for index = 1, #entries do
        local entry = entries[index]

        if type(entry) == 'string' then
            normalized[#normalized + 1] = make_text_entry('info', entry)
        else
            normalized[#normalized + 1] = entry
        end
    end

    return normalized
end

function ScreenHelpers.set_hint(node, hint)
    rawset(node, '_demo_hint', hint)
    return node
end

function ScreenHelpers.set_inspect_props(node, prop_keys)
    rawset(node, '_demo_inspect_props', prop_keys)
    return node
end

function ScreenHelpers.set_hint_fields(node, fields)
    rawset(node, '_demo_hint_fields', fields)
    return node
end

local function append_badge_entry(entries, label, keys, source)
    if keys == false or keys == nil then
        return
    end

    local badges = {}
    for index = 1, #keys do
        local key = keys[index]
        badges[#badges + 1] = make_badge(key, format_value(source[key]))
    end

    if #badges > 0 then
        entries[#entries + 1] = {
            label = label,
            badges = badges,
        }
    end
end

function ScreenHelpers.get_hint_entries(node)
    local hint = rawget(node, '_demo_hint')
    if type(hint) == 'function' then
        return normalize_hint_entries(hint(node))
    end

    if type(hint) == 'table' then
        return normalize_hint_entries(hint)
    end

    local opts = rawget(node, '_demo_opts') or {}
    local local_bounds = node:getLocalBounds()
    local world_bounds = node:getWorldBounds()
    local hint_fields = rawget(node, '_demo_hint_fields') or {}
    local inspect_props = rawget(node, '_demo_inspect_props') or hint_fields.props or { 'x', 'y', 'width', 'height' }
    local entries = {
        {
            label = 'node',
            badges = {
                make_badge(nil, rawget(node, '_demo_label') or (node.tag or 'container')),
            },
        },
    }

    append_badge_entry(entries, 'props', inspect_props, opts)
    append_badge_entry(entries, 'local', hint_fields['local'], {
        x = local_bounds.x,
        y = local_bounds.y,
        w = local_bounds.width,
        h = local_bounds.height,
    })
    append_badge_entry(entries, 'world', hint_fields.world, {
        x = world_bounds.x,
        y = world_bounds.y,
        w = world_bounds.width,
        h = world_bounds.height,
    })

    if hint_fields.visible == true then
        entries[#entries + 1] = {
            label = 'visible',
            badges = {
                make_badge(nil, tostring(ScreenHelpers.is_visible(node))),
            },
        }
    end

    append_badge_entry(entries, 'clamp', hint_fields.clamp, {
        minW = opts.minWidth,
        maxW = opts.maxWidth,
        minH = opts.minHeight,
        maxH = opts.maxHeight,
    })

    return entries
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
            row_width = row_width,
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

function ScreenHelpers.draw_demo_node(graphics, node)
    if not rawget(node, '_demo_box') or not ScreenHelpers.is_visible(node) then
        return
    end

    local draw_context = ScreenHelpers._draw_context
    local bounds = node:getWorldBounds()
    local label = rawget(node, '_demo_label') or (node.tag or 'container')
    local fill_color = rawget(node, '_demo_fill_color') or DemoColors.rgba(DemoColors.roles.accent_blue_fill, 0.24)
    local line_color = rawget(node, '_demo_line_color') or DemoColors.roles.accent_blue_line
    local is_hovered = false

    if draw_context ~= nil and point_in_rect(draw_context.mouse_x, draw_context.mouse_y, bounds) then
        is_hovered = true

        local area = math.max(1, bounds.width * bounds.height)
        if draw_context.hovered_area == nil or area <= draw_context.hovered_area then
            draw_context.hovered_area = area
            draw_context.hovered_node = node
        end
    end

    set_color_with_alpha(graphics, fill_color, is_hovered and 1 or 0.75)
    graphics.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height)
    set_color_with_alpha(graphics, line_color, is_hovered and 1 or 0.75)
    graphics.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height)
    graphics.setColor(DemoColors.roles.body)
    graphics.print(label, bounds.x + 8, bounds.y + 8)
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
    local node = ScreenHelpers.mark_box(Container.new(opts), label, fill_color, line_color)
    rawset(node, '_demo_opts', opts)
    parent:addChild(node)

    scope:on_cleanup(function()
        if rawget(node, '_destroyed') ~= true then
            node:destroy()
        end
    end)

    return node
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
