local DemoColors = require('demos.common.colors')

local Setup = {}

local function find_required(root, id)
    local node = root:findById(id, -1)
    if node == nil then
        error('visibility_setup: missing node "' .. id .. '"', 2)
    end

    return node
end

local function visibility_hint(helpers)
    return function(current)
        return {
            {
                label = 'visible',
                badges = {
                    helpers.badge('value', tostring(helpers.is_visible(current))),
                },
            },
        }
    end
end

local function apply_box(helpers, node, label, fill_color, line_color)
    helpers.mark_box(node, label, fill_color, line_color)
    helpers.set_hint(node, visibility_hint(helpers))
end

function Setup.install(args)
    local helpers = args.helpers
    local root = args.root
    local stage = args.stage
    local state = args.state
    local elapsed = 0

    local parent = find_required(root, 'visibility-parent')
    local child = find_required(root, 'visibility-child')
    local grandchild = find_required(root, 'visibility-grandchild')
    local great_grandchild = find_required(root, 'visibility-great-grandchild')

    apply_box(
        helpers,
        parent,
        'parent',
        DemoColors.rgba(DemoColors.roles.accent_blue_fill, 0.24),
        DemoColors.roles.accent_blue_line
    )
    apply_box(
        helpers,
        child,
        'child',
        DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.22),
        DemoColors.roles.accent_green_line
    )
    apply_box(
        helpers,
        grandchild,
        'grandchild',
        DemoColors.rgba(DemoColors.roles.accent_amber_fill, 0.24),
        DemoColors.roles.accent_amber_line
    )
    apply_box(
        helpers,
        great_grandchild,
        'great grandchild',
        DemoColors.rgba(DemoColors.roles.accent_red_fill, 0.22),
        DemoColors.roles.accent_red_line
    )

    state.sidebar_title = 'Blink State'
    state.sidebar = function()
        local parent_bounds = parent:getWorldBounds()
        return {
            string.format('origin x:%d y:%d', helpers.round(parent_bounds.x), helpers.round(parent_bounds.y)),
            'child visible = ' .. tostring(helpers.is_visible(child)),
            'grandchild visible = ' .. tostring(helpers.is_visible(grandchild)),
            'great grandchild visible = ' .. tostring(helpers.is_visible(great_grandchild)),
        }
    end

    rawset(stage, '_demo_screen_hooks', {
        update = function(dt)
            elapsed = elapsed + dt

            child.visible = math.sin(elapsed * 1.15) > -0.15
            grandchild.visible = math.sin(elapsed * 1.85) > 0.1
            great_grandchild.visible = math.sin(elapsed * 2.65) > 0.35

            parent.x = helpers.round((love.graphics.getWidth() - parent.width) * 0.5)
            parent.y = helpers.round((love.graphics.getHeight() - parent.height) * 0.5)
        end,
    })
end

return Setup
