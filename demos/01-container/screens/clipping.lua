local DemoColors = require('demos.common.colors')

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        'Overflow and clipping behavior on plain Container nodes.',
        function(scope, stage)
            local root = stage.baseSceneLayer
            local parent_width = 220
            local parent_height = 160
            local parent_gap = 80
            local total_width = (parent_width * 2) + parent_gap
            local origin = {
                x = math.floor((love.graphics.getWidth() - total_width) * 0.5 + 0.5),
                y = math.floor((love.graphics.getHeight() - parent_height) * 0.5 + 0.5),
            }

            local overflow_parent = helpers.make_node(scope, root, {
                x = origin.x,
                y = origin.y,
                width = parent_width,
                height = parent_height,
                clipChildren = false,
            }, 'overflow parent', DemoColors.roles.accent_blue_fill, DemoColors.roles.accent_blue_line)
            helpers.set_hint_fields(overflow_parent, {
                props = { 'width', 'height', 'clipChildren' },
            })

            local overflow_child = helpers.make_node(scope, overflow_parent, {
                x = 120,
                y = 42,
                width = 160,
                height = 92,
            }, 'overflow child', DemoColors.roles.accent_green_fill, DemoColors.roles.accent_green_line)
            helpers.set_hint_fields(overflow_child, {
                props = { 'x', 'y', 'width', 'height', 'clipChildren' },
                world = { 'x', 'y', 'w', 'h' },
            })

            local overflow_grandchild = helpers.make_node(scope, overflow_child, {
                x = 86,
                y = 18,
                width = 120,
                height = 44,
            }, 'overflow grandchild', DemoColors.roles.accent_amber_fill, DemoColors.roles.accent_amber_line)
            helpers.set_hint_fields(overflow_grandchild, {
                props = { 'x', 'y', 'width', 'height', 'clipChildren' },
                world = { 'x', 'y', 'w', 'h' },
            })

            local clipped_parent = helpers.make_node(scope, root, {
                x = origin.x + parent_width + parent_gap,
                y = origin.y,
                width = parent_width,
                height = parent_height,
                clipChildren = true,
            }, 'clipped parent', DemoColors.roles.accent_red_fill, DemoColors.roles.accent_red_line)
            helpers.set_hint_fields(clipped_parent, {
                props = { 'width', 'height', 'clipChildren' },
            })

            local clipped_child = helpers.make_node(scope, clipped_parent, {
                x = 120,
                y = 42,
                width = 160,
                height = 192,
            }, 'clipped child', DemoColors.roles.accent_cyan_fill, DemoColors.roles.accent_cyan_line)
            helpers.set_hint_fields(clipped_child, {
                props = { 'x', 'y', 'width', 'height', 'clipChildren' },
                world = { 'x', 'y', 'w', 'h' },
            })

            local clipped_grandchild = helpers.make_node(scope, clipped_child, {
                x = 86,
                y = 18,
                width = 140,
                height = 44,
            }, 'clipped grandchild', DemoColors.roles.accent_amber_fill, DemoColors.roles.accent_amber_line)
            helpers.set_hint_fields(clipped_grandchild, {
                props = { 'x', 'y', 'width', 'height', 'clipChildren' },
                world = { 'x', 'y', 'w', 'h' },
            })

            return {
                title = 'Overflow / Clipping',
                description = 'Compares default overflow against clipChildren = true using the same overflowing child subtree in both parents.',
            }
        end
    )
end
