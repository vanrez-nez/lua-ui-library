local DemoColors = require('demos.common.colors')

local Hint = {}
Hint._font = nil

function Hint.round(value)
    return math.floor((value or 0) + 0.5)
end

function Hint.format_rect(rect)
    return string.format(
        'x:%d y:%d w:%d h:%d',
        Hint.round(rect.x),
        Hint.round(rect.y),
        Hint.round(rect.width),
        Hint.round(rect.height)
    )
end

function Hint.format_insets(insets)
    if insets == nil then
        return 'nil'
    end

    return string.format(
        't:%d r:%d b:%d l:%d',
        Hint.round(insets.top),
        Hint.round(insets.right),
        Hint.round(insets.bottom),
        Hint.round(insets.left)
    )
end

function Hint.format_scalar(value)
    if type(value) == 'number' then
        return tostring(Hint.round(value * 100) / 100)
    end

    if value == nil then
        return 'nil'
    end

    return tostring(value)
end

function Hint.badge(key, value)
    return {
        key = key,
        value = value,
    }
end

local function join_label(prefix, suffix)
    local left = prefix and tostring(prefix) or ''
    local right = suffix and tostring(suffix) or ''

    if left == '' then
        return right
    end

    if right == '' then
        return left
    end

    return left .. '.' .. right
end

local function sorted_keys(value)
    local keys = {}

    for key in pairs(value) do
        keys[#keys + 1] = key
    end

    table.sort(keys, function(left, right)
        if type(left) == type(right) then
            return tostring(left) < tostring(right)
        end

        return type(left) < type(right)
    end)

    return keys
end

local function flatten_badge_value(row_label, badge_key, value, flattened)
    if type(value) ~= 'table' then
        flattened[#flattened + 1] = {
            label = join_label(row_label, badge_key),
            badges = {
                Hint.badge(nil, Hint.format_scalar(value)),
            },
        }
        return
    end

    for _, child_key in ipairs(sorted_keys(value)) do
        flatten_badge_value(join_label(row_label, badge_key), child_key, value[child_key], flattened)
    end
end

local function normalize_entry(entry)
    if type(entry) ~= 'table' then
        return {}
    end

    local badges = entry.badges or {}
    local normalized = {}
    local inline_badges = {}

    for index = 1, #badges do
        local badge = badges[index]
        local value = badge and badge.value or nil

        if type(value) == 'table' then
            if #inline_badges > 0 then
                normalized[#normalized + 1] = {
                    label = entry.label,
                    badges = inline_badges,
                }
                inline_badges = {}
            end

            local flattened = {}
            flatten_badge_value(entry.label, badge.key, value, flattened)
            for flattened_index = 1, #flattened do
                normalized[#normalized + 1] = flattened[flattened_index]
            end
        else
            inline_badges[#inline_badges + 1] = {
                key = badge and badge.key or nil,
                value = Hint.format_scalar(value),
            }
        end
    end

    if #inline_badges > 0 or #normalized == 0 then
        normalized[#normalized + 1] = {
            label = entry.label,
            badges = inline_badges,
        }
    end

    return normalized
end

local function get_font(graphics)
    if Hint._font == nil then
        Hint._font = love.graphics.newFont(10)
    end

    return Hint._font or graphics.getFont()
end

local function assert_unique_labels(entries)
    local seen = {}

    for index = 1, #entries do
        local entry = entries[index]
        local label = tostring(entry.label or 'info')

        if seen[label] then
            error(string.format('Hint labels must be unique; duplicate label "%s"', label), 3)
        end

        seen[label] = true
    end
end

function Hint.normalize_entries(entries, string_entry_factory)
    local normalized = {}

    for index = 1, #entries do
        local entry = entries[index]

        if type(entry) == 'string' then
            if type(string_entry_factory) == 'function' then
                normalized[#normalized + 1] = string_entry_factory(entry)
            end
        elseif type(entry) == 'table' then
            local normalized_entries = normalize_entry(entry)
            for normalized_index = 1, #normalized_entries do
                normalized[#normalized + 1] = normalized_entries[normalized_index]
            end
        end
    end

    assert_unique_labels(normalized)
    return normalized
end

function Hint.set_hint(node, hint)
    rawset(node, '_demo_hint', hint)
    return node
end

function Hint.set_hint_name(node, name)
    rawset(node, '_demo_hint_name', name)
    return node
end

local function normalize_payload(payload, string_entry_factory)
    if type(payload) == 'table' and (payload.entries ~= nil or payload.name ~= nil) then
        return {
            name = payload.name,
            entries = Hint.normalize_entries(payload.entries, string_entry_factory),
        }
    end

    return {
        name = nil,
        entries = Hint.normalize_entries(payload, string_entry_factory),
    }
end

function Hint.resolve_payload(node, fallback_entries, opts)
    local hint = rawget(node, '_demo_hint')
    local string_entry_factory = opts and opts.string_entry_factory
    local default_name = rawget(node, '_demo_hint_name') or rawget(node, '_demo_label') or node.tag or 'node'

    if type(hint) == 'function' then
        local payload = normalize_payload(hint(node), string_entry_factory)
        if payload.name == nil then
            payload.name = default_name
        end
        return payload
    end

    if type(hint) == 'table' then
        local payload = normalize_payload(hint, string_entry_factory)
        if payload.name == nil then
            payload.name = default_name
        end
        return payload
    end

    local fallback_payload = {}
    if type(fallback_entries) == 'function' then
        fallback_payload = fallback_entries(node)
    elseif type(fallback_entries) == 'table' then
        fallback_payload = fallback_entries
    end

    if type(fallback_payload) == 'table' and (fallback_payload.entries ~= nil or fallback_payload.name ~= nil) then
        local payload = {
            name = fallback_payload.name,
            entries = fallback_payload.entries or {},
        }
        if payload.name == nil then
            payload.name = default_name
        end
        return payload
    end

    return {
        name = default_name,
        entries = fallback_payload or {},
    }
end

function Hint.resolve_entries(node, fallback_entries, opts)
    return Hint.resolve_payload(node, fallback_entries, opts).entries
end

function Hint.draw_hover_overlay(graphics, draw_context, payload)
    if draw_context == nil or draw_context.hovered_node == nil then
        return
    end

    local name = nil
    local entries = payload
    if type(payload) == 'table' and payload.entries ~= nil then
        name = payload.name
        entries = payload.entries
    end

    if name == nil or name == '' then
        name = 'node'
    end

    local rows = {
        {
            label = 'node',
            badges = {
                Hint.badge(nil, Hint.format_scalar(name)),
            },
        },
    }

    if entries == nil or #entries == 0 then
        entries = {}
    end

    for index = 1, #entries do
        rows[#rows + 1] = entries[index]
    end

    assert_unique_labels(rows)

    local previous_font = graphics.getFont()
    local font = get_font(graphics)
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

    for index = 1, #rows do
        local entry = rows[index]
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

return Hint
