local DemoColors = require('demos.common.colors')
local Hint = require('demos.common.hint')
local CommonScreenHelpers = require('demos.common.screen_helpers')
local UI = require('lib.ui')

local Container = UI.Container

local ScreenHelpers = {
    round = Hint.round,
    format_rect = Hint.format_rect,
    badge = Hint.badge,
    set_hint = Hint.set_hint,
    set_hint_name = Hint.set_hint_name,
}
ScreenHelpers._draw_context = nil

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

local function get_world_quad(node)
    local bounds = node:getLocalBounds()
    local x1, y1 = node:localToWorld(0, 0)
    local x2, y2 = node:localToWorld(bounds.width, 0)
    local x3, y3 = node:localToWorld(bounds.width, bounds.height)
    local x4, y4 = node:localToWorld(0, bounds.height)

    return {
        x1, y1,
        x2, y2,
        x3, y3,
        x4, y4,
    }
end

local function make_text_entry(label, text)
    return {
        label = label,
        badges = {
            Hint.badge(nil, text),
        },
    }
end

function ScreenHelpers.set_inspect_props(node, prop_keys)
    rawset(node, '_demo_inspect_props', prop_keys)
    return node
end

function ScreenHelpers.set_hint_fields(node, fields)
    rawset(node, '_demo_hint_fields', fields)
    return node
end

function ScreenHelpers.set_markers(node, markers)
    rawset(node, '_demo_markers', markers)
    return node
end

local function append_badge_entry(entries, label, keys, source)
    if keys == false or keys == nil then
        return
    end

    local badges = {}
    for index = 1, #keys do
        local key = keys[index]
        badges[#badges + 1] = Hint.badge(key, format_value(source[key]))
    end

    if #badges > 0 then
        entries[#entries + 1] = {
            label = label,
            badges = badges,
        }
    end
end

local function append_grouped_rows(entries, groups, sources)
    if type(groups) ~= 'table' then
        return false
    end

    for index = 1, #groups do
        local group = groups[index]
        local label = group.label
        local source_name = group.source or 'opts'
        local keys = group.keys
        append_badge_entry(entries, label, keys, sources[source_name] or {})
    end

    return #groups > 0
end

function ScreenHelpers.get_hint_entries(node)
    return Hint.resolve_entries(node, function(current)
        local opts = rawget(current, '_demo_opts') or {}
        local local_bounds = current:getLocalBounds()
        local world_bounds = current:getWorldBounds()
        local hint_fields = rawget(current, '_demo_hint_fields') or {}
        local inspect_props = rawget(current, '_demo_inspect_props') or hint_fields.props or { 'x', 'y', 'width', 'height' }
        local sources = {
            opts = opts,
            local_bounds = {
                x = local_bounds.x,
                y = local_bounds.y,
                w = local_bounds.width,
                h = local_bounds.height,
            },
            world_bounds = {
                x = world_bounds.x,
                y = world_bounds.y,
                w = world_bounds.width,
                h = world_bounds.height,
            },
            visible = {
                value = tostring(ScreenHelpers.is_visible(current)),
            },
            clamp = {
                minW = opts.minWidth,
                maxW = opts.maxWidth,
                minH = opts.minHeight,
                maxH = opts.maxHeight,
            },
        }
        local entries = {}

        if not append_grouped_rows(entries, hint_fields.rows, sources) then
            append_badge_entry(entries, 'props', inspect_props, sources.opts)
            append_badge_entry(entries, 'local', hint_fields['local'], sources.local_bounds)
            append_badge_entry(entries, 'world', hint_fields.world, sources.world_bounds)

            if hint_fields.visible == true then
                entries[#entries + 1] = {
                    label = 'visible',
                    badges = {
                        Hint.badge(nil, sources.visible.value),
                    },
                }
            end

            append_badge_entry(entries, 'clamp', hint_fields.clamp, sources.clamp)
        end

        return entries
    end, {
        string_entry_factory = function(text)
            return make_text_entry('info', text)
        end,
    })
end

function ScreenHelpers.draw_hover_overlay(graphics)
    local draw_context = ScreenHelpers._draw_context
    local hovered_node = draw_context and draw_context.hovered_node or nil
    local payload = hovered_node and Hint.resolve_payload(hovered_node, function(current)
        return ScreenHelpers.get_hint_entries(current)
    end, {
        string_entry_factory = function(text)
            return make_text_entry('info', text)
        end,
    }) or nil
    Hint.draw_hover_overlay(graphics, draw_context, payload)
end

function ScreenHelpers.draw_demo_node(graphics, node)
    if not rawget(node, '_demo_box') or not ScreenHelpers.is_visible(node) then
        return
    end

    local draw_context = ScreenHelpers._draw_context
    local bounds = node:getWorldBounds()
    local local_bounds = node:getLocalBounds()
    local quad = get_world_quad(node)
    local label = rawget(node, '_demo_label') or (node.tag or 'container')
    local fill_color = rawget(node, '_demo_fill_color') or DemoColors.rgba(DemoColors.roles.accent_blue_fill, 0.24)
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

    set_color_with_alpha(graphics, fill_color, is_hovered and 1 or 0.75)
    graphics.polygon('fill', quad)
    set_color_with_alpha(graphics, line_color, is_hovered and 1 or 0.75)
    graphics.polygon('line', quad)
    graphics.setColor(DemoColors.roles.body)
    local label_x, label_y = node:localToWorld(
        math.min(8, math.max(0, local_bounds.width - 8)),
        math.min(8, math.max(0, local_bounds.height - 8))
    )
    graphics.print(label, label_x, label_y)
end

local function draw_point_marker(graphics, x, y, color)
    local cross_radius = 4
    local circle_radius = 6

    graphics.setColor(color)
    graphics.circle('line', x, y, circle_radius)
    graphics.line(x - cross_radius, y, x + cross_radius, y)
    graphics.line(x, y - cross_radius, x, y + cross_radius)
end

local function draw_anchor_marker(graphics, node, color)
    if node.parent == nil then
        return
    end

    local parent_bounds = node.parent:getLocalBounds()
    local anchor_x = (node.anchorX or 0) * parent_bounds.width
    local anchor_y = (node.anchorY or 0) * parent_bounds.height
    local world_x, world_y = node.parent:localToWorld(anchor_x, anchor_y)
    draw_point_marker(graphics, world_x, world_y, color)
end

local function draw_pivot_marker(graphics, node, color)
    local bounds = node:getLocalBounds()
    local pivot_x = (node.pivotX or 0) * bounds.width
    local pivot_y = (node.pivotY or 0) * bounds.height
    local world_x, world_y = node:localToWorld(pivot_x, pivot_y)
    draw_point_marker(graphics, world_x, world_y, color)
end

function ScreenHelpers.draw_demo_markers(graphics, node)
    if not rawget(node, '_demo_box') or not ScreenHelpers.is_visible(node) then
        return
    end

    local markers = rawget(node, '_demo_markers')
    if markers == nil then
        return
    end

    for index = 1, #markers do
        local marker = markers[index]
        local marker_type = marker.type
        local color = marker.color or DemoColors.roles.accent_highlight

        if marker_type == 'anchor' then
            draw_anchor_marker(graphics, node, color)
        elseif marker_type == 'pivot' then
            draw_pivot_marker(graphics, node, color)
        end
    end
end

function ScreenHelpers.mark_box(node, label, fill_color, line_color)
    rawset(node, '_demo_box', true)
    rawset(node, '_demo_label', label)
    Hint.set_hint_name(node, label)
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

function ScreenHelpers.screen_wrapper(owner, description, build)
    return CommonScreenHelpers.screen_wrapper(owner, ScreenHelpers, description, build)
end

return ScreenHelpers
