local DemoColors = require('demos.common.colors')

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        'Parent / child bounds, local versus world coordinates, and retained tree structure.',
        function(scope, stage)
            local root = stage.baseSceneLayer
            local origin = helpers.random_root_position(520, 260, 120)

            local parent = helpers.make_node(scope, root, {
                x = origin.x,
                y = origin.y,
                width = 520,
                height = 260,
            }, 'parent', DemoColors.roles.accent_blue_fill, DemoColors.roles.accent_blue_line)
            helpers.set_hint_fields(parent, {
                props = { 'x', 'y', 'width', 'height' },
                ['local'] = { 'x', 'y', 'w', 'h' },
                world = { 'x', 'y', 'w', 'h' },
            })

            local child_a = helpers.make_node(scope, parent, {
                x = 32,
                y = 28,
                width = 156,
                height = 94,
            }, 'child A', DemoColors.roles.accent_green_fill, DemoColors.roles.accent_green_line)
            helpers.set_hint_fields(child_a, {
                props = { 'x', 'y', 'width', 'height' },
                ['local'] = { 'x', 'y', 'w', 'h' },
                world = { 'x', 'y', 'w', 'h' },
            })

            local child_b = helpers.make_node(scope, parent, {
                x = 246,
                y = 44,
                width = 182,
                height = 118,
            }, 'child B', DemoColors.roles.accent_cyan_fill, DemoColors.roles.accent_cyan_line)
            helpers.set_hint_fields(child_b, {
                props = { 'x', 'y', 'width', 'height' },
                ['local'] = { 'x', 'y', 'w', 'h' },
                world = { 'x', 'y', 'w', 'h' },
            })

            local grandchild = helpers.make_node(scope, child_b, {
                x = 26,
                y = 30,
                width = 96,
                height = 52,
            }, 'grandchild', DemoColors.roles.accent_amber_fill, DemoColors.roles.accent_amber_line)
            helpers.set_hint_fields(grandchild, {
                props = { 'x', 'y', 'width', 'height' },
                ['local'] = { 'x', 'y', 'w', 'h' },
                world = { 'x', 'y', 'w', 'h' },
            })

            local offset_child = helpers.make_node(scope, child_b, {
                x = -18,
                y = 72,
                width = 76,
                height = 34,
            }, 'offset child', DemoColors.roles.accent_red_fill, DemoColors.roles.accent_red_line)
            helpers.set_hint_fields(offset_child, {
                props = { 'x', 'y', 'width', 'height' },
                ['local'] = { 'x', 'y', 'w', 'h' },
                world = { 'x', 'y', 'w', 'h' },
            })

            return {
                title = 'Parent / Child Bounds',
                description = 'Verifies world coordinates across direct children and nested descendants while local bounds remain container-relative.',
                inspect = function()
                    local child_b_world = child_b:getWorldBounds()
                    local grandchild_world = grandchild:getWorldBounds()
                    local offset_world = offset_child:getWorldBounds()

                    return {
                        string.format('root offset  x:%d y:%d', helpers.round(origin.x), helpers.round(origin.y)),
                        'parent local  ' .. helpers.format_rect(parent:getLocalBounds()),
                        'parent world  ' .. helpers.format_rect(parent:getWorldBounds()),
                        'child A local ' .. helpers.format_rect(child_a:getLocalBounds()),
                        'child A world ' .. helpers.format_rect(child_a:getWorldBounds()),
                        'child B local ' .. helpers.format_rect(child_b:getLocalBounds()),
                        'child B world ' .. helpers.format_rect(child_b_world),
                        'grandchild local ' .. helpers.format_rect(grandchild:getLocalBounds()),
                        'grandchild world ' .. helpers.format_rect(grandchild_world),
                        'offset child local ' .. helpers.format_rect(offset_child:getLocalBounds()),
                        'offset child world ' .. helpers.format_rect(offset_world),
                    }
                end,
            }
        end
    )
end
