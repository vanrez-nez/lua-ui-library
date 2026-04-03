local DemoColors = require('demos.common.colors')

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        'Clamp behavior driven by resizing parents.',
        function(scope, stage)
            local root = stage.baseSceneLayer
            local parent_gap = 56
            local elapsed = 0

            local width_parent = helpers.make_node(scope, root, {
                x = 0,
                y = 0,
                width = 180,
                height = 140,
            }, 'width parent', DemoColors.rgba(DemoColors.roles.accent_violet_fill, 0.22), DemoColors.roles.accent_violet_line)
            helpers.set_hint_fields(width_parent, {
                rows = {
                    { label = 'size.requested', source = 'opts', keys = { 'width' } },
                    { label = 'size.resolved', source = 'local_bounds', keys = { 'w' } },
                },
            })

            local width_case = helpers.make_node(scope, width_parent, {
                x = 20,
                y = 25,
                width = '78%',
                height = 90,
                minWidth = 120,
                maxWidth = 180,
            }, 'width clamp', DemoColors.rgba(DemoColors.roles.accent_blue_fill, 0.24), DemoColors.roles.accent_blue_line)
            helpers.set_hint_fields(width_case, {
                rows = {
                    { label = 'size.requested', source = 'opts', keys = { 'width' } },
                    { label = 'size.resolved', source = 'local_bounds', keys = { 'w' } },
                    { label = 'clamp.width', source = 'clamp', keys = { 'minW', 'maxW' } },
                },
            })

            local height_parent = helpers.make_node(scope, root, {
                x = 0,
                y = 0,
                width = 180,
                height = 140,
            }, 'height parent', DemoColors.rgba(DemoColors.roles.accent_violet_fill, 0.22), DemoColors.roles.accent_violet_line)
            helpers.set_hint_fields(height_parent, {
                rows = {
                    { label = 'size.requested', source = 'opts', keys = { 'height' } },
                    { label = 'size.resolved', source = 'local_bounds', keys = { 'h' } },
                },
            })

            local height_case = helpers.make_node(scope, height_parent, {
                x = 30,
                y = 15,
                width = 120,
                height = '82%',
                minHeight = 72,
                maxHeight = 120,
            }, 'height clamp', DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.22), DemoColors.roles.accent_green_line)
            helpers.set_hint_fields(height_case, {
                rows = {
                    { label = 'size.requested', source = 'opts', keys = { 'height' } },
                    { label = 'size.resolved', source = 'local_bounds', keys = { 'h' } },
                    { label = 'clamp.height', source = 'clamp', keys = { 'minH', 'maxH' } },
                },
            })

            local both_parent = helpers.make_node(scope, root, {
                x = 0,
                y = 0,
                width = 180,
                height = 140,
            }, 'both parent', DemoColors.rgba(DemoColors.roles.accent_violet_fill, 0.22), DemoColors.roles.accent_violet_line)
            helpers.set_hint_fields(both_parent, {
                rows = {
                    { label = 'dimensions.requested', source = 'opts', keys = { 'width', 'height' } },
                    { label = 'dimensions.resolved', source = 'local_bounds', keys = { 'w', 'h' } },
                },
            })

            local both_case = helpers.make_node(scope, both_parent, {
                x = 10,
                y = 20,
                width = '92%',
                height = '72%',
                minWidth = 220,
                maxWidth = 260,
                minHeight = 80,
                maxHeight = 100,
            }, 'both clamp', DemoColors.rgba(DemoColors.roles.accent_amber_fill, 0.24), DemoColors.roles.accent_amber_line)
            helpers.set_hint_fields(both_case, {
                rows = {
                    { label = 'dimensions.requested', source = 'opts', keys = { 'width', 'height' } },
                    { label = 'dimensions.resolved', source = 'local_bounds', keys = { 'w', 'h' } },
                    { label = 'clamp.width', source = 'clamp', keys = { 'minW', 'maxW' } },
                    { label = 'clamp.height', source = 'clamp', keys = { 'minH', 'maxH' } },
                },
            })

            return {
                title = 'Min / Max Clamps',
                description = 'Each parent resizes while its child uses percentage sizing plus clamps, so the child visibly hits min and max limits in response to parent changes.',
                update = function(dt)
                    elapsed = elapsed + dt

                    width_parent.width = helpers.round(200 + (math.sin(elapsed * 1.35) * 70))
                    height_parent.height = helpers.round(120 + (math.cos(elapsed * 1.1) * 40))
                    both_parent.width = helpers.round(250 + (math.sin(elapsed * 1.2) * 70))
                    both_parent.height = helpers.round(130 + (math.cos(elapsed * 1.45) * 30))

                    local screen_width = love.graphics.getWidth()
                    local screen_height = love.graphics.getHeight()
                    local total_height = width_parent.height + height_parent.height + both_parent.height + (parent_gap * 2)
                    local top = math.floor((screen_height - total_height) * 0.5 + 0.5)

                    width_parent.x = math.floor((screen_width - width_parent.width) * 0.5 + 0.5)
                    width_parent.y = top

                    height_parent.x = math.floor((screen_width - height_parent.width) * 0.5 + 0.5)
                    height_parent.y = width_parent.y + width_parent.height + parent_gap

                    both_parent.x = math.floor((screen_width - both_parent.width) * 0.5 + 0.5)
                    both_parent.y = height_parent.y + height_parent.height + parent_gap
                end,
            }
        end
    )
end
