local DemoColors = require('demos.common.colors')

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        function(scope, stage)
            local root = stage.baseSceneLayer
            local elapsed = 0

            local parent = helpers.make_node(scope, root, {
                x = 0,
                y = 0,
                width = '55%',
                height = '58%',
                minWidth = 360,
                minHeight = 240,
            }, 'parent', DemoColors.rgba(DemoColors.roles.accent_cyan_fill, 0.22), DemoColors.roles.accent_cyan_line)
            helpers.set_hint_fields(parent, {
                rows = {
                    { label = 'size.requested', source = 'opts', keys = { 'width', 'height' } },
                    { label = 'size.resolved', source = 'local_bounds', keys = { 'w', 'h' } },
                    { label = 'clamp.minimum', source = 'clamp', keys = { 'minW', 'minH' } },
                },
            })

            local child = helpers.make_node(scope, parent, {
                x = 20,
                y = 20,
                width = '50%',
                height = '50%',
            }, 'child', DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.22), DemoColors.roles.accent_green_line)
            helpers.set_hint_fields(child, {
                rows = {
                    { label = 'size.requested', source = 'opts', keys = { 'width', 'height' } },
                    { label = 'size.resolved', source = 'local_bounds', keys = { 'w', 'h' } },
                },
            })

            local nested = helpers.make_node(scope, child, {
                x = 10,
                y = 10,
                width = '50%',
                height = '50%',
            }, 'nested', DemoColors.rgba(DemoColors.roles.accent_amber_fill, 0.24), DemoColors.roles.accent_amber_line)
            helpers.set_hint_fields(nested, {
                rows = {
                    { label = 'size.requested', source = 'opts', keys = { 'width', 'height' } },
                    { label = 'size.resolved', source = 'local_bounds', keys = { 'w', 'h' } },
                },
            })

            local pulse_parent_size = helpers.make_size_pulse(
                parent,
                function()
                    return love.graphics.getWidth() * 0.55
                end,
                function()
                    return love.graphics.getHeight() * 0.58
                end,
                60,
                40,
                0.9
            )

            return {
                title = 'Nested Percentage Sizing',
                description = 'Shows percentage sizing recalculating from the effective parent region while the root node moves in a circular path.',
                update = function(dt)
                    elapsed = elapsed + dt
                    pulse_parent_size(dt)

                    local orbit_x = math.sin(elapsed * 0.9) * 72
                    local orbit_y = math.cos(elapsed * 0.9) * 54

                    parent.x = helpers.round(((love.graphics.getWidth() - parent.width) * 0.5) + orbit_x)
                    parent.y = helpers.round(((love.graphics.getHeight() - parent.height) * 0.5) + orbit_y)
                end,
            }
        end
    )
end
