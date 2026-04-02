local DemoColors = require('demos.common.colors')

local CASES = {
    { label = 'blend alpha', value = 'alpha', x = 170 },
    { label = 'blend add', value = 'add', x = 480 },
    { label = 'blend multiply', value = 'multiply', x = 790 },
}

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        'Tracks blendMode on Drawable as public surface data while keeping the harness honest about current deferred rendering behavior.',
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
                    blendMode = case.value,
                }, case.label, DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.18), DemoColors.roles.accent_green_line)
                helpers.show_content(node, 88, 44)
                helpers.set_hint(node, {
                    {
                        label = 'props',
                        badges = {
                            helpers.badge('blendMode', case.value),
                        },
                    },
                })
            end

            return {
                title = 'Blend Mode',
                description = 'This screen verifies that blendMode survives on Drawable without claiming full subtree compositing behavior that is still deferred.',
            }
        end
    )
end
