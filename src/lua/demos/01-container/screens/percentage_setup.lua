local DemoColors = require('demos.common.colors')

local Setup = {}

local function find_required(root, id)
    local node = root:findById(id, -1)
    if node == nil then
        error('percentage_setup: missing node "' .. id .. '"', 2)
    end

    return node
end

local function size_hint(helpers, include_minimum)
    return function(current)
        local bounds = current:getLocalBounds()
        local rows = {
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

        if include_minimum then
            rows[#rows + 1] = {
                label = 'clamp.minimum',
                badges = {
                    helpers.badge('minW', tostring(current.minWidth)),
                    helpers.badge('minH', tostring(current.minHeight)),
                },
            }
        end

        return rows
    end
end

local function apply_box(helpers, node, label, fill_color, line_color, include_minimum)
    helpers.mark_box(node, label, fill_color, line_color)
    helpers.set_hint(node, size_hint(helpers, include_minimum))
end

function Setup.install(args)
    local helpers = args.helpers
    local root = args.root
    local stage = args.stage

    local parent = find_required(root, 'percentage-parent')
    local child = find_required(root, 'percentage-child')
    local nested = find_required(root, 'percentage-nested')
    local elapsed = 0
    local pulse_parent_size = helpers.make_size_pulse(
        parent,
        function()
            return love.graphics.getWidth() * 0.55
        end,
        function()
            return love.graphics.getHeight() * 0.60
        end,
        60,
        40,
        0.9
    )

    apply_box(
        helpers,
        parent,
        'parent',
        DemoColors.rgba(DemoColors.roles.accent_cyan_fill, 0.22),
        DemoColors.roles.accent_cyan_line,
        true
    )
    apply_box(
        helpers,
        child,
        'child',
        DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.22),
        DemoColors.roles.accent_green_line,
        false
    )
    apply_box(
        helpers,
        nested,
        'nested',
        DemoColors.rgba(DemoColors.roles.accent_amber_fill, 0.24),
        DemoColors.roles.accent_amber_line,
        false
    )

    rawset(stage, '_demo_screen_hooks', {
        update = function(dt)
            elapsed = elapsed + dt
            pulse_parent_size(dt)

            local orbit_x = math.sin(elapsed * 0.9) * 70
            local orbit_y = math.cos(elapsed * 0.9) * 50

            parent.x = helpers.round(((love.graphics.getWidth() - parent.width) * 0.5) + orbit_x)
            parent.y = helpers.round(((love.graphics.getHeight() - parent.height) * 0.5) + orbit_y)
        end,
    })
end

return Setup
