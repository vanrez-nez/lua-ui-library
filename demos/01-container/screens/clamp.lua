local DemoColors = require('demos.common.colors')

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        'Clamp behavior driven by resizing parents.',
        function(scope, stage)
            local root = stage.baseSceneLayer
            local parent_gap = 56

            local width_parent = helpers.make_node(scope, root, {
                x = 0,
                y = 0,
                width = 180,
                height = 140,
            }, 'width parent', DemoColors.roles.accent_violet_fill, DemoColors.roles.accent_violet_line)
            helpers.set_hint_fields(width_parent, { props = { 'width' }, ['local'] = { 'w' } })

            local width_case = helpers.make_node(scope, width_parent, {
                x = 20,
                y = 26,
                width = '78%',
                height = 88,
                minWidth = 120,
                maxWidth = 180,
            }, 'width clamp', DemoColors.roles.accent_blue_fill, DemoColors.roles.accent_blue_line)
            helpers.set_hint_fields(width_case, {
                props = { 'width' },
                ['local'] = { 'w' },
                clamp = { 'minW', 'maxW' },
            })

            local height_parent = helpers.make_node(scope, root, {
                x = 0,
                y = 0,
                width = 180,
                height = 140,
            }, 'height parent', DemoColors.roles.accent_violet_fill, DemoColors.roles.accent_violet_line)
            helpers.set_hint_fields(height_parent, { props = { 'height' }, ['local'] = { 'h' } })

            local height_case = helpers.make_node(scope, height_parent, {
                x = 30,
                y = 13,
                width = 120,
                height = '82%',
                minHeight = 72,
                maxHeight = 120,
            }, 'height clamp', DemoColors.roles.accent_green_fill, DemoColors.roles.accent_green_line)
            helpers.set_hint_fields(height_case, {
                props = { 'height' },
                ['local'] = { 'h' },
                clamp = { 'minH', 'maxH' },
            })

            local both_parent = helpers.make_node(scope, root, {
                x = 0,
                y = 0,
                width = 180,
                height = 140,
            }, 'both parent', DemoColors.roles.accent_violet_fill, DemoColors.roles.accent_violet_line)
            helpers.set_hint_fields(both_parent, { props = { 'width', 'height' }, ['local'] = { 'w', 'h' } })

            local both_case = helpers.make_node(scope, both_parent, {
                x = 7,
                y = 20,
                width = '92%',
                height = '72%',
                minWidth = 220,
                maxWidth = 260,
                minHeight = 84,
                maxHeight = 100,
            }, 'both clamp', DemoColors.roles.accent_amber_fill, DemoColors.roles.accent_amber_line)
            helpers.set_hint_fields(both_case, {
                props = { 'width', 'height' },
                ['local'] = { 'w', 'h' },
                clamp = { 'minW', 'maxW', 'minH', 'maxH' },
            })

            return {
                title = 'Min / Max Clamps',
                description = 'Each parent resizes while its child uses percentage sizing plus clamps, so the child visibly hits min and max limits in response to parent changes.',
                update = function(_)
                    local time = love.timer.getTime()

                    width_parent.width = helpers.round(190 + (math.sin(time * 1.35) * 70))
                    height_parent.height = helpers.round(120 + (math.cos(time * 1.1) * 44))
                    both_parent.width = helpers.round(250 + (math.sin(time * 1.2) * 72))
                    both_parent.height = helpers.round(128 + (math.cos(time * 1.45) * 34))

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
