local DemoColors = require('demos.common.colors')

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        'Fixed sizing, stage-direct fill sizing, and percentage sizing.',
        function(scope, stage)
            local root = stage.baseSceneLayer

            local viewport = helpers.make_node(scope, root, {
                x = 0,
                y = 0,
                width = 'fill',
                height = 'fill',
            }, 'viewport', DemoColors.rgba(DemoColors.roles.accent_blue_fill, 0.24), DemoColors.roles.accent_blue_line)
            helpers.set_hint_fields(viewport, {
                rows = {
                    { label = 'size.requested', source = 'opts', keys = { 'width', 'height' } },
                    { label = 'size.resolved', source = 'local_bounds', keys = { 'w', 'h' } },
                },
            })

            local parent = helpers.make_node(scope, viewport, {
                x = 0,
                y = 0,
                width = 420,
                height = 260,
            }, 'Root', DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.22), DemoColors.roles.accent_green_line)
            helpers.set_hint_fields(parent, {
                rows = {
                    { label = 'size.requested', source = 'opts', keys = { 'width', 'height' } },
                    { label = 'size.resolved', source = 'local_bounds', keys = { 'w', 'h' } },
                },
            })

            local child = helpers.make_node(scope, parent, {
                x = 20,
                y = 20,
                width = '62%',
                height = '58%',
            }, 'Root->A', DemoColors.rgba(DemoColors.roles.accent_amber_fill, 0.24), DemoColors.roles.accent_amber_line)
            helpers.set_hint_fields(child, {
                rows = {
                    { label = 'size.requested', source = 'opts', keys = { 'width', 'height' } },
                    { label = 'size.resolved', source = 'local_bounds', keys = { 'w', 'h' } },
                },
            })

            local grandchild = helpers.make_node(scope, child, {
                x = 20,
                y = 20,
                width = '54%',
                height = '60%',
            }, 'A->B', DemoColors.rgba(DemoColors.roles.accent_red_fill, 0.22), DemoColors.roles.accent_red_line)
            helpers.set_hint_fields(grandchild, {
                rows = {
                    { label = 'size.requested', source = 'opts', keys = { 'width', 'height' } },
                    { label = 'size.resolved', source = 'local_bounds', keys = { 'w', 'h' } },
                },
            })

            local great_grandchild = helpers.make_node(scope, grandchild, {
                x = 0,
                y = 0,
                width = 60,
                height = '50%',
            }, 'B->C', DemoColors.rgba(DemoColors.roles.accent_cyan_fill, 0.22), DemoColors.roles.accent_cyan_line)
            helpers.set_hint_fields(great_grandchild, {
                rows = {
                    { label = 'size.requested', source = 'opts', keys = { 'width', 'height' } },
                    { label = 'size.resolved', source = 'local_bounds', keys = { 'w', 'h' } },
                },
            })

            local pulse_parent_size = helpers.make_size_pulse(parent, 420, 260, 70, 40, 1.0)

            return {
                title = 'Fixed / Fill / Percent Sizing',
                description = 'Root is a fixed container that pulses, Root->A resolves percentage sizing from Root, A->B resolves nested percentage sizing, and B->C mixes fixed width with percentage height.',
                update = function(dt)
                    pulse_parent_size(dt)
                    parent.x = helpers.round((love.graphics.getWidth() - parent.width) * 0.5)
                    parent.y = helpers.round((love.graphics.getHeight() - parent.height) * 0.5)
                    local grandchild_bounds = grandchild:getLocalBounds()
                    local great_grandchild_bounds = great_grandchild:getLocalBounds()
                    great_grandchild.x = helpers.round((grandchild_bounds.width - great_grandchild_bounds.width) * 0.5)
                    great_grandchild.y = helpers.round((grandchild_bounds.height - great_grandchild_bounds.height) * 0.5)
                end,
            }
        end
    )
end
