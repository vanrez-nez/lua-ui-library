local LayoutDemoDebug = require('demos.common.layout_demo_debug')
local LayoutSpacingVisuals = require('demos.common.layout_spacing_visuals')

local Setup = {}

local function find_required(root, id)
    local node = root:findById(id, -1)
    if node == nil then
        error('layout_stack_setup: missing node "' .. id .. '"', 2)
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
                    helpers.badge(nil, 'Stack'),
                },
            },
        }

        append_rect_row(entries, helpers, 'parent.container', current:getLocalBounds())
        append_rect_row(entries, helpers, 'parent.content', current:_get_effective_content_rect())
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
    local stage = args.stage
    local title_font = love.graphics.newFont(12)
    local parent = find_required(root, 'layout-stack-parent')
    local backdrop = find_required(root, 'layout-stack-backdrop')
    local surface = find_required(root, 'layout-stack-surface')
    local badge = find_required(root, 'layout-stack-badge')

    rawset(parent, '_demo_label', '')
    helpers.set_hint_name(parent, 'parent')
    set_parent_hint(parent, helpers)
    helpers.show_bounds(parent)

    local parent_bounds_overlay = rawget(parent, '_demo_bounds_overlay')
    parent_bounds_overlay.borderStyle = 'rough'
    parent_bounds_overlay.borderPattern = 'dashed'
    parent_bounds_overlay.borderDashLength = 8
    parent_bounds_overlay.borderGapLength = 6

    rawset(backdrop, '_demo_label', 'Backdrop')
    rawset(backdrop, '_demo_label_rect', 'content')
    rawset(backdrop, '_demo_label_inset_x', 0)
    rawset(backdrop, '_demo_label_inset_y', 0)
    helpers.set_hint_name(backdrop, 'backdrop')
    set_child_hint(backdrop, helpers)

    rawset(surface, '_demo_label', 'Surface')
    rawset(surface, '_demo_label_rect', 'content')
    rawset(surface, '_demo_label_inset_x', 0)
    rawset(surface, '_demo_label_inset_y', 0)
    helpers.set_hint_name(surface, 'surface')
    set_child_hint(surface, helpers)

    rawset(badge, '_demo_label', 'Badge')
    rawset(badge, '_demo_label_rect', 'content')
    rawset(badge, '_demo_label_inset_x', 0)
    rawset(badge, '_demo_label_inset_y', 0)
    helpers.set_hint_name(badge, 'badge')
    set_child_hint(badge, helpers)

    LayoutDemoDebug.dump('layout_stack', {
        LayoutDemoDebug.group('parent', {
            LayoutDemoDebug.entry('padding', '15'),
            LayoutDemoDebug.entry('width', tostring(parent.width)),
            LayoutDemoDebug.entry('height', tostring(parent.height)),
        }),
        LayoutDemoDebug.group('backdrop', {
            LayoutDemoDebug.entry('width', tostring(backdrop.width)),
            LayoutDemoDebug.entry('height', tostring(backdrop.height)),
        }),
        LayoutDemoDebug.group('surface', {
            LayoutDemoDebug.entry('margin', '30'),
            LayoutDemoDebug.entry('padding', '15'),
            LayoutDemoDebug.entry('width', tostring(surface.width)),
            LayoutDemoDebug.entry('height', tostring(surface.height)),
        }),
        LayoutDemoDebug.group('badge', {
            LayoutDemoDebug.entry('x', tostring(badge.x)),
            LayoutDemoDebug.entry('y', tostring(badge.y)),
            LayoutDemoDebug.entry('width', tostring(badge.width)),
            LayoutDemoDebug.entry('height', tostring(badge.height)),
        }),
    })

    rawset(stage, '_demo_screen_hooks', {
        update = function()
            local viewport = root:getWorldBounds()
            local bounds = parent:getLocalBounds()
            parent.x = math.floor((viewport.width - bounds.width) * 0.5)
            parent.y = math.floor((viewport.height - bounds.height) * 0.5)
        end,
        draw_overlay = function(graphics)
            local bounds = parent:getWorldBounds()
            local hovered_node = helpers._draw_context and helpers._draw_context.hovered_node or nil

            LayoutSpacingVisuals.draw_hovered_overlays(graphics, hovered_node, {
                parent = parent,
                children = { backdrop, surface, badge },
            })

            graphics.setColor(0.95, 0.95, 0.95, 1)
            graphics.setFont(title_font)
            graphics.print('Parent', bounds.x, bounds.y - title_font:getHeight() - 10)
        end,
    })
end

return Setup
