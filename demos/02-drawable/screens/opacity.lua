local DemoColors = require('demos.common.colors')

local CASES = {
    { label = 'opacity 1.0', value = 1, x = 170 },
    { label = 'opacity 0.5', value = 0.5, x = 480 },
    { label = 'opacity 0.0', value = 0, x = 790 },
}

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        'Exercises Drawable.opacity as a stable prop without implying a later render-isolation implementation that is not active here.',
        function(scope, stage)
            local root = stage.baseSceneLayer

            for index = 1, #CASES do
                local case = CASES[index]
                local node = helpers.make_node(scope, root, {
                    x = case.x,
                    y = 220,
                    width = 220,
                    height = 160,
                    padding = 14,
                    opacity = case.value,
                }, case.label, DemoColors.rgba(DemoColors.roles.accent_cyan_fill, 0.2), DemoColors.roles.accent_cyan_line)
                helpers.show_content(node, 88, 44)
                helpers.set_hint(node, function(current)
                    return {
                        {
                            label = 'props',
                            badges = {
                                helpers.badge('opacity', helpers.format_scalar(current.opacity)),
                            },
                        },
                        {
                            label = 'rect',
                            badges = {
                                helpers.badge('content', helpers.format_rect(current:getContentRect())),
                            },
                        },
                    }
                end)
            end

            return {
                title = 'Opacity',
                description = 'The screen keeps all nodes inspectable while showing that Drawable.opacity is already part of the stable public surface.',
            }
        end
    )
end
