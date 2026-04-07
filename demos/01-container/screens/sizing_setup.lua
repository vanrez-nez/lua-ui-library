local DemoColors = require('demos.common.colors')

local Setup = {}

local function find_required(root, id)
    local node = root:findById(id, -1)
    if node == nil then
        error('sizing_setup: missing node "' .. id .. '"', 2)
    end

    return node
end

local function apply_box(helpers, node, label, fill_color, line_color)
    helpers.mark_box(node, label, fill_color, line_color)
    helpers.set_hint(node, function(current)
        local bounds = current:getLocalBounds()

        return {
            {
                label = 'size.props',
                badges = {
                    helpers.badge('width', tostring(current.width)),
                    helpers.badge('height', tostring(current.height)),
                },
            },
            {
                label = 'size.resolved',
                badges = {
                    helpers.badge('w', helpers.round(bounds.width)),
                    helpers.badge('h', helpers.round(bounds.height)),
                },
            },
        }
    end)
end

function Setup.install(args)
    local helpers = args.helpers
    local root = args.root
    local stage = args.stage

    local viewport = find_required(root, 'sizing-viewport')
    local parent = find_required(root, 'sizing-parent')
    local child = find_required(root, 'sizing-child')
    local grandchild = find_required(root, 'sizing-grandchild')
    local great_grandchild = find_required(root, 'sizing-great-grandchild')
    local pulse_parent_size = helpers.make_size_pulse(parent, 400, 250, 70, 40, 1.0)

    apply_box(
        helpers,
        viewport,
        'viewport',
        DemoColors.rgba(DemoColors.roles.accent_blue_fill, 0.24),
        DemoColors.roles.accent_blue_line
    )
    apply_box(
        helpers,
        parent,
        'Root',
        DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.22),
        DemoColors.roles.accent_green_line
    )
    apply_box(
        helpers,
        child,
        'Root->A',
        DemoColors.rgba(DemoColors.roles.accent_amber_fill, 0.24),
        DemoColors.roles.accent_amber_line
    )
    apply_box(
        helpers,
        grandchild,
        'A->B',
        DemoColors.rgba(DemoColors.roles.accent_red_fill, 0.22),
        DemoColors.roles.accent_red_line
    )
    apply_box(
        helpers,
        great_grandchild,
        'B->C',
        DemoColors.rgba(DemoColors.roles.accent_cyan_fill, 0.22),
        DemoColors.roles.accent_cyan_line
    )

    rawset(stage, '_demo_screen_hooks', {
        update = function(dt)
            pulse_parent_size(dt)

            parent.x = helpers.round((love.graphics.getWidth() - parent.width) * 0.5)
            parent.y = helpers.round((love.graphics.getHeight() - parent.height) * 0.5)

            local grandchild_bounds = grandchild:getLocalBounds()
            local great_grandchild_bounds = great_grandchild:getLocalBounds()
            great_grandchild.x = helpers.round((grandchild_bounds.width - great_grandchild_bounds.width) * 0.5)
            great_grandchild.y = helpers.round((grandchild_bounds.height - great_grandchild_bounds.height) * 0.5)
        end,
    })
end

return Setup
