local DemoColors = require('demos.common.colors')

local CASES = {
    {
        label = 'circle mask',
        x = 170,
        mask = { id = 'mask.circle', kind = 'circle' },
    },
    {
        label = 'diamond mask',
        x = 480,
        mask = { id = 'mask.diamond', kind = 'diamond' },
    },
    {
        label = 'stripe mask',
        x = 790,
        mask = { id = 'mask.stripe', kind = 'stripe' },
    },
}

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        'Keeps mask on the stable Drawable prop surface while distinguishing it from later composited subtree masking behavior.',
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
                    mask = case.mask,
                }, case.label, DemoColors.rgba(DemoColors.roles.accent_violet_fill, 0.18), DemoColors.roles.accent_violet_line)
                helpers.show_content(node, 88, 44)
                helpers.set_hint(node, {
                    {
                        label = 'props',
                        badges = {
                            helpers.badge('mask.id', case.mask.id),
                            helpers.badge('mask.kind', case.mask.kind),
                        },
                    },
                })
            end

            return {
                title = 'Mask',
                description = 'Mask is part of the public Drawable contract. The screen keeps it visible as stored data instead of faking a compositing pipeline that is not active here.',
            }
        end
    )
end
