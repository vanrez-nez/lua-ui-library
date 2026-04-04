local LayoutSpacingVisuals = require('demos.common.layout_spacing_visuals')

local Setup = {}

local function find_required(root, id)
    local node = root:findById(id, -1)
    if node == nil then
        error('layout_row_setup: missing node "' .. id .. '"', 2)
    end
    return node
end

local function has_insets(insets)
    return insets ~= nil and
        (insets.top ~= 0 or insets.right ~= 0 or insets.bottom ~= 0 or insets.left ~= 0)
end

local function append_inset_row(entries, helpers, label, insets)
    if not has_insets(insets) then
        return
    end

    entries[#entries + 1] = {
        label = label,
        badges = {
            helpers.badge('left', helpers.format_scalar(insets.left)),
            helpers.badge('top', helpers.format_scalar(insets.top)),
            helpers.badge('right', helpers.format_scalar(insets.right)),
            helpers.badge('bottom', helpers.format_scalar(insets.bottom)),
        },
    }
end

local function append_rect_row(entries, helpers, label, rect)
    entries[#entries + 1] = {
        label = label,
        badges = {
            helpers.badge('x', helpers.format_scalar(rect.x)),
            helpers.badge('y', helpers.format_scalar(rect.y)),
            helpers.badge('width', helpers.format_scalar(rect.width)),
            helpers.badge('height', helpers.format_scalar(rect.height)),
        },
    }
end

local function set_parent_hint(node, helpers)
    helpers.set_hint(node, function(current)
        local entries = {
            {
                label = 'type',
                badges = {
                    helpers.badge(nil, 'Row'),
                },
            },
        }

        append_rect_row(entries, helpers, 'parent.container', current:getLocalBounds())
        append_rect_row(entries, helpers, 'parent.content', current:_get_effective_content_rect())
        entries[#entries + 1] = {
            label = 'layout',
            badges = {
                helpers.badge('justify', current.justify or 'start'),
                helpers.badge('align', current.align or 'start'),
                helpers.badge('gap', helpers.format_scalar(current.gap or 0)),
                helpers.badge('direction', current.direction or 'ltr'),
            },
        }
        append_inset_row(entries, helpers, 'padding', current.padding)

        return entries
    end)
end

local function set_child_hint(node, helpers)
    helpers.set_hint(node, function(current)
        local entries = {
            {
                label = 'type',
                badges = {
                    helpers.badge(nil, 'Drawable'),
                },
            },
            {
                label = 'position',
                badges = {
                    helpers.badge('x', helpers.format_scalar(current.x or 0)),
                    helpers.badge('y', helpers.format_scalar(current.y or 0)),
                    helpers.badge('zIndex', helpers.format_scalar(current.zIndex or 0)),
                },
            },
        }

        append_rect_row(entries, helpers, 'child.container', current:getLocalBounds())
        append_rect_row(entries, helpers, 'child.content', current:getContentRect())
        append_inset_row(entries, helpers, 'padding', current.padding)
        append_inset_row(entries, helpers, 'margin', current.margin)

        return entries
    end)
end

function Setup.install(args)
    local helpers = args.helpers
    local root = args.root
    local scope = args.scope
    local stage = args.stage
    local title_font = scope:font(12)
    local parent = find_required(root, 'layout-row-parent')
    local leading = find_required(root, 'layout-row-leading')
    local content = find_required(root, 'layout-row-content')
    local action = find_required(root, 'layout-row-action')

    rawset(parent, '_demo_label', '')
    helpers.set_hint_name(parent, 'parent')
    set_parent_hint(parent, helpers)
    helpers.show_bounds(parent)

    local parent_bounds_overlay = rawget(parent, '_demo_bounds_overlay')
    parent_bounds_overlay.borderStyle = 'rough'
    parent_bounds_overlay.borderPattern = 'dashed'
    parent_bounds_overlay.borderDashLength = 8
    parent_bounds_overlay.borderGapLength = 6

    rawset(leading, '_demo_label', 'Leading')
    rawset(leading, '_demo_label_rect', 'content')
    rawset(leading, '_demo_label_inset_x', 10)
    rawset(leading, '_demo_label_inset_y', 10)
    helpers.set_hint_name(leading, 'child')
    set_child_hint(leading, helpers)

    rawset(content, '_demo_label', 'Content')
    rawset(content, '_demo_label_rect', 'content')
    rawset(content, '_demo_label_inset_x', 10)
    rawset(content, '_demo_label_inset_y', 10)
    helpers.set_hint_name(content, 'child')
    set_child_hint(content, helpers)

    rawset(action, '_demo_label', 'Action')
    rawset(action, '_demo_label_rect', 'content')
    rawset(action, '_demo_label_inset_x', 10)
    rawset(action, '_demo_label_inset_y', 10)
    helpers.set_hint_name(action, 'child')
    set_child_hint(action, helpers)

    rawset(stage, '_demo_screen_hooks', {
        update = function()
            local viewport = root:getWorldBounds()
            local bounds = parent:getLocalBounds()
            parent.x = math.floor((viewport.width - bounds.width) * 0.5)
            parent.y = math.floor((viewport.height - bounds.height) * 0.5)
        end,
        draw_overlay = function(graphics)
            local bounds = parent:getWorldBounds()

            LayoutSpacingVisuals.draw_padding_overlay(graphics, parent)
            LayoutSpacingVisuals.draw_padding_overlay(graphics, leading)
            LayoutSpacingVisuals.draw_padding_overlay(graphics, content)
            LayoutSpacingVisuals.draw_margin_overlay(graphics, content)
            LayoutSpacingVisuals.draw_padding_overlay(graphics, action)
            LayoutSpacingVisuals.draw_row_gap_overlay(graphics, parent)

            graphics.setColor(0.95, 0.95, 0.95, 1)
            graphics.setFont(title_font)
            graphics.print('Parent', bounds.x, bounds.y - title_font:getHeight() - 10)
        end,
    })
end

return Setup
