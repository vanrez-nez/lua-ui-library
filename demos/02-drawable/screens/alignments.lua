local DemoColors = require('demos.common.colors')

local CASES = {
    {
        label = 'start / start',
        x = 120,
        y = 170,
        alignX = 'start',
        alignY = 'start',
    },
    {
        label = 'center / center',
        x = 430,
        y = 170,
        alignX = 'center',
        alignY = 'center',
    },
    {
        label = 'end / end',
        x = 740,
        y = 170,
        alignX = 'end',
        alignY = 'end',
    },
    {
        label = 'stretch / stretch',
        x = 1050,
        y = 170,
        alignX = 'stretch',
        alignY = 'stretch',
    },
}

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        'Shows how Drawable resolves aligned content inside its padded content box.',
        function(scope, stage)
            local root = stage.baseSceneLayer
            for index = 1, #CASES do
                local case = CASES[index]
                local node = helpers.make_node(scope, root, {
                    x = case.x,
                    y = case.y,
                    width = 220,
                    height = 180,
                    padding = { 16, 20, 28, 24 },
                    alignX = case.alignX,
                    alignY = case.alignY,
                }, case.label, DemoColors.rgba(DemoColors.roles.accent_blue_fill, 0.2), DemoColors.roles.accent_blue_line)
                helpers.show_content(node, 72, 40)
                helpers.set_hint(node, function(current)
                    return {
                        {
                            label = 'node',
                            badges = {
                                helpers.badge('name', case.label),
                            },
                        },
                        {
                            label = 'props',
                            badges = {
                                helpers.badge('alignX', current.alignX),
                                helpers.badge('alignY', current.alignY),
                                helpers.badge('padding', helpers.format_insets(current.padding)),
                            },
                        },
                        {
                            label = 'rect',
                            badges = {
                                helpers.badge('content', helpers.format_rect(current:getContentRect())),
                            },
                        },
                        {
                            label = 'rect',
                            badges = {
                                helpers.badge('sample', helpers.format_rect(current:resolveContentRect(72, 40))),
                            },
                        },
                    }
                end)
            end

            return {
                title = 'Alignments',
                description = 'Amber shows the content box after padding. Cyan shows a 72x40 content sample resolved through alignX and alignY.',
            }
        end
    )
end
