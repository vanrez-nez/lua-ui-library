local DemoColors = require('demos.common.colors')

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        'Visibility behavior without mixing in later control systems.',
        function(scope, stage)
            local root = stage.baseSceneLayer
            local elapsed = 0
            local parent_width = 260
            local parent_height = 200
            local origin = {
                x = math.floor((love.graphics.getWidth() - parent_width) * 0.5 + 0.5),
                y = math.floor((love.graphics.getHeight() - parent_height) * 0.5 + 0.5),
            }

            local parent = helpers.make_node(scope, root, {
                x = origin.x,
                y = origin.y,
                width = parent_width,
                height = parent_height,
            }, 'parent', DemoColors.rgba(DemoColors.roles.accent_blue_fill, 0.24), DemoColors.roles.accent_blue_line)
            helpers.set_hint_fields(parent, {
                rows = {
                    { label = 'visibility', source = 'visible', keys = { 'value' } },
                },
            })

            local child = helpers.make_node(scope, parent, {
                x = 30,
                y = 20,
                width = 180,
                height = 132,
            }, 'child', DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.22), DemoColors.roles.accent_green_line)
            helpers.set_hint_fields(child, {
                rows = {
                    { label = 'visibility', source = 'visible', keys = { 'value' } },
                },
            })

            local grandchild = helpers.make_node(scope, child, {
                x = 20,
                y = 20,
                width = 116,
                height = 86,
            }, 'grandchild', DemoColors.rgba(DemoColors.roles.accent_amber_fill, 0.24), DemoColors.roles.accent_amber_line)
            helpers.set_hint_fields(grandchild, {
                rows = {
                    { label = 'visibility', source = 'visible', keys = { 'value' } },
                },
            })

            local great_grandchild = helpers.make_node(scope, grandchild, {
                x = 20,
                y = 15,
                width = 68,
                height = 44,
            }, 'great grandchild', DemoColors.rgba(DemoColors.roles.accent_red_fill, 0.22), DemoColors.roles.accent_red_line)
            helpers.set_hint_fields(great_grandchild, {
                rows = {
                    { label = 'visibility', source = 'visible', keys = { 'value' } },
                },
            })

            return {
                title = 'Visibility',
                description = 'Three nested descendants blink at different timings so visibility changes stay easy to compare across parent-child levels.',
                sidebar_title = 'Blink State',
                update = function(dt)
                    elapsed = elapsed + dt

                    child.visible = math.sin(elapsed * 1.15) > -0.15
                    grandchild.visible = math.sin(elapsed * 1.85) > 0.1
                    great_grandchild.visible = math.sin(elapsed * 2.65) > 0.35
                end,
                sidebar = function()
                    return {
                        string.format('origin x:%d y:%d', helpers.round(origin.x), helpers.round(origin.y)),
                        'child visible = ' .. tostring(helpers.is_visible(child)),
                        'grandchild visible = ' .. tostring(helpers.is_visible(grandchild)),
                        'great grandchild visible = ' .. tostring(helpers.is_visible(great_grandchild)),
                    }
                end,
            }
        end
    )
end
