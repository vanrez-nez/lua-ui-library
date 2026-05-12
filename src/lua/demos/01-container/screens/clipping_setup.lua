local DemoColors = require('demos.common.colors')

local Setup = {}

local function find_required(root, id)
    local node = root:findById(id, -1)
    if node == nil then
        error('clipping_setup: missing node "' .. id .. '"', 2)
    end

    return node
end

local function clipping_hint(helpers)
    return function(current)
        local bounds = current:getWorldBounds()
        return {
            {
                label = 'position',
                badges = {
                    helpers.badge('x', tostring(current.x)),
                    helpers.badge('y', tostring(current.y)),
                },
            },
            {
                label = 'dimensions',
                badges = {
                    helpers.badge('width', tostring(current.width)),
                    helpers.badge('height', tostring(current.height)),
                },
            },
            {
                label = 'clipping',
                badges = {
                    helpers.badge('clipChildren', tostring(current.clipChildren)),
                },
            },
            {
                label = 'bounds.world',
                badges = {
                    helpers.badge('x', helpers.round(bounds.x)),
                    helpers.badge('y', helpers.round(bounds.y)),
                    helpers.badge('w', helpers.round(bounds.width)),
                    helpers.badge('h', helpers.round(bounds.height)),
                },
            },
        }
    end
end

local function parent_hint(helpers)
    return function(current)
        return {
            {
                label = 'dimensions',
                badges = {
                    helpers.badge('width', tostring(current.width)),
                    helpers.badge('height', tostring(current.height)),
                },
            },
            {
                label = 'clipping',
                badges = {
                    helpers.badge('clipChildren', tostring(current.clipChildren)),
                },
            },
        }
    end
end

local function apply_box(helpers, node, label, fill_color, line_color, hint_factory)
    helpers.mark_box(node, label, fill_color, line_color)
    helpers.set_hint(node, hint_factory(helpers))
end

function Setup.install(args)
    local helpers = args.helpers
    local root = args.root
    local stage = args.stage

    local overflow_parent = find_required(root, 'clipping-overflow-parent')
    local overflow_child = find_required(root, 'clipping-overflow-child')
    local overflow_grandchild = find_required(root, 'clipping-overflow-grandchild')
    local clipped_parent = find_required(root, 'clipping-clipped-parent')
    local clipped_child = find_required(root, 'clipping-clipped-child')
    local clipped_grandchild = find_required(root, 'clipping-clipped-grandchild')
    local clickable_nodes = {
        overflow_parent,
        overflow_child,
        overflow_grandchild,
        clipped_parent,
        clipped_child,
        clipped_grandchild,
    }
    local parent_gap = 80
    local parent_width = 220
    local parent_height = 160

    apply_box(
        helpers,
        overflow_parent,
        'overflow parent',
        DemoColors.rgba(DemoColors.roles.accent_blue_fill, 0.24),
        DemoColors.roles.accent_blue_line,
        parent_hint
    )
    apply_box(
        helpers,
        overflow_child,
        'overflow child',
        DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.22),
        DemoColors.roles.accent_green_line,
        clipping_hint
    )
    apply_box(
        helpers,
        overflow_grandchild,
        'overflow grandchild',
        DemoColors.rgba(DemoColors.roles.accent_amber_fill, 0.24),
        DemoColors.roles.accent_amber_line,
        clipping_hint
    )
    apply_box(
        helpers,
        clipped_parent,
        'clipped parent',
        DemoColors.rgba(DemoColors.roles.accent_red_fill, 0.22),
        DemoColors.roles.accent_red_line,
        parent_hint
    )
    apply_box(
        helpers,
        clipped_child,
        'clipped child',
        DemoColors.rgba(DemoColors.roles.accent_cyan_fill, 0.22),
        DemoColors.roles.accent_cyan_line,
        clipping_hint
    )
    apply_box(
        helpers,
        clipped_grandchild,
        'clipped grandchild',
        DemoColors.rgba(DemoColors.roles.accent_amber_fill, 0.24),
        DemoColors.roles.accent_amber_line,
        clipping_hint
    )

    rawset(stage, '_demo_screen_hooks', {
        update = function()
            local total_width = (parent_width * 2) + parent_gap
            local origin_x = helpers.round((love.graphics.getWidth() - total_width) * 0.5)
            local origin_y = helpers.round((love.graphics.getHeight() - parent_height) * 0.5)

            overflow_parent.x = origin_x
            overflow_parent.y = origin_y
            clipped_parent.x = origin_x + parent_width + parent_gap
            clipped_parent.y = origin_y
        end,
        mousepressed = function(x, y, button)
            if button ~= 1 then
                return false
            end

            for index = #clickable_nodes, 1, -1 do
                local node = clickable_nodes[index]
                if helpers.is_visible(node) and node:containsPoint(x, y) then
                    node.clipChildren = not node.clipChildren
                    return true
                end
            end

            return false
        end,
    })
end

return Setup
