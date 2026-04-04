local Insets = require('lib.ui.core.insets')

local LayoutSpacing = {}

local function get_node_effective_values(node)
    return rawget(node, '_effective_values') or {}
end

function LayoutSpacing.get_effective_margin(node)
    local effective_values = get_node_effective_values(node)
    return effective_values.margin or Insets.zero()
end

function LayoutSpacing.resolve_axis_margins(margin, main_size_key)
    if main_size_key == 'width' then
        return margin.left, margin.right, margin.top, margin.bottom
    end

    return margin.top, margin.bottom, margin.left, margin.right
end

function LayoutSpacing.get_outer_size(size, leading_margin, trailing_margin)
    return (leading_margin or 0) + (size or 0) + (trailing_margin or 0)
end

function LayoutSpacing.resolve_stack_layout_offset(content_rect, child, margin)
    local effective_values = get_node_effective_values(child)
    local anchor_x = effective_values.anchorX or 0
    local anchor_y = effective_values.anchorY or 0

    return
        content_rect.x + margin.left - ((margin.left + margin.right) * anchor_x),
        content_rect.y + margin.top - ((margin.top + margin.bottom) * anchor_y)
end

function LayoutSpacing.resolve_outer_edges(bounds, margin)
    local left = bounds:left() - margin.left
    local top = bounds:top() - margin.top
    local right = math.max(left, bounds:right() + margin.right)
    local bottom = math.max(top, bounds:bottom() + margin.bottom)

    return left, top, right, bottom
end

return LayoutSpacing
