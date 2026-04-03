local DemoColors = require('demos.common.colors')
local Hint = require('demos.common.hint')
local CommonScreenHelpers = require('demos.common.screen_helpers')
local Motion = require('lib.ui.motion')
local UI = require('lib.ui')

local Drawable = UI.Drawable

local ScreenHelpers = {
    round = Hint.round,
    format_rect = Hint.format_rect,
    format_insets = Hint.format_insets,
    format_scalar = Hint.format_scalar,
    badge = Hint.badge,
    set_hint = Hint.set_hint,
    set_hint_name = Hint.set_hint_name,
}
ScreenHelpers._draw_context = nil

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

function ScreenHelpers.set_markers(node, opts)
    rawset(node, '_demo_markers', opts)
    return node
end

function ScreenHelpers.get_hint_entries(node)
    return Hint.resolve_entries(node, function(current)
        local content_rect = current:getContentRect()
        local opts = rawget(current, '_demo_opts') or {}

        return {
            {
                label = 'position',
                badges = {
                    Hint.badge('x', Hint.format_scalar(opts.x)),
                    Hint.badge('y', Hint.format_scalar(opts.y)),
                },
            },
            {
                label = 'dimensions',
                badges = {
                    Hint.badge('width', Hint.format_scalar(opts.width)),
                    Hint.badge('height', Hint.format_scalar(opts.height)),
                },
            },
            {
                label = 'rect.content',
                badges = {
                    Hint.badge('content', Hint.format_rect(content_rect)),
                },
            },
        }
    end)
end

function ScreenHelpers.draw_hover_overlay(graphics)
    local draw_context = ScreenHelpers._draw_context
    local hovered_node = draw_context and draw_context.hovered_node or nil
    local payload = hovered_node and Hint.resolve_payload(hovered_node, function(current)
        return ScreenHelpers.get_hint_entries(current)
    end) or nil
    Hint.draw_hover_overlay(graphics, draw_context, payload)
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
    local outline_only = rawget(node, '_demo_outline_only') == true
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

    if not outline_only then
        draw_rect_fill(graphics, node, node:getLocalBounds(), fill_color, is_hovered and 1 or 0.78)
    end
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

function ScreenHelpers.mark_box(node, label, fill_color, line_color)
    rawset(node, '_demo_box', true)
    rawset(node, '_demo_label', label)
    Hint.set_hint_name(node, label)
    rawset(node, '_demo_fill_color', fill_color)
    rawset(node, '_demo_line_color', line_color)
    return node
end

function ScreenHelpers.make_node(scope, parent, opts, label, fill_color, line_color)
    local node = ScreenHelpers.mark_box(Drawable.new(opts), label, fill_color, line_color)
    rawset(node, '_demo_opts', opts)
    parent:addChild(node)

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

function ScreenHelpers.show_outline_only(node)
    rawset(node, '_demo_outline_only', true)
    return node
end

function ScreenHelpers.request_motion(node, phase, payload)
    return Motion.request(node, phase, payload or {})
end

function ScreenHelpers.screen_wrapper(owner, description, build)
    return CommonScreenHelpers.screen_wrapper(owner, ScreenHelpers, description, build)
end

return ScreenHelpers
