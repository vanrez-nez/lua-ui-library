local DemoColors = require('demos.common.colors')
local Hint = require('demos.common.hint')
local ScreenHelper = require('demos.common.screen_helper')
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

local function get_world_rect(node, rect)
    local local_rect = rect or node:getLocalBounds()
    local x, y = node:localToWorld(local_rect.x, local_rect.y)

    return {
        x = x,
        y = y,
        width = local_rect.width,
        height = local_rect.height,
    }
end

local function get_effective_content_rect(node)
    if type(node.getContentRect) == 'function' then
        return node:getContentRect()
    end

    return node:_get_effective_content_rect()
end

local function apply_box_style(node, fill_color, line_color)
    node.backgroundColor = fill_color
    node.borderColor = line_color
    node.borderWidth = 1
    return node
end

local function ensure_overlay(node, key, opts)
    local overlay = rawget(node, key)
    if overlay ~= nil and not rawget(overlay, '_destroyed') then
        return overlay
    end

    local parent = rawget(node, 'parent')
    if parent == nil then
        error('demo overlay requires an attached parent node', 2)
    end

    overlay = Drawable.new({
        internal = true,
        enabled = false,
        x = 0,
        y = 0,
        width = 0,
        height = 0,
        backgroundColor = opts.backgroundColor,
        borderColor = opts.borderColor,
        borderWidth = opts.borderWidth or 1,
    })
    rawset(overlay, '_demo_overlay', true)
    parent:addChild(overlay)
    rawset(node, key, overlay)
    return overlay
end

local function set_overlay_rect(overlay, world_rect)
    local parent = rawget(overlay, 'parent')
    local x = world_rect.x
    local y = world_rect.y

    if parent ~= nil then
        x, y = parent:worldToLocal(world_rect.x, world_rect.y)
    end

    overlay.x = x
    overlay.y = y
    overlay.width = world_rect.width
    overlay.height = world_rect.height
    overlay:_refresh_if_dirty()
end

local function sync_content_overlay(node)
    local overlay = rawget(node, '_demo_content_overlay')
    if overlay == nil then
        return
    end

    set_overlay_rect(overlay, get_world_rect(node, get_effective_content_rect(node)))
end

local function sync_bounds_overlay(node)
    local overlay = rawget(node, '_demo_bounds_overlay')
    if overlay == nil then
        return
    end

    set_overlay_rect(overlay, get_world_rect(node))
end

local function sync_sample_overlay(node)
    local overlay = rawget(node, '_demo_sample_overlay')
    local sample_size = rawget(node, '_demo_sample_size')
    if overlay == nil or sample_size == nil then
        return
    end

    local resolved = node:resolveContentRect(sample_size.width, sample_size.height)
    set_overlay_rect(overlay, get_world_rect(node, resolved))
end

local function sync_margin_overlay(node)
    local overlay = rawget(node, '_demo_margin_overlay')
    if overlay == nil then
        return
    end

    local margin = node.margin or { top = 0, right = 0, bottom = 0, left = 0 }
    local bounds = node:getLocalBounds()
    set_overlay_rect(overlay, get_world_rect(node, {
        x = -margin.left,
        y = -margin.top,
        width = bounds.width + margin.left + margin.right,
        height = bounds.height + margin.top + margin.bottom,
    }))
end

local function sync_motion_overlays(node)
    local track = rawget(node, '_demo_motion_track_overlay')
    local fill = rawget(node, '_demo_motion_fill_overlay')
    if track == nil or fill == nil then
        return
    end

    local bounds = node:getLocalBounds()
    local track_rect = {
        x = 8,
        y = math.max(8, bounds.height - 18),
        width = math.max(0, bounds.width - 16),
        height = 8,
    }
    local opacity = node:_get_motion_value('root', 'opacity') or 0
    local fill_rect = {
        x = 8,
        y = math.max(8, bounds.height - 18),
        width = math.max(0, (bounds.width - 16) * opacity),
        height = 8,
    }

    set_overlay_rect(track, get_world_rect(node, track_rect))
    set_overlay_rect(fill, get_world_rect(node, fill_rect))
end

local function sync_node_visuals(node)
    if rawget(node, '_demo_overlay') == true or rawget(node, '_destroyed') then
        return
    end

    sync_bounds_overlay(node)
    sync_content_overlay(node)
    sync_sample_overlay(node)
    sync_margin_overlay(node)
    sync_motion_overlays(node)
end

local function sync_subtree(node)
    sync_node_visuals(node)

    local children = rawget(node, '_children') or {}
    for index = 1, #children do
        sync_subtree(children[index])
    end
end

function ScreenHelpers.set_markers(node, opts)
    rawset(node, '_demo_markers', opts)
    return node
end

function ScreenHelpers.get_hint_entries(node)
    return Hint.resolve_entries(node, function(current)
        local content_rect = get_effective_content_rect(current)
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

function ScreenHelpers.draw_demo_node(graphics, node)
    if rawget(node, '_demo_overlay') == true or
        rawget(node, '_demo_label') == nil or
        not ScreenHelpers.is_visible(node) then
        return
    end

    local draw_context = ScreenHelpers._draw_context
    local bounds = node:getWorldBounds()
    local label = rawget(node, '_demo_label') or (node.tag or 'drawable')
    local label_rect_mode = rawget(node, '_demo_label_rect') or 'bounds'
    local label_inset_x = rawget(node, '_demo_label_inset_x') or 8
    local label_inset_y = rawget(node, '_demo_label_inset_y') or 8
    local is_hovered = false

    if draw_context ~= nil and node:containsPoint(draw_context.mouse_x, draw_context.mouse_y) then
        is_hovered = true
        local area = math.max(1, bounds.width * bounds.height)
        if draw_context.hovered_area == nil or area <= draw_context.hovered_area then
            draw_context.hovered_area = area
            draw_context.hovered_node = node
        end
    end

    graphics.setColor(DemoColors.roles.body)
    local label_rect = node:getLocalBounds()
    if label_rect_mode == 'content' then
        label_rect = get_effective_content_rect(node)
    end
    local label_x, label_y = node:localToWorld(
        label_rect.x + label_inset_x,
        label_rect.y + label_inset_y
    )
    graphics.print(label, label_x, label_y)
end

function ScreenHelpers.mark_box(node, label, fill_color, line_color)
    rawset(node, '_demo_label', label)
    Hint.set_hint_name(node, label)
    return apply_box_style(node, fill_color, line_color)
end

function ScreenHelpers.make_node(scope, parent, opts, label, fill_color, line_color)
    local node = ScreenHelpers.mark_box(Drawable.new(opts), label, fill_color, line_color)
    rawset(node, '_demo_opts', opts)
    parent:addChild(node)

    return node
end

function ScreenHelpers.show_content(node, sample_width, sample_height)
    ensure_overlay(node, '_demo_content_overlay', {
        backgroundColor = DemoColors.rgba(DemoColors.roles.accent_amber_fill, 0.2),
        borderColor = DemoColors.roles.accent_amber_line,
        borderWidth = 1,
    })
    if sample_width ~= nil and sample_height ~= nil then
        rawset(node, '_demo_sample_size', {
            width = sample_width,
            height = sample_height,
        })
        ensure_overlay(node, '_demo_sample_overlay', {
            backgroundColor = DemoColors.rgba(DemoColors.roles.accent_cyan_fill, 0.35),
            borderColor = DemoColors.roles.accent_cyan_line,
            borderWidth = 1,
        })
    end
end

function ScreenHelpers.show_bounds(node)
    ensure_overlay(node, '_demo_bounds_overlay', {
        backgroundColor = { 184, 191, 207, 18 },
        borderColor = { 184, 191, 207 },
        borderWidth = 1,
        borderStyle = 'rough',
    })
end

function ScreenHelpers.show_margin(node)
    ensure_overlay(node, '_demo_margin_overlay', {
        backgroundColor = nil,
        borderColor = DemoColors.roles.accent_gold_line,
        borderWidth = 1,
    })
end

function ScreenHelpers.show_motion_track(node)
    ensure_overlay(node, '_demo_motion_track_overlay', {
        backgroundColor = DemoColors.rgba(DemoColors.roles.surface, 0.9),
        borderColor = DemoColors.roles.body,
        borderWidth = 1,
    })
    ensure_overlay(node, '_demo_motion_fill_overlay', {
        backgroundColor = DemoColors.roles.accent_cyan_fill,
        borderColor = DemoColors.roles.accent_cyan_line,
        borderWidth = 1,
    })
end

function ScreenHelpers.sync_stage_visuals(stage)
    sync_subtree(stage.baseSceneLayer)
    sync_subtree(stage.overlayLayer)
end

function ScreenHelpers.draw_demo_markers(graphics, node)
    local markers = rawget(node, '_demo_markers')
    if markers == nil or not ScreenHelpers.is_visible(node) then
        return
    end

    local bounds = node:getWorldBounds()
    local marker_x = bounds.x + bounds.width - 10
    local marker_y = bounds.y + 10

    if markers.motion then
        graphics.setColor(DemoColors.roles.accent_cyan_line)
        graphics.circle('fill', marker_x, marker_y, 4)
        marker_x = marker_x - 12
    end

    if markers.effect then
        graphics.setColor(DemoColors.roles.accent_gold_line)
        graphics.rectangle('fill', marker_x - 4, marker_y - 4, 8, 8)
    end
end

function ScreenHelpers.screen_wrapper(owner, build)
    return ScreenHelper.screen_wrapper(owner, ScreenHelpers, build)
end

return ScreenHelpers
