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
            }, 'parent', DemoColors.rgba(DemoColors.roles.accent_blue_fill, 0.24), DemoColors.roles.accent_blue_line)
            helpers.set_hint_fields(parent, {
                rows = {
                    { label = 'position', source = 'opts', keys = { 'x', 'y' } },
                    { label = 'dimensions', source = 'opts', keys = { 'width', 'height' } },
                    { label = 'bounds.local', source = 'local_bounds', keys = { 'x', 'y', 'w', 'h' } },
                    { label = 'bounds.world', source = 'world_bounds', keys = { 'x', 'y', 'w', 'h' } },
                },
            })

            local child_a = helpers.make_node(scope, parent, {
                x = 30,
                y = 30,
                width = 160,
                height = 90,
            }, 'child A', DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.22), DemoColors.roles.accent_green_line)
            helpers.set_hint_fields(child_a, {
                rows = {
                    { label = 'position', source = 'opts', keys = { 'x', 'y' } },
                    { label = 'dimensions', source = 'opts', keys = { 'width', 'height' } },
                    { label = 'bounds.local', source = 'local_bounds', keys = { 'x', 'y', 'w', 'h' } },
                    { label = 'bounds.world', source = 'world_bounds', keys = { 'x', 'y', 'w', 'h' } },
                },
            })

            local child_b = helpers.make_node(scope, parent, {
                x = 250,
                y = 40,
                width = 180,
                height = 120,
            }, 'child B', DemoColors.rgba(DemoColors.roles.accent_cyan_fill, 0.22), DemoColors.roles.accent_cyan_line)
            helpers.set_hint_fields(child_b, {
                rows = {
                    { label = 'position', source = 'opts', keys = { 'x', 'y' } },
                    { label = 'dimensions', source = 'opts', keys = { 'width', 'height' } },
                    { label = 'bounds.local', source = 'local_bounds', keys = { 'x', 'y', 'w', 'h' } },
                    { label = 'bounds.world', source = 'world_bounds', keys = { 'x', 'y', 'w', 'h' } },
                },
            })

            local grandchild = helpers.make_node(scope, child_b, {
                x = 30,
                y = 30,
                width = 100,
                height = 50,
            }, 'grandchild', DemoColors.rgba(DemoColors.roles.accent_amber_fill, 0.24), DemoColors.roles.accent_amber_line)
            helpers.set_hint_fields(grandchild, {
                rows = {
                    { label = 'position', source = 'opts', keys = { 'x', 'y' } },
                    { label = 'dimensions', source = 'opts', keys = { 'width', 'height' } },
                    { label = 'bounds.local', source = 'local_bounds', keys = { 'x', 'y', 'w', 'h' } },
                    { label = 'bounds.world', source = 'world_bounds', keys = { 'x', 'y', 'w', 'h' } },
                },
            })

            local offset_child = helpers.make_node(scope, child_b, {
                x = -20,
                y = 70,
                width = 80,
                height = 30,
            }, 'offset child', DemoColors.rgba(DemoColors.roles.accent_red_fill, 0.22), DemoColors.roles.accent_red_line)
            helpers.set_hint_fields(offset_child, {
                rows = {
                    { label = 'position', source = 'opts', keys = { 'x', 'y' } },
                    { label = 'dimensions', source = 'opts', keys = { 'width', 'height' } },
                    { label = 'bounds.local', source = 'local_bounds', keys = { 'x', 'y', 'w', 'h' } },
                    { label = 'bounds.world', source = 'world_bounds', keys = { 'x', 'y', 'w', 'h' } },
                },
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
