local DemoColors = require('demos.common.colors')
local LayoutSpacing = require('lib.ui.layout.spacing')

local Visuals = {}

local PADDING_BACKGROUND_COLOR = DemoColors.rgba(DemoColors.roles.accent_amber_fill, 0.2)
local MARGIN_BACKGROUND_COLOR = DemoColors.rgba(DemoColors.roles.accent_violet_fill, 0.2)
local GAP_BACKGROUND_COLOR = DemoColors.rgba(DemoColors.roles.accent_cyan_fill, 0.2)
local PADDING_PATTERN_COLOR = DemoColors.rgba(DemoColors.roles.accent_amber_line, 0.25)
local MARGIN_PATTERN_COLOR = DemoColors.rgba(DemoColors.roles.accent_violet_line, 0.25)
local GAP_PATTERN_COLOR = DemoColors.rgba(DemoColors.roles.accent_cyan_line, 0.25)

local function has_insets(insets)
    return insets ~= nil and
        (insets.top ~= 0 or insets.right ~= 0 or insets.bottom ~= 0 or insets.left ~= 0)
end

local function get_effective_content_rect(node)
    if type(node.getContentRect) == 'function' then
        return node:getContentRect()
    end

    return node:_get_effective_content_rect()
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

local function draw_stripe_fill(graphics, rect, color, step)
    if rect.width <= 0 or rect.height <= 0 then
        return
    end

    local spacing = step or 8
    local start = math.floor(rect.x - rect.height)
    local finish = math.floor(rect.x + rect.width)

    graphics.setScissor(rect.x, rect.y, rect.width, rect.height)
    graphics.setColor(color)

    for x = start, finish, spacing do
        graphics.line(x, rect.y + rect.height, x + rect.height, rect.y)
    end

    graphics.setScissor()
end

local function draw_reverse_stripe_fill(graphics, rect, color, step)
    if rect.width <= 0 or rect.height <= 0 then
        return
    end

    local spacing = step or 8
    local start = math.floor(rect.x - rect.height)
    local finish = math.floor(rect.x + rect.width)

    graphics.setScissor(rect.x, rect.y, rect.width, rect.height)
    graphics.setColor(color)

    for x = start, finish, spacing do
        graphics.line(x, rect.y, x + rect.height, rect.y + rect.height)
    end

    graphics.setScissor()
end

function Visuals.draw_pattern_region(graphics, outer_rect, hole_rects, background_color, pattern_drawer)
    if outer_rect.width <= 0 or outer_rect.height <= 0 then
        return
    end

    graphics.stencil(function()
        graphics.rectangle('fill', outer_rect.x, outer_rect.y, outer_rect.width, outer_rect.height)
    end, 'replace', 1)

    for index = 1, #hole_rects do
        local hole = hole_rects[index]
        if hole.width > 0 and hole.height > 0 then
            graphics.stencil(function()
                graphics.rectangle('fill', hole.x, hole.y, hole.width, hole.height)
            end, 'replace', 0, true)
        end
    end

    graphics.setStencilTest('greater', 0)

    if background_color ~= nil then
        graphics.setColor(background_color)
        graphics.rectangle('fill', outer_rect.x, outer_rect.y, outer_rect.width, outer_rect.height)
    end

    pattern_drawer(outer_rect)
    graphics.setStencilTest()
end

function Visuals.draw_padding_overlay(graphics, node)
    local padding = node.padding or { top = 0, right = 0, bottom = 0, left = 0 }
    if not has_insets(padding) then
        return
    end

    Visuals.draw_pattern_region(
        graphics,
        get_world_rect(node),
        { get_world_rect(node, get_effective_content_rect(node)) },
        PADDING_BACKGROUND_COLOR,
        function(rect)
            draw_stripe_fill(graphics, rect, PADDING_PATTERN_COLOR, 8)
        end
    )
end

function Visuals.draw_margin_overlay(graphics, node)
    local margin = LayoutSpacing.get_effective_margin(node)
    if not has_insets(margin) then
        return
    end

    local bounds = node:getLocalBounds()
    local left, top, right, bottom = LayoutSpacing.resolve_outer_edges(bounds, margin)

    Visuals.draw_pattern_region(
        graphics,
        get_world_rect(node, {
            x = left,
            y = top,
            width = right - left,
            height = bottom - top,
        }),
        { get_world_rect(node) },
        MARGIN_BACKGROUND_COLOR,
        function(rect)
            draw_reverse_stripe_fill(graphics, rect, MARGIN_PATTERN_COLOR, 8)
        end
    )
end

function Visuals.draw_row_gap_overlay(graphics, parent)
    local effective_values = rawget(parent, '_effective_values') or {}
    local gap = effective_values.gap or 0
    local children = rawget(parent, '_children') or {}
    local content_rect = get_world_rect(parent, parent:_get_effective_content_rect())
    local previous_outer_right = nil

    if gap <= 0 then
        return
    end

    for index = 1, #children do
        local child = children[index]
        local child_effective = rawget(child, '_effective_values') or {}

        if child_effective.visible ~= false then
            local margin = LayoutSpacing.get_effective_margin(child)
            local bounds = child:getLocalBounds()
            local left, _, right = LayoutSpacing.resolve_outer_edges(bounds, margin)
            local outer_rect = get_world_rect(child, {
                x = left,
                y = bounds.y - margin.top,
                width = right - left,
                height = bounds.height + margin.top + margin.bottom,
            })

            if previous_outer_right ~= nil then
                local gap_width = outer_rect.x - previous_outer_right

                if gap_width > 0 then
                    Visuals.draw_pattern_region(
                        graphics,
                        {
                            x = previous_outer_right,
                            y = content_rect.y,
                            width = gap_width,
                            height = content_rect.height,
                        },
                        {},
                        GAP_BACKGROUND_COLOR,
                        function(rect)
                            draw_stripe_fill(graphics, rect, GAP_PATTERN_COLOR, 8)
                        end
                    )
                end
            end

            previous_outer_right = outer_rect.x + outer_rect.width
        end
    end
end

function Visuals.draw_column_gap_overlay(graphics, parent)
    local effective_values = rawget(parent, '_effective_values') or {}
    local gap = effective_values.gap or 0
    local children = rawget(parent, '_children') or {}
    local content_rect = get_world_rect(parent, parent:_get_effective_content_rect())
    local previous_outer_bottom = nil

    if gap <= 0 then
        return
    end

    for index = 1, #children do
        local child = children[index]
        local child_effective = rawget(child, '_effective_values') or {}

        if child_effective.visible ~= false then
            local margin = LayoutSpacing.get_effective_margin(child)
            local bounds = child:getLocalBounds()
            local _, top, _, bottom = LayoutSpacing.resolve_outer_edges(bounds, margin)
            local outer_rect = get_world_rect(child, {
                x = bounds.x - margin.left,
                y = top,
                width = bounds.width + margin.left + margin.right,
                height = bottom - top,
            })

            if previous_outer_bottom ~= nil then
                local gap_height = outer_rect.y - previous_outer_bottom

                if gap_height > 0 then
                    Visuals.draw_pattern_region(
                        graphics,
                        {
                            x = content_rect.x,
                            y = previous_outer_bottom,
                            width = content_rect.width,
                            height = gap_height,
                        },
                        {},
                        GAP_BACKGROUND_COLOR,
                        function(rect)
                            draw_stripe_fill(graphics, rect, GAP_PATTERN_COLOR, 8)
                        end
                    )
                end
            end

            previous_outer_bottom = outer_rect.y + outer_rect.height
        end
    end
end

function Visuals.draw_hovered_overlays(graphics, hovered_node, opts)
    local parent = opts.parent
    local children = opts.children or {}
    local show_row_gap = opts.show_row_gap == true
    local show_column_gap = opts.show_column_gap == true

    if hovered_node == nil then
        return
    end

    if hovered_node == parent then
        Visuals.draw_padding_overlay(graphics, parent)

        if show_row_gap then
            Visuals.draw_row_gap_overlay(graphics, parent)
        end

        if show_column_gap then
            Visuals.draw_column_gap_overlay(graphics, parent)
        end

        return
    end

    for index = 1, #children do
        local child = children[index]
        if hovered_node == child then
            Visuals.draw_margin_overlay(graphics, child)
            Visuals.draw_padding_overlay(graphics, child)
            return
        end
    end
end

return Visuals
