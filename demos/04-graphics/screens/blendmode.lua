local DemoColors = require('demos.common.colors')

local CASES = {
    { label = 'Normal', value = 'normal', x = 170 },
    { label = 'Add', value = 'add', x = 480 },
    { label = 'Multiply', value = 'multiply', x = 790 },
}

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        function(scope, stage)
            local root = stage.baseSceneLayer

            for index = 1, #CASES do
                local case = CASES[index]
                local node = helpers.make_node(scope, root, {
                    x = case.x,
                    y = 220,
                    width = 220,
                    height = 160,
                    padding = 10,
                    blendMode = case.value,
                }, case.label, DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.18), DemoColors.roles.accent_green_line)
                helpers.show_content(node, 88, 44)
                helpers.set_hint(node, {
                    {
                        label = 'blendMode',
                        badges = {
                            helpers.badge('blendMode', case.value),
                        },
                    },
                })
            end

            return {
                title = 'Blend Mode',
                description = 'Inspect the assigned blendMode values here, then compare them with the retained render-effects screen where add and multiply are rendered through the shared compositing path.',
            }
        end
    )
end
